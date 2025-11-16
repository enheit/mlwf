-- MLWF plugin initialization
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_mlwf then
  return
end
vim.g.loaded_mlwf = 1

-- Setup default highlight groups
-- These integrate with the current colorscheme
local function setup_highlights()
  -- Only set if not already defined by colorscheme
  vim.api.nvim_set_hl(0, 'MLWFSelection', { link = 'CursorLine' })
  vim.api.nvim_set_hl(0, 'MLWFMatch', { link = 'IncSearch' })
  vim.api.nvim_set_hl(0, 'MLWFPath', { link = 'Directory' })
  vim.api.nvim_set_hl(0, 'MLWFLineNr', { link = 'LineNr' })
end

-- Setup highlights on colorscheme change
setup_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = setup_highlights,
  desc = 'Update MLWF highlight groups on colorscheme change',
})
