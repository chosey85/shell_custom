# 🚀 Shell Custom Configuration

Welcome to an awesome terminal setup that will make your command-line experience both powerful and beautiful! This configuration pack transforms your macOS terminal into a productivity powerhouse with intelligent autocomplete, beautiful themes, and time-saving shortcuts.

## 📸 Screenshots

![Terminal Setup](https://github.com/user-attachments/assets/5ebc5034-714c-447c-9459-eb3c0c160c62)
*🔍 Fuzzy tab completion in action - never type full paths again!*

![Neovim Setup](https://github.com/user-attachments/assets/cabed93b-fe19-4ba5-a372-0a5fbe3eba79)
*📝 Neovim with file explorer - coding in style*

## ✨ What You'll Get

### 🖥️ A Beautiful Terminal (WezTerm)
- **GPU-Accelerated**: Buttery smooth scrolling and rendering
- **Semi-Transparent Windows**: 90% opacity for that modern glass look
- **Split Panes**: Work on multiple things side-by-side
- **Smart Tab Titles**: Icons that show what's running (🐍 Python, 🐳 Docker, etc.)
- **Blinking Cursor**: Customizable yellow-green cursor that's easy to spot
- **Theme Options**: Switch between warm Melange 🍯 or cool Catppuccin 🌙 themes

### 🧠 Intelligent Shell (Zsh + Powerlevel10k)
- **Smart Prompt**: Shows current directory, git status, command execution time
- **Timestamps**: See exactly when each command was run (gray timestamps on the right)
- **Auto-suggestions**: Start typing and see command suggestions from your history
- **Syntax Highlighting**: Commands turn green when valid, red when they have errors
- **Lightning Fast**: Optimized for speed with lazy loading

### 🔍 Fuzzy Finding Everything (fzf)
- **Tab Completion on Steroids**: Type partial names and hit Tab to see matches
- **History Search**: Ctrl+R to search through command history with live preview
- **File Navigation**: Quickly jump to any file or directory
- **Works Everywhere**: In cd commands, vim, git, and more!

### 📝 Modern Text Editor (Neovim)
- **File Tree**: Navigate projects easily with Neo-tree
- **Fuzzy File Search**: Find any file in your project instantly with Telescope
- **Syntax Highlighting**: Beautiful code highlighting with Tree-sitter
- **Plugin Manager**: Lazy.nvim for fast startup and easy plugin management
- **Matching Themes**: Same beautiful Melange/Catppuccin themes as your terminal

### 🛠️ Productivity Boosters
- **Better ls**: `lsd` command with icons and colors
- **Faster grep**: `ripgrep` for blazing fast file searches
- **SSH Launcher**: Professional SSH server manager with folder organization and secure password storage (Ctrl+Shift+S)
- **SSH Integration**: Ctrl+Shift+C opens Cyberduck for easy file transfers
- **Git Awareness**: See branch and status right in your prompt
- **Command Aliases**: Short versions of common commands

### 🌐 SSH Launcher (Professional Server Manager)
The SSH Launcher provides XShell/MobaXterm-like functionality directly in WezTerm:

#### ✨ Features
- **📁 Folder Organization**: Organize servers into custom folders for better management
- **🔐 Secure Password Storage**: Passwords stored in macOS Keychain for maximum security
- **⚡ Quick Access**: Press `Ctrl+Shift+S` to instantly open the server selection menu
- **📋 Server Management**: Add, edit, and delete servers with ease
- **🎯 Smart Defaults**: Port 22 is assumed for standard SSH connections
- **🌐 Tab Titles**: SSH tabs display the hostname for easy identification
- **⌨️ Navigation**: Use Esc key to navigate between menus intuitively
- **🔍 Folder Filtering**: Click folders to view only servers in that folder
- **🎯 Fuzzy Search**: Search across all servers and folder names instantly

#### 📖 Usage Guide

##### Adding a Server with Password
1. Press `Ctrl+Shift+S` to open the launcher
2. Select "➕ Add New Server"
3. Enter server details in format: `ServerName,Host,User,Password`
   - Example: `MyLab,192.168.1.10,admin,mypassword`
   - Port 22 is used by default (no need to specify)
4. Server is added and launcher closes automatically

##### Connecting to Servers
1. Press `Ctrl+Shift+S` to open the launcher
2. Select any server from the list
3. A new SSH tab opens with hostname as the tab title
4. Password authentication happens automatically via sshpass

##### Managing Servers
- **Edit**: Select "✏️ Edit Server" to modify existing servers
- **Delete**: Select "🗑️ Delete Server" to remove servers
- **Security Icons**: 🔐 indicates password stored, 🔑 indicates SSH key

##### 📁 Folder Management
The SSH Launcher supports organizing servers into folders for better management:

**Creating Folders:**
1. Press `Ctrl+Shift+S` to open the launcher
2. Select "📁 Create New Folder"
3. Enter folder name (e.g., "Production", "Development", "Lab Servers")

**Adding Servers to Folders:**
- When adding a new server, you'll be prompted to select a folder first
- Servers can be placed in any folder or the Root folder

**Organizing Existing Servers:**
1. Select "✏️ Edit Server" from the main menu
2. Choose the server to edit
3. Select "📁 Change Folder" 
4. Pick the destination folder

**Folder Operations:**
- **📝 Rename Folder**: Change folder names while preserving server assignments
- **🗑️ Delete Empty Folder**: Remove folders that contain no servers
- **🔍 Folder Filtering**: Click any folder header to view only its servers

**Navigation:**
- **Esc Key**: Navigate back to previous menu (only exits to terminal from main menu)
- **Fuzzy Search**: Type to search across all servers and folder names
- **Visual Hierarchy**: Folders show server count and indented server lists

### 💾 Backup & Migration (Global Commands)
The SSH configuration can be backed up and restored using standalone command-line tools with full folder compatibility:

**Export Configuration:**
```bash
# Run from anywhere in your terminal
wezterm_ssh_export.sh

# Interactive process:
# 1. Detects folder-enabled vs legacy systems automatically
# 2. Choose export format: Full (v2.0 with folders) or Legacy (v1.0 compatible)
# 3. Finds your servers and extracts passwords from Keychain  
# 4. Enter encryption password (min 8 chars) and confirm
# 5. Creates encrypted file: ~/Downloads/ssh_launcher_export_TIMESTAMP.enc
```

**Import Configuration:**
```bash
# Run from anywhere in your terminal
wezterm_ssh_import.sh

# Or specify file directly:
wezterm_ssh_import.sh ~/Downloads/ssh_launcher_export_20240111_120000.enc

# Interactive process:
# 1. Enter decryption password
# 2. Automatic compatibility detection and migration
# 3. Choose import mode: Replace all (recommended) or Merge
# 4. Servers, passwords, and folders automatically restored with migration
```

**Migration Compatibility:**
The export/import tools handle all folder system migrations automatically:

- **📁 v2.0 → v2.0**: Full compatibility with folders preserved
- **📁 v2.0 → v1.0**: Folders stripped, servers imported without organization
- **📁 v1.0 → v2.0**: Servers assigned to Root folder, ready for organization
- **📁 v1.0 → v1.0**: Direct compatibility, no changes needed

**Why Separate Commands?**
- **🚀 More Reliable**: No complex callback nesting in WezTerm Lua
- **🔧 Better Debugging**: Clear error messages and detailed progress feedback  
- **📱 Universal**: Works from any terminal, anywhere in your system
- **🎯 Clean Separation**: SSH Launcher focuses on connection, scripts handle backup
- **⚡ Simple Usage**: Just type the command when you need backup/restore
- **🔄 Smart Migration**: Automatic compatibility between folder and legacy systems
- **🛡️ Independent**: Backup/restore works even if WezTerm config changes

**Security Features:**
- **AES-256-CBC Encryption**: Military-grade encryption for exported data
- **PBKDF2 Key Derivation**: 10,000 iterations for password strengthening
- **Secure Cleanup**: Temporary files are overwritten before deletion
- **Version Compatibility**: Export format versioning for future compatibility

##### Server Format
```
ServerName,Host,User,Password[,Port]
```
- **ServerName**: Display name for the server
- **Host**: IP address or hostname
- **User**: SSH username
- **Password**: Password (stored securely in Keychain)
- **Port**: Optional, defaults to 22

### 📊 **Modern System Monitoring (Rust-Powered)**
- **Bottom (btm)**: Beautiful htop replacement with customizable widgets and real-time graphs
- **Procs**: Colorful ps alternative with TCP/UDP ports, Docker info, and smart search
- **Dust**: Visual disk usage analyzer with tree view and size bars
- **Bandwhich**: Real-time network bandwidth usage by process (requires sudo)

## 🎯 Quick Install (Recommended)

Just three commands and you're done! The installer handles everything:

```bash
# 1. Clone this repository
git clone https://github.com/chosey85/shell_custom.git ~/workspace/shell_custom

# 2. Run the installer
cd ~/workspace/shell_custom && ./install.sh

# 3. Restart your terminal
# That's it! 🎉
```

The installer will:
- ✅ Install all required tools (Homebrew, Zsh, WezTerm, etc.)
- ✅ Set up the beautiful JetBrains Mono font
- ✅ Configure everything automatically
- ✅ Back up your existing configs (just in case)
- ✅ Give you clear next steps

## 🎮 Essential Keyboard Shortcuts

### Terminal Navigation (WezTerm)
| Shortcut | Action | Emoji Guide |
|----------|--------|-------------|
| `Ctrl+Shift+T` | New tab | 📑 |
| `Ctrl+Shift+W` | Close tab | ❌ |
| `Ctrl+Shift+H` | Split horizontally | ↔️ |
| `Ctrl+Shift+V` | Split vertically | ↕️ |
| `Ctrl+Shift+C` | Open file manager for current SSH | 📁 |
| `Ctrl+Shift+S` | Open SSH server launcher | 🌐 |

### Shell Magic (Zsh)
| Shortcut | Action | Emoji Guide |
|----------|--------|-------------|
| `Tab` | Fuzzy autocomplete anything | 🎯 |
| `Ctrl+R` | Search command history | 🔍 |
| `Ctrl+P` | Previous command | ⬆️ |
| `Ctrl+N` | Next command | ⬇️ |

### Quick Commands
| Command | What it does | Real Example |
|---------|--------------|--------------|
| `cd **<Tab>` | Jump to any subdirectory | `cd **src<Tab>` → shows all 'src' folders |
| `ls` | Pretty list with icons | `ls` → 📁 Documents 📄 file.txt |
| `vi` | Opens Neovim | `vi config.json` → powerful editing |
| `btm` | Modern system monitor | Shows CPU, memory, processes with graphs |
| `procs` | Better process list | Colorful ps with ports and Docker info |
| `dust` | Visual disk usage | `dust ~/Downloads` → see what's taking space |
| `sudo bandwhich` | Network monitor | See which apps use your bandwidth |
| `wezterm_ssh_export.sh` | Export SSH config | Backup servers + passwords to encrypted file |
| `wezterm_ssh_import.sh` | Import SSH config | Restore servers from encrypted backup |

## 🎨 Customization Tips

### 🌈 Change Your Theme
Want to switch from warm to cool colors? Edit `~/.config/wezterm/wezterm.lua`:
```lua
local current_theme = "melange"  -- Change to "catppuccin" for blue theme
```

### 👻 Adjust Transparency
Make your terminal more or less see-through:
```lua
config.window_background_opacity = 0.9  -- Try 0.7 for more transparent
```

### ⚡ Customize Your Prompt
Run this command to interactively design your prompt:
```bash
p10k configure
```

## 🔧 Troubleshooting

### "My icons look weird!" 😵
The JetBrains Mono Nerd Font needs to be selected in WezTerm. The installer should handle this, but if not, it's in WezTerm settings.

### "Commands not found!" 🤔
Restart your terminal or run:
```bash
source ~/.zshrc
```

### "Neovim plugins not working!" 🐛
Open Neovim and run:
```vim
:checkhealth
```

## 🤝 What's Included

This setup brings together these amazing tools:
- 🖥️ [WezTerm](https://wezfurlong.org/wezterm/) - The terminal emulator
- 🐚 [Zsh](https://www.zsh.org/) + [Zinit](https://github.com/zdharma-continuum/zinit) - The shell and plugin manager
- 👑 [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - The beautiful prompt
- 🔍 [fzf](https://github.com/junegunn/fzf) - Fuzzy finder for everything
- 📝 [Neovim](https://neovim.io/) - The text editor
- 🚄 [ripgrep](https://github.com/BurntSushi/ripgrep) - Ultra-fast file search
- 📊 [lsd](https://github.com/lsd-rs/lsd) - Better ls with icons
- 🦆 [Cyberduck](https://cyberduck.io/) - File transfer tool
- 🔐 [sshpass](https://github.com/kevinburke/sshpass) - SSH password authentication for launcher
- ⚡ [Bottom](https://github.com/ClementTsang/bottom) - Modern system monitor
- 🔄 [Procs](https://github.com/dalance/procs) - Modern ps replacement
- 💾 [Dust](https://github.com/bootandy/dust) - Visual disk usage analyzer
- 🌐 [Bandwhich](https://github.com/imsnif/bandwhich) - Network bandwidth monitor

## 💡 Pro Tips

1. **Use Tab Everywhere**: Seriously, hit Tab after typing a few letters of anything
2. **Split Panes**: Use splits to compare files or run commands while editing
3. **Time Travel**: Your command timestamps help debug "when did I run that?"
4. **SSH Power**: The Cyberduck integration and SSH launcher are game-changers for remote work
5. **Secure Passwords**: SSH passwords are stored in macOS Keychain - never worry about security
6. **Quick SSH**: `Ctrl+Shift+S` becomes muscle memory for instant server access

## 📜 License

This configuration collection is provided as-is. All tools retain their original licenses.

---

🎉 **Enjoy your new supercharged terminal!** Feel free to star ⭐ this repo if you found it helpful!