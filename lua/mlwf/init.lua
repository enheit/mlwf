-- MLWF - My Lovely Word Finder
-- Main plugin entry point

local finder = require('mlwf.finder')

local M = {}

-- Plugin configuration
M.config = {
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
  -- Keybinding for opening the word finder
  keymap = '<leader>fw',
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_extend('force', M.config, opts)

  -- Update finder config
  finder.config = M.config

  -- Setup keymap if provided
  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, function()
      M.find()
    end, {
      noremap = true,
      silent = true,
      desc = 'Open MLWF word finder',
    })
  end
end

-- Open word finder
function M.find()
  finder.open()
end

-- Create user commands
vim.api.nvim_create_user_command('MLWFFind', function()
  M.find()
end, {
  desc = 'Open MLWF word finder',
})

return M
