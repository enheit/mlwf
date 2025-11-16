# MLWF - My Lovely Word Finder

A fast, live text search plugin for Neovim with smart filtering and beautiful highlighting. Search for words, environment variables, function names, or any text across your entire project.

## Features

- **Live search** - Results update as you type
- **Fast search** powered by ripgrep
- **Smart filtering**: Excludes `node_modules`, build directories, minified files
- **Beautiful UI**: Clean bottom-split interface that matches your theme
- **Match highlighting**: Matched text highlighted with bright colors
- **Jump to location**: Press Enter to jump to exact file and line
- **Syntax highlighting**: File paths, line numbers, and content all colored

## Use Cases

- Find where environment variables are used: `NEXT_PUBLIC_API_URL`
- Search for function calls: `calculateTotal`
- Find TODO comments: `TODO:`
- Locate configuration values: `API_KEY`
- Track down variable usage across files

## Dependencies

**Required:**
- `ripgrep` (rg) - Ultra-fast text search tool

### Installing ripgrep

```bash
# Ubuntu/Debian
sudo apt install ripgrep

# Arch Linux
sudo pacman -S ripgrep

# macOS
brew install ripgrep
```

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'enheit/mlwf',
  config = function()
    require('mlwf').setup({
      -- Optional: customize configuration
      exclude_patterns = {
        'node_modules',
        '.git',
        'dist',
        'build',
      },
      window_height = 15,
    })

    -- Set keybinding
    vim.keymap.set('n', '<leader>fw', ':MLWFFind<CR>', { desc = 'Find Word' })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'enheit/mlwf',
  config = function()
    require('mlwf').setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'enheit/mlwf'

" In your init.vim or after plug#end()
lua require('mlwf').setup()
```

## Usage

### Default keybinding

Press `<leader>fw` (usually `space` + `f` + `w`) to open the word finder.

### Commands

```vim
:MLWFFind    " Open word finder
```

### In the search window

- **Type** to search for text across all files
- **Enter** - Jump to selected match (opens file at exact line)
- **Ctrl-n** / **Down** - Next result
- **Ctrl-p** / **Up** - Previous result
- **Esc** - Close without selecting
- **j/k** (normal mode) - Navigate results

## Configuration

### Default configuration

```lua
require('mlwf').setup({
  -- Directories/patterns to exclude from search
  exclude_patterns = {
    'node_modules',
    '.git',
    'dist',
    'build',
    'target',
    '.next',
    'coverage',
    '*.min.js',
    '*.min.css',
  },

  -- Height of the finder window (in lines)
  window_height = 15,
})

-- Set keybinding
vim.keymap.set('n', '<leader>fw', ':MLWFFind<CR>', { desc = 'Find Word' })
```

### Custom keybinding example

```lua
require('mlwf').setup({
  -- your config here
})

-- Use any keybinding you prefer
vim.keymap.set('n', '<C-f>', ':MLWFFind<CR>', { desc = 'Find word' })
```

### Exclude additional patterns

```lua
require('mlwf').setup({
  exclude_patterns = {
    'node_modules',
    '.git',
    'vendor',        -- Add vendor directory
    '*.pyc',         -- Add Python bytecode
    '__pycache__',   -- Add Python cache
    '*.lock',        -- Add lock files
  },
})
```

## How it works

1. **Text search**: Uses `ripgrep` to search file contents
2. **Smart filtering**: Automatically excludes common build/dependency directories
3. **Live updates**: Results update with ~200ms debounce as you type
4. **Display format**: `path/to/file.ts:42 - const API = NEXT_PUBLIC_MY_ENV`
5. **Match highlighting**: Your search term is highlighted in bright colors
6. **Jump to match**: Opens file and positions cursor at the exact line and column

## Example searches

```
NEXT_PUBLIC        → Find all environment variables
TODO:              → Find all TODO comments
calculateTotal     → Find function usage
API_KEY            → Find configuration values
import React       → Find React imports
```

## Integration with other plugins

MLWF is designed to work alongside:
- [MLFS](https://github.com/enheit/mlfs) - My Lovely File Selector (find files by name)
- [MLTS](https://github.com/enheit/mlts) - My Lovely Theme Selector
- [MLTB](https://github.com/enheit/mltb) - My Lovely Theme Builder

All plugins follow the same naming convention, code style, and theme integration.

## Highlight Groups

You can customize colors by setting these highlight groups:

```lua
vim.api.nvim_set_hl(0, 'MLWFSelection', { link = 'CursorLine' })  -- Selected line
vim.api.nvim_set_hl(0, 'MLWFMatch', { link = 'IncSearch' })       -- Matched text
vim.api.nvim_set_hl(0, 'MLWFPath', { link = 'Directory' })        -- File path
vim.api.nvim_set_hl(0, 'MLWFLineNr', { link = 'LineNr' })         -- Line number
```

## Performance

- **Ripgrep** is extremely fast - can search millions of lines in seconds
- **Debounced search** - Waits 200ms after you stop typing before searching
- **Limited results** - Shows max 100 results for UI performance
- **Smart exclude** - Skips `node_modules` and build directories automatically

## License

MIT

## Credits

- Built with [ripgrep](https://github.com/BurntSushi/ripgrep) for blazing fast search
- Inspired by Telescope, fzf.vim, and grep.vim
- Part of the "My Lovely" plugin family
