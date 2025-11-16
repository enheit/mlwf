-- Word finder with custom UI

local ui = require('mlwf.ui')
local search = require('mlwf.search')

local M = {}

-- Plugin configuration (will be set from init.lua)
M.config = {}

-- Debounce timer for search
local search_timer = nil

-- Update results based on current query
local function update_results()
  if not ui.is_open() then
    return
  end

  local query = ui.get_query()

  -- Cancel previous search timer
  if search_timer then
    search_timer:stop()
    search_timer:close()
    search_timer = nil
  end

  -- Debounce search (wait 200ms after user stops typing)
  search_timer = vim.loop.new_timer()
  search_timer:start(200, 0, vim.schedule_wrap(function()
    local ok, err = pcall(function()
      vim.notify('Query: "' .. (query or '') .. '"', vim.log.levels.INFO)
      if query and query ~= '' then
        local results = search.search(query, {
          cwd = vim.fn.getcwd(),
          exclude_patterns = M.config.exclude_patterns or {},
        })

        vim.notify('Rendering ' .. #results .. ' results', vim.log.levels.INFO)
        -- Render results
        ui.render_results(results, query)
      else
        -- Clear results if query is empty
        vim.notify('Query empty, clearing results', vim.log.levels.INFO)
        ui.render_results({}, '')
      end
    end)

    if not ok then
      vim.notify('ERROR in timer callback: ' .. tostring(err), vim.log.levels.ERROR)
    end

    -- Clean up timer
    if search_timer then
      search_timer:stop()
      search_timer:close()
      search_timer = nil
    end
  end))
end

-- Handle file selection
local function select_match()
  local selected = ui.get_selected()
  if not selected then
    ui.close()
    return
  end

  -- Close UI first
  ui.close()

  -- Open the file at the specific line
  local cmd = string.format('edit +%d %s', selected.line, vim.fn.fnameescape(selected.filename))
  vim.cmd(cmd)

  -- Move cursor to the column where the match is
  if selected.column then
    vim.api.nvim_win_set_cursor(0, { selected.line, selected.column - 1 })
  end
end

-- Setup keymaps for the picker
local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Close picker
  vim.keymap.set('n', 'q', function() ui.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() ui.close() end, opts)
  vim.keymap.set('i', '<Esc>', function()
    ui.close()
    vim.cmd('stopinsert')
  end, opts)

  -- Select match
  vim.keymap.set('i', '<CR>', function()
    vim.cmd('stopinsert')
    select_match()
  end, opts)
  vim.keymap.set('n', '<CR>', select_match, opts)

  -- Navigation
  vim.keymap.set('i', '<C-n>', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('i', '<C-p>', function()
    ui.select_prev()
  end, opts)
  vim.keymap.set('i', '<Down>', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('i', '<Up>', function()
    ui.select_prev()
  end, opts)
  vim.keymap.set('n', 'j', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('n', 'k', function()
    ui.select_prev()
  end, opts)
end

-- Setup autocmds for real-time updates
local function setup_autocmds(buf)
  local augroup = vim.api.nvim_create_augroup('MLWFPicker', { clear = true })

  -- Update results on text change and prevent multi-line
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    group = augroup,
    buffer = buf,
    callback = function()
      vim.notify('TextChanged autocmd fired', vim.log.levels.INFO)

      -- Prevent multiple lines
      local line_count = vim.api.nvim_buf_line_count(buf)
      if line_count > 1 then
        local prompt_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt_line })
      end

      -- Only update if we're on the first line (prompt line)
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.notify('Cursor at line: ' .. cursor[1], vim.log.levels.INFO)
      if cursor[1] == 1 then
        vim.notify('Calling update_results()', vim.log.levels.INFO)
        update_results()
      end
    end,
  })

  -- Keep cursor on first line in normal mode
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = augroup,
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] ~= 1 then
        vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
      end
    end,
  })

  -- Keep cursor on first line in insert mode
  vim.api.nvim_create_autocmd('CursorMovedI', {
    group = augroup,
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] ~= 1 then
        vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
      end
    end,
  })

  -- Clean up on buffer close
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    buffer = buf,
    callback = function()
      ui.close()
      -- Clean up timer if exists
      if search_timer then
        search_timer:stop()
        search_timer:close()
        search_timer = nil
      end
    end,
  })
end

-- Open word finder
function M.open()
  -- Check if ripgrep is available
  if not search.rg_available then
    vim.notify('ripgrep (rg) is not installed. Please install ripgrep first.', vim.log.levels.ERROR)
    return
  end

  -- Open UI
  local height = M.config.window_height or 15
  local buf, win = ui.open(height)

  if not buf or not win then
    vim.notify('Failed to open picker', vim.log.levels.ERROR)
    return
  end

  -- Setup keymaps and autocmds
  setup_keymaps(buf)
  setup_autocmds(buf)

  -- Initial render with empty results
  ui.render_results({}, '')

  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Enter insert mode at end of prompt
  vim.cmd('startinsert!')
end

return M
