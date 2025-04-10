# nvim-lsp-extras

Some extra functionality I use to make neovim LSP a bit better.

## Requirements

- Neovim 0.11

## Installation

### lazy.nvim

```lua
require("lazy").setup({
    { "seblyng/nvim-lsp-extras" },
})
```

## Setup

This plugin provides a setup function with the following default values.
Each module can be set to `false` if you do not wish the functionality

```lua
require("nvim-lsp-extras").setup({
    signature = {
        border = "rounded",
    },
    mouse_hover = {
        border = "rounded",
    },
    lightbulb = {
        icon = "",
        diagnostic_only = true, -- Only lightbulb if line contains diagnostic
    },
})
```
