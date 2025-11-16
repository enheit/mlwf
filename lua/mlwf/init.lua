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
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_extend('force', M.config, opts)

  -- Update finder config
  finder.config = M.config
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
