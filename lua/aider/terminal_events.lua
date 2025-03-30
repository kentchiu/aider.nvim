local M = {}

local EventEmitter = require("aider.events")
local State = require("aider.state")
local config = require("aider.config")
local patterns = require("aider.patterns")
local util = require("aider.util")

local function clean_terminal_line(str)
  -- 移除 ANSI 控制序列
  str = str:gsub("\27%[%d+m", "")
  str = str:gsub("\27%[m", "")
  -- 移除控制字元
  str = str:gsub("%c", "")
  -- 移除所有 UTF-8 框線字元 (E2 94 80)
  str = str:gsub("\226\148\128+", "")
  -- 移除首尾空白
  str = str:gsub("^%s*(.-)%s*$", "%1")
  return str
end

-- 創建狀態實例
M.state = State:new()

-- 創建事件發射器實例
M.events = EventEmitter:new()

M.PATTERNS = {
  editable = patterns.EditableHandler:new(),
  readonly = patterns.ReadonlyHandler:new(),
  prompt = patterns.PromptHandler:new(),
  ready = patterns.ReadyHandler:new(),
  feedback = patterns.FeedbackHandler:new(),
}

function M.get_lines_history()
  return M.state.history
end

function M.clear_lines_history()
  M.state.history = {}
end

---處理 buffer lines 變化的回調函數
---@param buf number Buffer ID
---@param changedtick number Changed tick number
---@param first_line number First changed line (0-based)
---@param last_line number Last changed line (0-based)
---@param last_line_in_range number Last line in changed range
---@param byte_count number Number of bytes changed
function M.handle_lines(buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
  -- Early return if buffer is invalid
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Get the changed lines content
  local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

  if #lines == 0 then
    return
  end

  -- Only log detailed args in TRACE mode to avoid string formatting overhead
  if config.get().logger.level == "TRACE" then
    local args_str = string.format(
      "first_line=%d last_line=%d last_line_in_range=%d byte_count=%d",
      first_line,
      last_line,
      last_line_in_range,
      byte_count
    )
    util.log("lines args: " .. args_str, "TRACE")
    util.log("aider lines: " .. vim.inspect(lines), "TRACE")
  end

  -- Process meaningful lines only
  local has_meaningful_content = false
  for index, line in ipairs(lines) do
    -- Only process non-empty lines
    if line:match("%S") then
      has_meaningful_content = true

      -- Clean and parse the line
      local clean_line = clean_terminal_line(line)

      -- Skip empty lines after cleaning
      if clean_line:match("%S") then
        -- Debug logging only when needed
        if config.get().logger.level == "TRACE" then
          local hex = line:gsub(".", function(c)
            return string.format("%02X ", string.byte(c))
          end)
          util.log(string.format("%d -- Raw hex: %s", index, hex), "TRACE")
          util.log(string.format("Cleaned line: %s", clean_line), "TRACE")
        end

        util.log(clean_line, "DEBUG")
        -- Parse the cleaned line
        M.parse(clean_line)
      end
    end
  end

  -- Only update history if we have meaningful content
  if has_meaningful_content then
    -- Add to history
    table.insert(M.state.history, lines)

    -- More efficient history size management
    if #M.state.history > M.state.max_history then
      -- Remove oldest entries in one operation
      local excess = #M.state.history - M.state.max_history
      if excess > 0 then
        table.move(M.state.history, excess + 1, #M.state.history, 1)
        for i = #M.state.history - excess + 1, #M.state.history do
          M.state.history[i] = nil
        end
      end
    end

    -- Emit event only once per batch of lines
    M.events:emit("lines_changed", lines)
  end
end

function M.parse(line)
  if line == "" then
    return
  end

  -- reset ready state if any changed
  M.state.ready = false
  M.state.wait_for_feedback = nil

  -- 按優先級排序處理器
  local handlers = {}
  for _, handler in pairs(M.PATTERNS) do
    table.insert(handlers, handler)
  end
  table.sort(handlers, function(a, b)
    return a.priority < b.priority
  end)

  -- 依次嘗試每個處理器
  for _, handler in ipairs(handlers) do
    if handler.enabled then
      local matches = { line:match(handler.pattern) }
      if #matches > 0 and handler:validate(matches) then
        handler:handle(matches, M.state)
        -- 發出模式匹配事件
        M.events:emit("pattern_matched", handler.name, matches)
        break -- 假設每行只匹配一個pattern
      end
    end
  end
end

function M.to_string()
  vim.notify(vim.inspect(M.state))
end

function M.reset_state()
  M.state:reset()
  M.events:clear()

  -- Enable patterns
  for _, pattern in pairs(M.PATTERNS) do
    pattern.enabled = true
  end
end

return M
