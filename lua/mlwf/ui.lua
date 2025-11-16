-- UI management for word finder

local M = {}

-- UI state
local state = {
  buf = nil,
  win = nil,
  prompt = '',
  selected_index = 1,
  results = {},
}

-- Get color from highlight group
local function get_hl_color(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if hl[attr] then
    return string.format('#%06x', hl[attr])
  end
  return nil
end

-- Setup highlight groups based on current theme
local function setup_highlights()
  -- Selected item
  vim.api.nvim_set_hl(0, 'MLWFSelection', {
    link = 'CursorLine',
  })

  -- Matched word - use IncSearch for visibility
  vim.api.nvim_set_hl(0, 'MLWFMatch', {
    fg = get_hl_color('IncSearch', 'fg') or get_hl_color('String', 'fg'),
    bg = get_hl_color('IncSearch', 'bg'),
    bold = true,
  })

  -- Filepath
  vim.api.nvim_set_hl(0, 'MLWFPath', {
    fg = get_hl_color('Directory', 'fg') or get_hl_color('Comment', 'fg'),
  })

  -- Line number
  vim.api.nvim_set_hl(0, 'MLWFLineNr', {
    fg = get_hl_color('LineNr', 'fg'),
  })
end

-- Create and open the picker window
function M.open(height)
  height = height or 15

  -- Setup highlights
  setup_highlights()

  -- Create scratch buffer
  state.buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(state.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(state.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(state.buf, 'filetype', 'mlwf')

  -- Create bottom split
  vim.cmd('botright ' .. height .. 'split')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  -- Set window options
  vim.api.nvim_win_set_option(state.win, 'number', false)
  vim.api.nvim_win_set_option(state.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(state.win, 'cursorline', false)
  vim.api.nvim_win_set_option(state.win, 'wrap', false)
  vim.api.nvim_win_set_option(state.win, 'spell', false)

  -- Initial prompt
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { state.prompt })

  -- Move cursor to end of prompt
  vim.api.nvim_win_set_cursor(state.win, { 1, #state.prompt })

  return state.buf, state.win
end

-- Render results in the buffer
function M.render_results(results, query)
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  state.results = results

  -- Get current prompt line content
  local prompt_line = vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or state.prompt

  -- Limit results to prevent performance issues
  local max_results = 100

  -- Build lines: prompt + results
  local lines = { prompt_line }

  if #results == 0 then
    if query and query ~= '' then
      table.insert(lines, 'No matches found')
    end
  else
    for i = 1, math.min(#results, max_results) do
      table.insert(lines, results[i].display)
    end

    if #results > max_results then
      table.insert(lines, string.format('... and %d more matches', #results - max_results))
    end
  end

  -- Update buffer (disable events to prevent infinite loop)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)

  -- Save cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(state.win)

  -- Use eventignore to prevent TextChanged from firing during update
  local save_eventignore = vim.o.eventignore
  vim.o.eventignore = 'all'

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Restore cursor position (keep on prompt line)
  if cursor_pos[1] == 1 then
    pcall(vim.api.nvim_win_set_cursor, state.win, cursor_pos)
  end

  -- Restore eventignore
  vim.o.eventignore = save_eventignore

  -- Keep buffer modifiable so user can type in prompt line

  -- Force complete redraw (important for display refresh during insert mode)
  vim.cmd('redraw!')
  vim.cmd('redrawstatus!')

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)

  -- Highlight selected item
  if #results > 0 and state.selected_index <= #results then
    local line_idx = state.selected_index  -- No separator, just offset from prompt
    vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLWFSelection', line_idx, 0, -1)
  end

  -- Highlight matched words and syntax in results
  if query and query ~= '' then
    for i, result in ipairs(results) do
      if i > max_results then
        break
      end
      local line_idx = i  -- Line index in buffer

      -- Highlight filepath
      local filepath_end = #result.filename
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLWFPath', line_idx, 0, filepath_end)

      -- Highlight line number
      local line_num_str = ':' .. result.line
      local line_num_start = filepath_end
      local line_num_end = line_num_start + #line_num_str
      vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLWFLineNr', line_idx, line_num_start, line_num_end)

      -- Highlight matched query in content
      local content_start = #result.filename + #line_num_str + 3  -- +3 for " - "
      local content = result.content:gsub('^%s+', '')  -- trimmed content
      local query_lower = query:lower()
      local content_lower = content:lower()

      -- Find all occurrences of query in content
      local pos = 1
      while true do
        local match_start, match_end = content_lower:find(query_lower, pos, true)
        if not match_start then
          break
        end
        vim.api.nvim_buf_add_highlight(
          state.buf,
          -1,
          'MLWFMatch',
          line_idx,
          content_start + match_start - 1,
          content_start + match_end
        )
        pos = match_end + 1
      end
    end
  end
end

-- Get current query from prompt line
function M.get_query()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ''
  end

  local prompt_line = vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or state.prompt
  return prompt_line:sub(#state.prompt + 1)
end

-- Get currently selected result
function M.get_selected()
  if state.selected_index > 0 and state.selected_index <= #state.results then
    return state.results[state.selected_index]
  end
  return nil
end

-- Move selection up
function M.select_prev()
  if #state.results == 0 then
    return
  end

  state.selected_index = state.selected_index - 1
  if state.selected_index < 1 then
    state.selected_index = 1
  end

  -- Re-render to update highlight
  M.render_results(state.results, M.get_query())
end

-- Move selection down
function M.select_next()
  if #state.results == 0 then
    return
  end

  state.selected_index = state.selected_index + 1
  if state.selected_index > #state.results then
    state.selected_index = #state.results
  end

  -- Re-render to update highlight
  M.render_results(state.results, M.get_query())
end

-- Close the picker
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  -- Reset state
  state.buf = nil
  state.win = nil
  state.results = {}
  state.selected_index = 1
end

-- Check if picker is open
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

-- Get current state
function M.get_state()
  return state
end

return M
