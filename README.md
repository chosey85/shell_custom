# Introduction

Welcome to my personal shell and development environment configuration repository. This collection of dotfiles and configurations is designed to create a powerful, efficient, and visually appealing command-line experience.

## Disclaimer

This repository is a personal collection of configurations and tools that I use to enhance my development environment. It is important to note:

1. **Third-Party Software**: The software and tools configured in this repository (including but not limited to Zsh, Neovim, Wezterm, fzf, and powerlevel10k) are not my creations. They are developed and maintained by their respective owners and communities. I highly respect their work and encourage users to visit the original projects for more information:

   - [Zsh](https://www.zsh.org/)
   - [Neovim](https://neovim.io/)
   - [Wezterm](https://wezfurlong.org/wezterm/)
   - [fzf](https://github.com/junegunn/fzf)
   - [powerlevel10k](https://github.com/romkatv/powerlevel10k)

2. **Personal Use**: The configurations and customizations in this repository are tailored to my personal preferences and workflow. While I'm happy to share them, they may not suit everyone's needs or preferences.

3. **No Warranty**: This repository is provided "as is", without warranty of any kind. Use of these configurations is at your own risk.

4. **Respect Licenses**: When using or adapting any part of this repository, please respect the licenses of the individual software components and any third-party code included.

The purpose of this repository is to consolidate and version control my personal development environment setup, making it easier for me to maintain and deploy across different machines. If others find it useful as a reference or starting point for their own configurations, that's a welcome bonus!

## What's Inside

This repository contains customizations for:

- **Zsh**: Enhanced shell with Zinit plugin manager, powerlevel10k theme, and fzf integration
- **Powerlevel10k**: A highly customizable Zsh theme
- **Wezterm**: A GPU-accelerated cross-platform terminal emulator and multiplexer
- **Neovim**: A highly extensible Vim-based text editor

Each tool is configured with Lua where applicable, providing a modern and flexible setup.

## Key Features

- Zsh configuration with auto-completion, suggestions, custom aliases, and history modifications
- Powerlevel10k for a sleek and informative prompt
- Wezterm setup for an efficient terminal experience
- Neovim configuration with lazy.nvim for plugin management, including:
  - Telescope for fuzzy finding
  - Treesitter for improved syntax highlighting
  - Neo-tree for file exploration
  - Custom color schemes (Catppuccin and Melange)

# Installation

## Prerequisites

### Install Nerd Fonts
Nerd Fonts are required for proper rendering of powerline symbols and icons in the terminal. Here's how to install them:

1. Download a Nerd Font of your choice from the [Nerd Fonts website](https://www.nerdfonts.com/font-downloads). 
   Recommended fonts: JetBrainsMono Nerd Font, Meslo Nerd Font, or FiraCode Nerd Font.

2. Install the font:

   - **For macOS:**
     - Double-click the downloaded font files and click "Install Font"
     - Or, copy the font files to `~/Library/Fonts/`

   - **For Ubuntu/Debian:**
     ```bash
     mkdir -p ~/.local/share/fonts
     mv /path/to/downloaded/nerd/font.ttf ~/.local/share/fonts/
     fc-cache -fv
     ```

   - **For RHEL/CentOS:**
     ```bash
     sudo mv /path/to/downloaded/nerd/font.ttf /usr/share/fonts/
     sudo fc-cache -fv
     ```

3. Configure your terminal to use the installed Nerd Font:
   - For most terminals, go to Preferences/Settings and change the font to your installed Nerd Font
   - For iTerm2 on macOS, go to Preferences > Profiles > Text and change the font

## .zshrc
To use this file, just make sure the following:
1. Verify your default shell is zsh ($SHELL)
2. Create a backup of your current .zshrc in ~/
3. Copy the .zshrc to ~/

fzf tab example:
<img width="1499" alt="image" src="https://github.com/user-attachments/assets/5ebc5034-714c-447c-9459-eb3c0c160c62">

## Powerlevel10k
To use my Powerlevel10K configuration, just backup the .p10k.zsh file in ~/ and replace it with this file

## Wezterm
To use my Wezterm.lua config: 
1. Make sure to install wezterm - https://wezfurlong.org/wezterm/installation.html
2. Put wezterm.lua in ~/.config/wezterm/

## NeoVim
For using the lua configuration file, you must have at least Neovim v0.8.0 installed.
1. For Ubuntu Linux, make sure to install the latest version:
``` bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```
For RHEL bases operating systems, use the following:
```
sudo dnf install epel-release
sudo dnf install ninja-build libtool autoconf automake cmake gcc gcc-c++ make pkgconfig unzip patch gettext curl
git clone https://github.com/neovim/neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
nvim --version
```

2. Place all the the content of nvim directory under ~/.config/nvim/
3. When running nvim, you may be required to update Lazy by running:

```
:Lazy update
:Lazy sync
```
4. Once this is done, exit and enter nvim again to make sure there are no errors

Neovim example with Neotree:
<img width="1482" alt="image" src="https://github.com/user-attachments/assets/cabed93b-fe19-4ba5-a372-0a5fbe3eba79">

