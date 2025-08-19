#!/bin/bash

# WezTerm SSH Configuration Export Script
# Exports servers.json and Keychain passwords to encrypted bundle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
   _____ _____ _   _   ______                       _   
  / ____/ ____| | | | |  ____|                     | |  
 | (___| (___ | |_| | | |__  __  ___ __   ___  _ __| |_ 
  \___ \\___ \|  _  | |  __| \ \/ / '_ \ / _ \| '__| __|
  ____) |___) | | | | | |____ >  <| |_) | (_) | |  | |_ 
 |_____/_____/|_| |_| |______/_/\_\ .__/ \___/|_|   \__|
                                  | |                   
                                  |_|                   
EOF
echo -e "${NC}"
echo "WezTerm SSH Configuration Export Tool"
echo "====================================="
echo

# Check if servers.json exists
SERVERS_FILE="$HOME/.config/wezterm/servers.json"
FOLDERS_FILE="$HOME/.config/wezterm/folders.json"

if [[ ! -f "$SERVERS_FILE" ]]; then
    print_error "servers.json not found at $SERVERS_FILE"
    exit 1
fi

# Check if this is a folder-enabled system
HAS_FOLDERS=false
if [[ -f "$FOLDERS_FILE" ]]; then
    HAS_FOLDERS=true
    print_status "Detected folder-enabled SSH launcher"
else
    print_status "Detected legacy SSH launcher (no folders)"
fi

# Count servers
SERVER_COUNT=$(python3 -c "
import json, sys
try:
    with open('$SERVERS_FILE', 'r') as f:
        data = json.load(f)
    print(len(data))
except:
    print(0)
")

print_status "Found $SERVER_COUNT servers in configuration"

# Extract passwords from Keychain
print_status "Extracting passwords from macOS Keychain..."
TEMP_PASSWORDS_FILE="/tmp/wezterm_passwords_$$.json"

python3 << EOF
import json
import subprocess
import sys

# Read servers
with open('$SERVERS_FILE', 'r') as f:
    servers = json.load(f)

passwords = {}
password_count = 0

for server in servers:
    server_name = server['name']
    service = f"wezterm-ssh-{server_name}"
    account = "password"
    
    try:
        result = subprocess.run([
            'security', 'find-generic-password', 
            '-s', service, '-a', account, '-w'
        ], capture_output=True, text=True, stderr=subprocess.DEVNULL)
        
        if result.returncode == 0:
            password = result.stdout.strip()
            if password:
                passwords[server_name] = password
                password_count += 1
    except:
        pass

print(f"Extracted {password_count} passwords")

with open('$TEMP_PASSWORDS_FILE', 'w') as f:
    json.dump(passwords, f)
EOF

PASSWORD_COUNT=$(python3 -c "
import json
with open('$TEMP_PASSWORDS_FILE', 'r') as f:
    passwords = json.load(f)
print(len(passwords))
")

print_success "Extracted $PASSWORD_COUNT passwords from Keychain"

# Get export format preference
echo
if [[ "$HAS_FOLDERS" == "true" ]]; then
    echo "Export Format Options:"
    echo "  1) Full export with folders (v2.0) - for folder-enabled systems"
    echo "  2) Legacy export without folders (v1.0) - for compatibility with old systems"
    echo "  3) Auto-detect target system compatibility"
    echo
    
    while true; do
        echo -n "Choose export format [1-3]: "
        read EXPORT_CHOICE
        
        case $EXPORT_CHOICE in
            1)
                EXPORT_VERSION="2.0"
                INCLUDE_FOLDERS=true
                print_status "Selected: Full export with folders (v2.0)"
                break
                ;;
            2)
                EXPORT_VERSION="1.0"
                INCLUDE_FOLDERS=false
                print_status "Selected: Legacy export without folders (v1.0)"
                break
                ;;
            3)
                EXPORT_VERSION="2.0"
                INCLUDE_FOLDERS=true
                print_status "Selected: Auto-detect (defaulting to v2.0 with folders)"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
else
    EXPORT_VERSION="1.0"
    INCLUDE_FOLDERS=false
    print_status "Using legacy export format (v1.0) - no folders available"
fi

# Create export bundle
print_status "Creating export bundle..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_BUNDLE="/tmp/wezterm_export_bundle_$$.json"

