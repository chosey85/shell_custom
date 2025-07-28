#!/bin/bash

# Shell Custom Configuration Installer for macOS
# This script installs and configures a complete terminal environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup existing file/directory
backup_if_exists() {
    local path="$1"
    if [ -e "$path" ]; then
        local backup_path="${path}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backing up existing $path to $backup_path"
        mv "$path" "$backup_path"
    fi
}

# ASCII Art Banner
echo -e "${BLUE}"
cat << "EOF"
   _____ __         ____   ______           __                
  / ___// /_  ___  / / /  / ____/_  _______/ /_____  ____ ___ 
  \__ \/ __ \/ _ \/ / /  / /   / / / / ___/ __/ __ \/ __ `__ \
 ___/ / / / /  __/ / /  / /___/ /_/ (__  ) /_/ /_/ / / / / / /
/____/_/ /_/\___/_/_/   \____/\__,_/____/\__/\____/_/ /_/ /_/ 
                                                               
EOF
echo -e "${NC}"
echo "Shell Custom Configuration Installer v1.0"
echo "========================================="
echo

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This installer is designed for macOS only"
    exit 1
fi

print_status "Starting installation process..."

# Step 1: Install Homebrew if not installed
if ! command_exists brew; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_success "Homebrew is already installed"
fi

# Step 2: Update Homebrew
print_status "Updating Homebrew..."
brew update

# Step 3: Install required packages
print_status "Installing required packages..."

# Core tools
packages=(
    "zsh"
    "neovim"
    "wezterm"
    "fzf"
    "ripgrep"
    "fd"
    "lsd"
    "node"
    "python3"
)

for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        print_success "$package is already installed"
    else
        print_status "Installing $package..."
        brew install "$package"
    fi
done

# Step 4: Install JetBrains Mono Nerd Font
print_status "Installing JetBrains Mono Nerd Font..."
if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    brew tap homebrew/cask-fonts
    brew install --cask font-jetbrains-mono-nerd-font
else
    print_success "JetBrains Mono Nerd Font is already installed"
fi

# Step 4.5: Install Cyberduck (optional, for WezTerm SSH integration)
print_status "Installing Cyberduck for SSH file transfer integration..."
if ! brew list --cask cyberduck &>/dev/null; then
    brew install --cask cyberduck
else
    print_success "Cyberduck is already installed"
fi

# Step 5: Install Python packages for Neovim
print_status "Installing Python packages for Neovim..."
pip3 install --user pynvim

# Step 6: Set Zsh as default shell if needed
if [[ "$SHELL" != *"zsh"* ]]; then
    print_status "Setting Zsh as default shell..."
    chsh -s $(which zsh)
    print_warning "Shell changed to Zsh. You may need to log out and back in for changes to take effect."
else
    print_success "Zsh is already the default shell"
fi

# Step 7: Install configuration files
print_status "Installing configuration files..."

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Zsh configuration
print_status "Installing Zsh configuration..."
backup_if_exists "$HOME/.zshrc"
cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/"
print_success "Zsh configuration installed"

# macOS-specific Zsh config if exists
if [ -f "$SCRIPT_DIR/zsh/macos.zsh" ]; then
    mkdir -p "$HOME/.zsh"
    cp "$SCRIPT_DIR/zsh/macos.zsh" "$HOME/.zsh/"
    print_success "macOS-specific Zsh configuration installed"
fi

# Powerlevel10k configuration
print_status "Installing Powerlevel10k configuration..."
backup_if_exists "$HOME/.p10k.zsh"
cp "$SCRIPT_DIR/powerlevel10k/.p10k.zsh" "$HOME/"
print_success "Powerlevel10k configuration installed"

# WezTerm configuration
print_status "Installing WezTerm configuration..."
mkdir -p "$HOME/.config/wezterm"
backup_if_exists "$HOME/.config/wezterm/wezterm.lua"
cp "$SCRIPT_DIR/wezterm/"*.lua "$HOME/.config/wezterm/"
print_success "WezTerm configuration installed"

# Neovim configuration
print_status "Installing Neovim configuration..."
backup_if_exists "$HOME/.config/nvim"
cp -r "$SCRIPT_DIR/nvim" "$HOME/.config/"
print_success "Neovim configuration installed"

# Step 8: Install fzf key bindings and completion
print_status "Installing fzf key bindings and completion..."
if [ ! -f "$HOME/.fzf.zsh" ]; then
    $(brew --prefix)/opt/fzf/install --all --no-bash --no-fish
else
    print_success "fzf key bindings are already installed"
fi

# Step 9: Install Zinit (will be done automatically on first Zsh launch)
print_status "Zinit will be installed automatically on first Zsh launch"

# Step 10: Final setup instructions
echo
echo -e "${GREEN}================================"
echo "Installation Complete!"
echo "================================${NC}"
echo
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Zinit plugins will install automatically on first launch"
echo "3. Open Neovim and wait for plugins to install (automatic)"
echo "4. Configure WezTerm as your default terminal"
echo
echo "Optional customizations:"
echo "- Run 'p10k configure' to customize your prompt"
echo "- Edit ~/.config/wezterm/wezterm.lua to change themes"
echo "- Check the README.md for more customization options"
echo
print_success "Enjoy your new shell environment! 🚀"