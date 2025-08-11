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
if [[ ! -f "$SERVERS_FILE" ]]; then
    print_error "servers.json not found at $SERVERS_FILE"
    exit 1
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

# Create export bundle
print_status "Creating export bundle..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_BUNDLE="/tmp/wezterm_export_bundle_$$.json"

python3 << EOF
import json
import datetime

# Load servers
with open('$SERVERS_FILE', 'r') as f:
    servers = json.load(f)

# Load passwords
with open('$TEMP_PASSWORDS_FILE', 'r') as f:
    passwords = json.load(f)

# Create export bundle
export_data = {
    "version": "1.0",
    "exported_at": datetime.datetime.utcnow().isoformat() + "Z",
    "exporter": "WezTerm SSH Export Script",
    "encryption": {
        "method": "aes-256-cbc",
        "iterations": 10000
    },
    "servers": servers,
    "passwords": passwords
}

with open('$TEMP_BUNDLE', 'w') as f:
    json.dump(export_data, f, indent=2)

print(f"Bundle created with {len(servers)} servers and {len(passwords)} passwords")
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
    echo -e "${GREEN}📊 Contains: ${NC}$SERVER_COUNT servers with $PASSWORD_COUNT passwords"
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