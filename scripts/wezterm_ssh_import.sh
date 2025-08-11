#!/bin/bash

# WezTerm SSH Configuration Import Script  
# Imports encrypted bundles back to servers.json and Keychain

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
   _____ _____ _   _   _____                            _   
  / ____/ ____| | | | |_   _|                          | |  
 | (___| (___ | |_| |   | |  _ __ ___  _ __   ___  _ __| |_ 
  \___ \\___ \|  _  |   | | | '_ ` _ \| '_ \ / _ \| '__| __|
  ____) |___) | | | |  _| |_| | | | | | |_) | (_) | |  | |_ 
 |_____/_____/|_| |_| |_____|_| |_| |_| .__/ \___/|_|   \__|
                                     | |                   
                                     |_|                   
EOF
echo -e "${NC}"
echo "WezTerm SSH Configuration Import Tool"
echo "====================================="
echo

# Get import file path
if [[ $# -eq 1 ]]; then
    IMPORT_FILE="$1"
else
    echo -n "Enter path to encrypted export file: "
    read IMPORT_FILE
fi

# Expand ~ to home directory
IMPORT_FILE="${IMPORT_FILE/#\~/$HOME}"

# Check if import file exists
if [[ ! -f "$IMPORT_FILE" ]]; then
    print_error "Import file not found: $IMPORT_FILE"
    exit 1
fi

print_status "Import file: $IMPORT_FILE"
print_status "File size: $(ls -lh "$IMPORT_FILE" | awk '{print $5}')"

# Get decryption password
echo -n "Enter decryption password: "
read -s DECRYPT_PASSWORD
echo

# Decrypt and validate
print_status "Decrypting and validating import file..."
TEMP_DECRYPTED="/tmp/wezterm_import_$$.json"

if ! openssl enc -aes-256-cbc -d -pbkdf2 -iter 10000 \
     -in "$IMPORT_FILE" -out "$TEMP_DECRYPTED" \
     -pass pass:"$DECRYPT_PASSWORD" 2>/dev/null; then
    print_error "Decryption failed - check password"
    rm -f "$TEMP_DECRYPTED"
    exit 1
fi

# Validate JSON and extract info
IMPORT_INFO=$(python3 << EOF
import json
import sys

try:
    with open('$TEMP_DECRYPTED', 'r') as f:
        data = json.load(f)
    
    # Validate structure
    if 'version' not in data or 'servers' not in data:
        print("ERROR: Invalid export file format")
        sys.exit(1)
    
    if data['version'] != '1.0':
        print(f"ERROR: Incompatible version {data['version']}")
        sys.exit(1)
    
    server_count = len(data.get('servers', []))
    password_count = len(data.get('passwords', {}))
    exported_at = data.get('exported_at', 'unknown')
    
    print(f"VALID:{server_count}:{password_count}:{exported_at}")
    
except Exception as e:
    print(f"ERROR: Failed to parse import file: {e}")
    sys.exit(1)
EOF
)

if [[ $IMPORT_INFO == ERROR:* ]]; then
    print_error "${IMPORT_INFO#ERROR: }"
    rm -f "$TEMP_DECRYPTED"
    exit 1
fi

# Parse import info
IFS=':' read -r _ IMPORT_SERVER_COUNT IMPORT_PASSWORD_COUNT EXPORTED_AT <<< "$IMPORT_INFO"

print_success "Import file validated successfully"
echo "  📊 Contains: $IMPORT_SERVER_COUNT servers with $IMPORT_PASSWORD_COUNT passwords"
echo "  📅 Exported: $EXPORTED_AT"

# Check current configuration
SERVERS_FILE="$HOME/.config/wezterm/servers.json"
CURRENT_SERVER_COUNT=0

if [[ -f "$SERVERS_FILE" ]]; then
    CURRENT_SERVER_COUNT=$(python3 -c "
import json
try:
    with open('$SERVERS_FILE', 'r') as f:
        data = json.load(f)
    print(len(data))
except:
    print(0)
    ")
    print_status "Current configuration: $CURRENT_SERVER_COUNT servers"
else
    print_warning "No existing configuration found"
fi

echo
echo "Import Options:"
echo "  1) Replace all existing servers (recommended)"
echo "  2) Merge with existing servers (skip duplicates)"
echo "  3) Cancel import"
echo

while true; do
    echo -n "Choose option [1-3]: "
    read CHOICE
    
    case $CHOICE in
        1)
            IMPORT_MODE="replace"
            print_status "Selected: Replace all existing servers"
            break
            ;;
        2)
            IMPORT_MODE="merge"
            print_status "Selected: Merge with existing servers"
            break
            ;;
        3)
            print_status "Import cancelled"
            rm -f "$TEMP_DECRYPTED"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done

# Backup current configuration
if [[ -f "$SERVERS_FILE" && $CURRENT_SERVER_COUNT -gt 0 ]]; then
    BACKUP_FILE="$SERVERS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Creating backup: $BACKUP_FILE"
    cp "$SERVERS_FILE" "$BACKUP_FILE"
    
    # Backup current passwords
    print_status "Backing up current Keychain passwords..."
    TEMP_BACKUP_PASSWORDS="/tmp/wezterm_backup_passwords_$$.json"
    
    python3 << EOF