python3 << EOF
import json
import datetime
import os

# Load servers
with open('$SERVERS_FILE', 'r') as f:
    servers = json.load(f)

# Load passwords
with open('$TEMP_PASSWORDS_FILE', 'r') as f:
    passwords = json.load(f)

# Load folders if available and requested
folders = []
folders_count = 0
if '$INCLUDE_FOLDERS' == 'true' and os.path.exists('$FOLDERS_FILE'):
    try:
        with open('$FOLDERS_FILE', 'r') as f:
            folders = json.load(f)
        folders_count = len(folders)
    except:
        folders = []

# For v1.0 export, strip folder_id from servers
if '$EXPORT_VERSION' == '1.0':
    for server in servers:
        if 'folder_id' in server:
            del server['folder_id']

# Create export bundle
export_data = {
    "version": "$EXPORT_VERSION",
    "exported_at": datetime.datetime.utcnow().isoformat() + "Z",
    "exporter": "WezTerm SSH Export Script",
    "encryption": {
        "method": "aes-256-cbc",
        "iterations": 10000
    },
    "has_folders": '$INCLUDE_FOLDERS' == 'true',
    "servers": servers,
    "passwords": passwords
}

# Add folders for v2.0 exports
if '$EXPORT_VERSION' == '2.0' and '$INCLUDE_FOLDERS' == 'true':
    export_data["folders"] = folders

with open('$TEMP_BUNDLE', 'w') as f:
    json.dump(export_data, f, indent=2)

if '$EXPORT_VERSION' == '2.0' and '$INCLUDE_FOLDERS' == 'true':
    print(f"Bundle created with {len(servers)} servers, {len(passwords)} passwords, and {folders_count} folders")
else:
    print(f"Bundle created with {len(servers)} servers and {len(passwords)} passwords (legacy format)")
EOF

# Get encryption password
echo
while true; do
    echo -n "Enter password for encryption (min 8 chars): "
    read -s ENCRYPT_PASSWORD
    echo
    
    if [[ ${#ENCRYPT_PASSWORD} -lt 8 ]]; then
        print_error "Password must be at least 8 characters"
        continue
    fi
    
    echo -n "Confirm password: "
    read -s CONFIRM_PASSWORD
    echo
    
    if [[ "$ENCRYPT_PASSWORD" != "$CONFIRM_PASSWORD" ]]; then
        print_error "Passwords do not match"
        continue
    fi
    
    break
done

# Encrypt bundle
OUTPUT_FILE="$HOME/Downloads/ssh_launcher_export_$TIMESTAMP.enc"
print_status "Encrypting bundle..."

if openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 \
   -in "$TEMP_BUNDLE" -out "$OUTPUT_FILE" \
   -pass pass:"$ENCRYPT_PASSWORD" 2>/dev/null; then
    
    print_success "Export completed successfully!"
    echo
    echo -e "${GREEN}📁 Exported file: ${NC}$OUTPUT_FILE"
    if [[ "$EXPORT_VERSION" == "2.0" && "$INCLUDE_FOLDERS" == "true" ]]; then
        echo -e "${GREEN}📊 Contains: ${NC}$SERVER_COUNT servers with $PASSWORD_COUNT passwords and folders"
        echo -e "${GREEN}📂 Version: ${NC}v2.0 (folder-enabled)"
    else
        echo -e "${GREEN}📊 Contains: ${NC}$SERVER_COUNT servers with $PASSWORD_COUNT passwords"
        echo -e "${GREEN}📂 Version: ${NC}v1.0 (legacy compatibility)"
    fi
    echo -e "${GREEN}🔐 Encryption: ${NC}AES-256-CBC with PBKDF2 (10,000 iterations)"
    echo -e "${GREEN}📏 File size: ${NC}$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
    
    # Set secure permissions
    chmod 600 "$OUTPUT_FILE"
    
else
    print_error "Failed to encrypt export bundle"
    rm -f "$TEMP_BUNDLE" "$TEMP_PASSWORDS_FILE"
    exit 1
fi

# Cleanup
rm -f "$TEMP_BUNDLE" "$TEMP_PASSWORDS_FILE"

echo
print_success "Export process complete! 🚀"
echo
echo "To import this configuration:"
echo "  ~/.config/wezterm/ssh_import.sh"
echo