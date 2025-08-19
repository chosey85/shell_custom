#!/bin/bash

# WezTerm SSH Configuration Import Script v5.0
# Imports encrypted bundles back to servers.json and Keychain
# Fixed subprocess bug in password import

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

print_debug() {
    echo -e "${YELLOW}[DEBUG]${NC} $1"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
   _____ _____ _   _   _____                            _   
  / ____/ ____| | | | |_   _|                          | |  
 | (___| (___ | |_| |   | |  _ __ ___  _ __   ___  _ __| |_ 
  \___ \___ \|  _  |   | | | '_ ` _ \| '_ \ / _ \| '__| __|
  ____) |___) | | | |  _| |_| | | | | | |_) | (_) | |  | |_ 
 |_____/_____/|_| |_| |_____|_| |_| |_| .__/ \___/|_|   \__|
                                     | |                   
                                     |_|                   
EOF
echo -e "${NC}"
echo "WezTerm SSH Configuration Import Tool v5.0"
echo "=========================================="
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

print_debug "Decrypted file created: $TEMP_DECRYPTED"

# Validate and extract data in one step
cat > "/tmp/validate_$$.py" << EOF
import json
import sys

temp_file = '$TEMP_DECRYPTED'

try:
    with open(temp_file, 'r') as f:
        data = json.load(f)
    
    # Validate structure
    if 'version' not in data or 'servers' not in data:
        print("ERROR: Invalid export file format", file=sys.stderr)
        sys.exit(1)
    
    version = data['version']
    if version not in ['1.0', '2.0']:
        print(f"ERROR: Incompatible version {version}", file=sys.stderr)
        sys.exit(1)
    
    server_count = len(data.get('servers', []))
    password_count = len(data.get('passwords', {}))
    exported_at = data.get('exported_at', 'unknown')
    has_folders = data.get('has_folders', False)
    folder_count = len(data.get('folders', [])) if has_folders else 0
    
    # Output in a parseable format
    print(f"VERSION={version}")
    print(f"SERVER_COUNT={server_count}")
    print(f"PASSWORD_COUNT={password_count}")
    print(f"EXPORTED_AT={exported_at}")
    print(f"HAS_FOLDERS={has_folders}")
    print(f"FOLDER_COUNT={folder_count}")
    