import json
import subprocess

# Read current servers
with open('$SERVERS_FILE', 'r') as f:
    servers = json.load(f)

passwords = {}
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
    except:
        pass

with open('$TEMP_BACKUP_PASSWORDS', 'w') as f:
    json.dump(passwords, f)
EOF
fi

# Import servers
print_status "Importing server configurations..."

if [[ "$IMPORT_MODE" == "replace" ]]; then
    # Clear existing passwords if replacing
    if [[ $CURRENT_SERVER_COUNT -gt 0 ]]; then
        print_status "Clearing existing Keychain passwords..."
        python3 << EOF
import json
import subprocess

with open('$BACKUP_FILE', 'r') as f:
    servers = json.load(f)

for server in servers:
    server_name = server['name']
    service = f"wezterm-ssh-{server_name}"
    subprocess.run([
        'security', 'delete-generic-password', 
        '-s', service, '-a', 'password'
    ], stderr=subprocess.DEVNULL)
EOF
    fi
    
    # Copy new servers directly
    python3 << EOF
import json

with open('$TEMP_DECRYPTED', 'r') as f:
    data = json.load(f)

with open('$SERVERS_FILE', 'w') as f:
    json.dump(data['servers'], f, indent=2)
EOF
    
    FINAL_COUNT=$IMPORT_SERVER_COUNT
    
else
    # Merge mode
    python3 << EOF
import json

# Load import data
with open('$TEMP_DECRYPTED', 'r') as f:
    import_data = json.load(f)

# Load existing servers (if any)
existing_servers = []
if '$CURRENT_SERVER_COUNT' != '0':
    with open('$SERVERS_FILE', 'r') as f:
        existing_servers = json.load(f)

# Create name set for duplicate checking
existing_names = {server['name'] for server in existing_servers}

# Add new servers (skip duplicates)
added_count = 0
for import_server in import_data['servers']:
    if import_server['name'] not in existing_names:
        existing_servers.append(import_server)
        added_count += 1

# Save merged servers
with open('$SERVERS_FILE', 'w') as f:
    json.dump(existing_servers, f, indent=2)

print(f"{added_count}")
EOF
    ADDED_COUNT=$(python3 << 'EOF'
import json

with open('/tmp/wezterm_import_$$.json', 'r') as f:
    import_data = json.load(f)

existing_servers = []
if int('$CURRENT_SERVER_COUNT') > 0:
    with open('$SERVERS_FILE', 'r') as f:
        existing_servers = json.load(f)

existing_names = {server['name'] for server in existing_servers}
added_count = sum(1 for server in import_data['servers'] if server['name'] not in existing_names)
print(added_count)
EOF
)
    
    FINAL_COUNT=$(($CURRENT_SERVER_COUNT + $ADDED_COUNT))
fi

# Import passwords
print_status "Importing passwords to Keychain..."

PASSWORD_SUCCESS_COUNT=$(python3 << EOF
import json
import subprocess

with open('$TEMP_DECRYPTED', 'r') as f:
    data = json.load(f)

passwords = data.get('passwords', {})
success_count = 0

for server_name, password in passwords.items():
    service = f"wezterm-ssh-{server_name}"
    account = "password"
    
    try:
        # Delete existing password first
        subprocess.run([
            'security', 'delete-generic-password', 
            '-s', service, '-a', account
        ], stderr=subprocess.DEVNULL)
        
        # Add new password
        result = subprocess.run([
            'security', 'add-generic-password', 
            '-s', service, '-a', account, '-w', password
        ], stderr=subprocess.DEVNULL)
        
        if result.returncode == 0:
            success_count += 1
            
    except Exception as e:
        pass

print(success_count)
EOF
)

# Cleanup
rm -f "$TEMP_DECRYPTED" "$TEMP_BACKUP_PASSWORDS" 2>/dev/null

# Results
echo
print_success "Import completed successfully! 🎉"
echo
echo -e "${GREEN}📊 Results:${NC}"
echo "  • Final server count: $FINAL_COUNT"
if [[ "$IMPORT_MODE" == "merge" ]]; then
    echo "  • Servers added: $ADDED_COUNT"
    echo "  • Servers kept: $CURRENT_SERVER_COUNT"
fi
echo "  • Passwords imported: $PASSWORD_SUCCESS_COUNT/$IMPORT_PASSWORD_COUNT"

if [[ $PASSWORD_SUCCESS_COUNT -lt $IMPORT_PASSWORD_COUNT ]]; then
    FAILED_PASSWORDS=$(($IMPORT_PASSWORD_COUNT - $PASSWORD_SUCCESS_COUNT))
    print_warning "$FAILED_PASSWORDS passwords failed to import"
fi

echo
print_success "SSH configuration restore complete! 🚀"
echo
echo "You can now use Ctrl+Shift+S to access your imported servers."