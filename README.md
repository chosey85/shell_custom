# Introduction
The following repo is a bunch of shell customizations provided by Chosey85.
The current related applications are Wezterm and Powerlevel10K (invoked from .zshrc).
In addition the .zshrc that I'm using is also provided, including Zinit plugins, aliases and some extenstions.

# Installation
## .zshrc
To use this file, just make sure the following:
1. Verify your default shell is zsh ($SHELL)
2. Create a backup of your current .zshrc in ~/
3. Copy the .zshrc to ~/

## Powerlevel10k
To use my Powerlevel10K configuration, just backup the .p10k.zsh file in ~/ and replace it with this file

## Wezterm
To use my Wezterm.lua config, make sure to install wezterm and put wezterm.lua in ~/.config/wezterm/

## NeoVim
For using the lua configuration file, you must have at least Neovim v0.8.0 installed.
1. For Ubuntu Linux, make sure to install the latest version:
``` bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim
```
For other OSs, make sure to install using the relevant package manager.

2. Place all the the content of nvim directory under ~/.config/nvim/
3. When running nvim, you may be required to update Lazy by running:

```
:Lazy update
:Lazy sync
```
4. Once this is done, exit and enter nvim again to make sure there are no errors
