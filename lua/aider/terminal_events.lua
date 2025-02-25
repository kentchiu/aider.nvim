local M = {}

local util = require("aider.util")

---@param str string The raw terminal line
---@return string cleaned_str The cleaned line
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

---@class AiderState
---@field history string[][] 儲存buffer變化的歷史記錄
---@field max_history number 最大歷史記錄數量
---@field editable_files string[] 可編輯文件路徑列表
---@field readonly_files string[] 唯讀文件路徑列表
---@field ready boolean is adier ready or processing
M.state = {
  history = {},
  max_history = 1000,
  readonly_files = {},
  editable_files = {},
  wait_for_feedbak = nil,
  ready = false,
}

local patterns = require("aider.patterns")

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
  local args = {
    buf = buf,
    changedtick = changedtick,
    first_line = first_line,
    last_line = last_line,
    last_line_in_range = last_line_in_range,
    byte_count = byte_count,
  }

  -- local args_str = string.format(
  --   "buf=%d changedtick=%d first_line=%d last_line=%d last_line_in_range=%d byte_count=%d",
  --   buf,
  --   changedtick,
  --   first_line,
  --   last_line,
  --   last_line_in_range,
  --   byte_count
  -- )
  local args_str = string.format(
    "first_line=%d last_line=%d last_line_in_range=%d byte_count=%d",
    first_line,
    last_line,
    last_line_in_range,
    byte_count
  )

  util.log("lines args: " .. args_str, vim.log.levels.TRACE)
  -- Get the changed lines content
  local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

  -- Add to lines history
  if #lines > 0 then
    util.log("aider lines: " .. vim.inspect(lines), vim.log.levels.TRACE)

    for index, line in ipairs(lines) do
      -- 清理並解析每一行
      local clean_line = clean_terminal_line(line)

      -- 只處理非空行
      if clean_line:match("%S") then
        -- Debug 用的 hex 輸出
        local hex = line:gsub(".", function(c)
          return string.format("%02X ", string.byte(c))
        end)
        util.log(string.format("%d -- Raw hex: %s", index, hex), vim.log.levels.TRACE)
        util.log(string.format("Cleaned line: %s", clean_line), vim.log.levels.TRACE)

        util.log(clean_line, vim.log.levels.DEBUG)
        -- 解析清理後的行
        M.parse(clean_line)
      end
    end

    table.insert(M.state.history, lines)

    -- Maintain history size limit
    while #M.state.history > M.state.max_history do
      table.remove(M.state.history, 1)
    end
  end
end

function M.parse(line)
  if line == "" then
    return
  end

  -- reset ready state if any changed
  M.state.ready = false
  M.state.wait_for_feedbak = nil

  for _, parser in pairs(M.PATTERNS) do
    if parser.enabled then
      local matches = { line:match(parser.pattern) }
      if #matches > 0 then
        parser:handle(matches, M.state)
        break -- 假設每行只匹配一個pattern
      end
    end
  end
end

function M.to_string()
  vim.notify(vim.inspect(M.state), vim.log.levels.INFO)
end

function M.reset_state()
  M.state.history = {}
  M.state.max_history = 1000
  M.state.readonly_files = {}
  M.state.editable_files = {}
  M.state.ready = false

  -- Enable patterns
  M.PATTERNS.readonly.enabled = true
  M.PATTERNS.editable.enabled = true
  M.PATTERNS.prompt.enabled = true
  M.PATTERNS.ready.enabled = true
  M.PATTERNS.feedback.enabled = true
end

return M