except Exception as e:
    print(f"ERROR: Failed to parse import file: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# Run validation and source the output
VALIDATION_OUTPUT="/tmp/validation_$$.env"
if python3 "/tmp/validate_$$.py" > "$VALIDATION_OUTPUT" 2>&1; then
    source "$VALIDATION_OUTPUT"
    rm -f "$VALIDATION_OUTPUT" "/tmp/validate_$$.py"
else
    cat "$VALIDATION_OUTPUT"
    rm -f "$VALIDATION_OUTPUT" "/tmp/validate_$$.py" "$TEMP_DECRYPTED"
    exit 1
fi

print_success "Import file validated successfully"
echo "  📂 Version: v$VERSION"
if [[ "$HAS_FOLDERS" == "True" ]]; then
    echo "  📊 Contains: $SERVER_COUNT servers, $PASSWORD_COUNT passwords, and $FOLDER_COUNT folders"
else
    echo "  📊 Contains: $SERVER_COUNT servers with $PASSWORD_COUNT passwords (no folders)"
fi
echo "  📅 Exported: $EXPORTED_AT"

# Check current configuration and system compatibility
SERVERS_FILE="$HOME/.config/wezterm/servers.json"
FOLDERS_FILE="$HOME/.config/wezterm/folders.json"
CURRENT_SERVER_COUNT=0
CURRENT_HAS_FOLDERS=false

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

if [[ -f "$FOLDERS_FILE" ]]; then
    CURRENT_HAS_FOLDERS=true
    print_status "Current system: Folder-enabled (v2.0)"
else
    print_status "Current system: Legacy (v1.0)"
fi

# Determine migration scenario
echo
if [[ "$HAS_FOLDERS" == "True" && "$CURRENT_HAS_FOLDERS" == "false" ]]; then
    print_warning "Migration: v2.0 export → v1.0 system (folders will be removed)"
    MIGRATION_TYPE="v2_to_v1"
elif [[ "$HAS_FOLDERS" == "False" && "$CURRENT_HAS_FOLDERS" == "true" ]]; then
    print_warning "Migration: v1.0 export → v2.0 system (servers will be placed in Root folder)"
    MIGRATION_TYPE="v1_to_v2"
elif [[ "$HAS_FOLDERS" == "True" && "$CURRENT_HAS_FOLDERS" == "true" ]]; then
    print_status "Compatible: v2.0 export → v2.0 system (full compatibility)"
    MIGRATION_TYPE="v2_to_v2"
else
    print_status "Compatible: v1.0 export → v1.0 system (no changes needed)"
    MIGRATION_TYPE="v1_to_v1"
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
fi

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config/wezterm"

# Import servers and folders
print_status "Importing server configurations and folders..."

cat > "/tmp/import_data_$$.py" << EOF
import json
import os

# Read the decrypted data
temp_file = '$TEMP_DECRYPTED'
with open(temp_file, 'r') as f:
    data = json.load(f)

servers = data['servers']
print(f"Loaded {len(servers)} servers from import file")

# Apply migration logic
migration_type = '$MIGRATION_TYPE'
print(f"Applying migration: {migration_type}")

if migration_type == 'v2_to_v1':
    # v2.0 → v1.0: Strip folder_id from servers
    print("Removing folder references from servers")
    for server in servers:
        if 'folder_id' in server:
            del server['folder_id']
            
elif migration_type == 'v1_to_v2':
    # v1.0 → v2.0: Add folder_id = "root" to all servers
    print("Assigning servers to Root folder")
    for server in servers:
        server['folder_id'] = 'root'

# Handle existing servers for merge mode
if '$IMPORT_MODE' == 'merge':
    print("Merge mode: loading existing servers")
    existing_servers = []
    servers_file = '$SERVERS_FILE'
    if os.path.exists(servers_file) and $CURRENT_SERVER_COUNT > 0:
        with open(servers_file, 'r') as f:
            existing_servers = json.load(f)
    
    # Create name set for duplicate checking
    existing_names = {server['name'] for server in existing_servers}
    
    # Add new servers (skip duplicates)
    added_count = 0
    for import_server in servers:
        if import_server['name'] not in existing_names:
            existing_servers.append(import_server)
            added_count += 1
    
    servers = existing_servers
    print(f"Merge completed: added {added_count} new servers")

# Save servers
servers_file = '$SERVERS_FILE'
print(f"Writing {len(servers)} servers to {servers_file}")
with open(servers_file, 'w') as f:
    json.dump(servers, f, indent=2)
print("Servers saved successfully")

# Handle folders
folders_file = '$FOLDERS_FILE'
migration_type = '$MIGRATION_TYPE'

if migration_type in ['v2_to_v2', 'v1_to_v2']:
    # Need to handle folders
    if migration_type == 'v2_to_v2':
        # Import folders from export
        folders = data.get('folders', [])
        print(f"Importing {len(folders)} folders from export")
        
        # Ensure root folder has proper parent field
        for folder in folders:
            if folder.get('id') == 'root' and 'parent' not in folder:
                folder['parent'] = None
                print("Fixed missing parent field in root folder")
    
    else:  # v1_to_v2
        # Create default folder structure
        print("Creating default folder structure")
        folders = [{"id": "root", "name": "Root", "parent": None}]
    
    print(f"Writing {len(folders)} folders to {folders_file}")
    with open(folders_file, 'w') as f:
        json.dump(folders, f, indent=2)
    print("Folders saved successfully")

elif migration_type == 'v2_to_v1':
    # Remove folders.json for legacy system
    if os.path.exists(folders_file):
        os.remove(folders_file)
        print("Removed folders.json for legacy compatibility")

print("Data import completed successfully")
EOF

# Run the import
python3 "/tmp/import_data_$$.py"
rm -f "/tmp/import_data_$$.py"

# Import passwords
print_status "Importing $PASSWORD_COUNT passwords to Keychain..."

if [[ $PASSWORD_COUNT -gt 0 ]]; then
    # Clear existing passwords if replacing
    if [[ "$IMPORT_MODE" == "replace" && $CURRENT_SERVER_COUNT -gt 0 && -f "$BACKUP_FILE" ]]; then
        print_status "Clearing existing Keychain passwords..."
        cat > "/tmp/clear_passwords_$$.py" << EOF
import json
import subprocess

backup_file = '$BACKUP_FILE'
try:
    with open(backup_file, 'r') as f:
        servers = json.load(f)
    
    cleared_count = 0
    for server in servers:
        server_name = server['name']
        service = f"wezterm-ssh-{server_name}"
        result = subprocess.run([
            'security', 'delete-generic-password', 
            '-s', service, '-a', 'password'
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            cleared_count += 1
    
    print(f"Cleared {cleared_count} existing passwords")
except Exception as e:
    print(f"Error clearing passwords: {e}")
EOF
        python3 "/tmp/clear_passwords_$$.py"
        rm -f "/tmp/clear_passwords_$$.py"
    fi
    
    # Import new passwords with fixed subprocess calls
    cat > "/tmp/import_passwords_$$.py" << EOF
import json
import subprocess
import sys

temp_file = '$TEMP_DECRYPTED'
with open(temp_file, 'r') as f:
    data = json.load(f)

passwords = data.get('passwords', {})
print(f"Starting import of {len(passwords)} passwords...")

success_count = 0
failed_count = 0

for server_name, password in passwords.items():
    service = f"wezterm-ssh-{server_name}"
    account = "password"
    
    try:
        # Add new password - FIXED: no stderr parameter with capture_output
        result = subprocess.run([
            'security', 'add-generic-password', 
            '-s', service, '-a', account, '-w', password
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            success_count += 1
            print(f"✓ Imported password for: {server_name}")
        else:
            failed_count += 1
            error_msg = result.stderr.strip() if result.stderr else "Unknown error"
            if "already exists" in error_msg:
                # Try to update existing password
                subprocess.run([
                    'security', 'delete-generic-password', 
                    '-s', service, '-a', account
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                retry_result = subprocess.run([
                    'security', 'add-generic-password', 
                    '-s', service, '-a', account, '-w', password
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                if retry_result.returncode == 0:
                    success_count += 1
                    failed_count -= 1
                    print(f"✓ Updated password for: {server_name}")
                else:
                    print(f"✗ Failed to update password for: {server_name}")
            else:
                print(f"✗ Failed to import password for {server_name}: {error_msg}")
            
    except Exception as e:
        failed_count += 1
        print(f"✗ Exception importing password for {server_name}: {str(e)}")

print(f"Password import completed: {success_count} successful, {failed_count} failed")
print(f"SUCCESS_COUNT={success_count}")
EOF

    # Run password import and capture success count
    PASSWORD_OUTPUT=$(python3 "/tmp/import_passwords_$$.py")
    echo "$PASSWORD_OUTPUT"
    
    # Extract success count from output
    PASSWORD_SUCCESS_COUNT=$(echo "$PASSWORD_OUTPUT" | grep "SUCCESS_COUNT=" | cut -d'=' -f2)
    
    rm -f "/tmp/import_passwords_$$.py"
else
    print_warning "No passwords to import"
    PASSWORD_SUCCESS_COUNT=0
fi

# Clean up
rm -f "$TEMP_DECRYPTED"

# Verify results
print_status "Verifying import results..."

# Check folders
if [[ "$CURRENT_HAS_FOLDERS" == "true" || "$HAS_FOLDERS" == "True" ]]; then
    if [[ -f "$FOLDERS_FILE" && -s "$FOLDERS_FILE" ]]; then
        FINAL_FOLDER_COUNT=$(python3 -c "
import json
try:
    with open('$FOLDERS_FILE', 'r') as f:
        folders = json.load(f)
    print(len(folders))
except:
    print(0)
")
        print_success "folders.json verified: $FINAL_FOLDER_COUNT folders"
    else
        print_warning "folders.json missing or empty"
    fi
fi

# Check servers
FINAL_SERVER_COUNT=$(python3 -c "
import json
try:
    with open('$SERVERS_FILE', 'r') as f:
        servers = json.load(f)
    print(len(servers))
except:
    print(0)
")

# Results
echo
print_success "Import completed successfully! 🎉"
echo
echo -e "${GREEN}📊 Results:${NC}"
echo "  • Final server count: $FINAL_SERVER_COUNT"
echo "  • Passwords imported: $PASSWORD_SUCCESS_COUNT/$PASSWORD_COUNT"

if [[ $PASSWORD_SUCCESS_COUNT -lt $PASSWORD_COUNT ]]; then
    FAILED_PASSWORDS=$(($PASSWORD_COUNT - $PASSWORD_SUCCESS_COUNT))
    print_warning "$FAILED_PASSWORDS passwords failed to import"
fi

echo
print_success "SSH configuration restore complete! 🚀"
echo
echo "You can now use Ctrl+Shift+S to access your imported servers."
echo "Servers should appear organized in folders with working passwords."