# Shell Custom Configuration

Welcome to my personal shell and development environment configuration repository. This collection of dotfiles and configurations creates a powerful, efficient, and visually appealing command-line experience.

## Screenshots

![Terminal Setup](https://github.com/user-attachments/assets/5ebc5034-714c-447c-9459-eb3c0c160c62)
*fzf tab completion example*

![Neovim Setup](https://github.com/user-attachments/assets/cabed93b-fe19-4ba5-a372-0a5fbe3eba79)
*Neovim with Neotree file explorer*

## Features

### Terminal Setup
- **WezTerm**: GPU-accelerated terminal with custom themes (Melange/Catppuccin)
- **Zsh + Zinit**: Fast plugin management with syntax highlighting, autosuggestions, and completions
- **Powerlevel10k**: Beautiful prompt with git status, command execution time, and timestamps
- **fzf**: Fuzzy finder integration for files, history, and tab completion
- **Custom Key Bindings**: Productivity shortcuts for SSH, file management, and more

### Visual Customization
- **Themes**: Melange (default) and Catppuccin color schemes
- **Font**: JetBrains Mono Nerd Font (DemiBold, 15.5pt)
- **Transparency**: 90% window opacity for a modern look
- **Cursor**: Blinking yellow-green block cursor (500ms rate)
- **Timestamps**: Gray timestamps showing when each command was executed

### Neovim Configuration
- **Plugin Manager**: lazy.nvim for fast startup
- **File Explorer**: Neo-tree with icons
- **Fuzzy Finding**: Telescope for files, buffers, and grep
- **Syntax Highlighting**: Tree-sitter for accurate highlighting
- **Themes**: Catppuccin and Melange color schemes

## Quick Install

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/shell_custom.git ~/workspace/shell_custom

# Run the installer
cd ~/workspace/shell_custom
./install.sh
```

## Manual Installation

### Prerequisites

1. **Install Homebrew** (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Install Required Tools**:
```bash
# Core tools
brew install zsh neovim wezterm fzf ripgrep fd lsd

# Node.js for Neovim plugins
brew install node

# Python for Neovim
brew install python3
pip3 install pynvim

# Cyberduck for SSH file transfer integration (optional)
brew install --cask cyberduck
```

3. **Install JetBrains Mono Nerd Font**:
```bash
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

### Configuration Files

1. **Zsh Configuration**:
```bash
# Backup existing config
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup

# Copy new config
cp zsh/.zshrc ~/
[ -f zsh/macos.zsh ] && mkdir -p ~/.zsh && cp zsh/macos.zsh ~/.zsh/
```

2. **Powerlevel10k Theme**:
```bash
# Backup existing config
[ -f ~/.p10k.zsh ] && mv ~/.p10k.zsh ~/.p10k.zsh.backup

# Copy new config
cp powerlevel10k/.p10k.zsh ~/
```

3. **WezTerm Configuration**:
```bash
# Create config directory
mkdir -p ~/.config/wezterm

# Copy config files
cp wezterm/*.lua ~/.config/wezterm/
```

4. **Neovim Configuration**:
```bash
# Backup existing config
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup

# Copy new config
cp -r nvim ~/.config/
```

### Post-Installation

1. **Set Zsh as Default Shell**:
```bash
chsh -s $(which zsh)
```

2. **Install Zinit Plugins** (automatic on first launch)

3. **Install Neovim Plugins**:
```bash
nvim +Lazy sync +qa
```

## Key Bindings

### WezTerm
- `Ctrl+Shift+T`: New tab
- `Ctrl+Shift+W`: Close tab
- `Ctrl+Shift+H`: Split horizontally
- `Ctrl+Shift+V`: Split vertically
- `Ctrl+Shift+C`: Open Cyberduck SCP to current SSH host (requires Cyberduck)
- `Ctrl+Shift+K`: Open termscp to lab1010

### Zsh
- `Ctrl+P`: History search backward
- `Ctrl+N`: History search forward
- `Tab`: fzf-powered completion

## Customization

### Change Terminal Theme
Edit `~/.config/wezterm/wezterm.lua`:
```lua
local current_theme = "melange"  -- Change to "catppuccin"
```

### Adjust Transparency
Edit `~/.config/wezterm/wezterm.lua`:
```lua
config.window_background_opacity = 0.9  -- Range: 0.0 to 1.0
```

### Modify Prompt
Run `p10k configure` to reconfigure the Powerlevel10k prompt interactively.

## Troubleshooting

### Fonts Not Displaying Correctly
Ensure JetBrains Mono Nerd Font is installed and WezTerm is configured to use it.

### Zsh Plugins Not Loading
Run `zinit self-update` and restart your terminal.

### Neovim Plugins Issues
Run `:checkhealth` in Neovim to diagnose issues.

## Third-Party Software

This repository configures the following third-party tools:

- [Zsh](https://www.zsh.org/)
- [Zinit](https://github.com/zdharma-continuum/zinit)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [WezTerm](https://wezfurlong.org/wezterm/)
- [Neovim](https://neovim.io/)
- [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [lsd](https://github.com/lsd-rs/lsd)

## License

This configuration is provided as-is for personal use. Please respect the licenses of all third-party software.