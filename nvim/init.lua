require('core.options')
require('core.keymaps')
require('core.lazy_bootstrap')

 -- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- add your plugins here
    -- Themes
    {"catppuccin/nvim", name = "catppuccin", priority = 1000},
    {"savq/melange-nvim"},
    -- Telescope Plugin
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.5',
      dependencies = { 'nvim-lua/plenary.nvim' },
      config = function()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.find_files, {})
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      end
    },
    -- TreeSitter Plugin
    {
      "nvim-treesitter/nvim-treesitter", 
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "python", "bash", "terraform", "yaml", "ruby", "groovy", "lua", "toml", "make", "cmake", "c" },
          highlight = { enable = true },
          indent = { enable = true},
        })
      end
    },
    -- Nvim-Neo-Tree Plugin
    {
       "nvim-neo-tree/neo-tree.nvim",
       branch = "v3.x",
       dependencies = {
       "nvim-lua/plenary.nvim",
       "nvim-tree/nvim-web-devicons",
       "MunifTanjim/nui.nvim"
       } 
    }
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "catppuccin" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- Set the color scheme
vim.cmd.colorscheme "melange"

