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
- **SSH Integration**: Ctrl+Shift+C opens Cyberduck for easy file transfers
- **Git Awareness**: See branch and status right in your prompt
- **Command Aliases**: Short versions of common commands

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

## 💡 Pro Tips

1. **Use Tab Everywhere**: Seriously, hit Tab after typing a few letters of anything
2. **Split Panes**: Use splits to compare files or run commands while editing
3. **Time Travel**: Your command timestamps help debug "when did I run that?"
4. **SSH Power**: The Cyberduck integration is a game-changer for remote work

## 📜 License

This configuration collection is provided as-is. All tools retain their original licenses.

---

🎉 **Enjoy your new supercharged terminal!** Feel free to star ⭐ this repo if you found it helpful!