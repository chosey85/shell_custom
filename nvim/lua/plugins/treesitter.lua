-- TreeSitter Specific
local config = require("nvim-treesitter.configs")
config.setup({
  ensure_installed = { "python", "bash", "terraform", "yaml", "ruby", "groovy", "lua", "toml", "make", "cmake", "c" },
  highlight = { enable = true },
  indent = { enable = true},
})

