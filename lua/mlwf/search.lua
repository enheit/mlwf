-- Search backend using ripgrep

local M = {}

-- Check if ripgrep is installed
local function is_rg_available()
  local handle = io.popen('command -v rg 2>/dev/null')
  if not handle then
    return false
  end
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

M.rg_available = is_rg_available()

-- Search for text in files using ripgrep
-- @param query string: search query
-- @param opts table: search options
-- @return table: list of search results
function M.search(query, opts)
  if not M.rg_available then
    vim.notify('ripgrep (rg) is not installed. Please install ripgrep.', vim.log.levels.ERROR)
    return {}
  end

  if not query or query == '' then
    return {}
  end

  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local exclude_patterns = opts.exclude_patterns or {}

  -- Build ripgrep command
  -- --vimgrep: output in format filename:line:column:content
  -- --hidden: search hidden files
  -- --no-heading: don't group by file
  -- --color=never: no color codes
  local cmd = 'rg --vimgrep --hidden --no-heading --color=never --smart-case'

  -- Add exclude patterns
  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. ' --glob "!' .. pattern .. '"'
  end

  -- Add query and directory
  cmd = cmd .. ' ' .. vim.fn.shellescape(query) .. ' ' .. vim.fn.shellescape(cwd)

  -- Execute search
  local handle = io.popen(cmd .. ' 2>/dev/null')
  if not handle then
    return {}
  end

  local results = {}
  for line in handle:lines() do
    -- Parse ripgrep output: filename:line:column:content
    local filename, line_num, col, content = line:match('([^:]+):(%d+):(%d+):(.*)')
    if filename and line_num and content then
      -- Make path relative to cwd
      if filename:sub(1, #cwd) == cwd then
        filename = filename:sub(#cwd + 2)  -- +2 to skip the trailing /
      end

      table.insert(results, {
        filename = filename,
        line = tonumber(line_num),
        column = tonumber(col),
        content = content,
        -- Format for display: path:line - content
        display = string.format('%s:%d - %s', filename, line_num, content:gsub('^%s+', '')), -- trim leading whitespace
      })
    end
  end
  handle:close()

  return results
end

return M
