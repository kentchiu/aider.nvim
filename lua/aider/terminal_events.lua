local M = {}

local util = require("aider.util")

---@class AiderState
---@field history string[][] 儲存buffer變化的歷史記錄
---@field max_history number 最大歷史記錄數量
---@field current_chat_mode string|nil 當前的聊天模式
---@field mode_change_callbacks function[] 模式變化的回調函數表
---@field editable_files string[] 可編輯文件路徑列表
---@field readonly_files string[] 唯讀文件路徑列表
local state = {
  history = {},
  max_history = 1000,
  current_chat_mode = nil,
  mode_change_callbacks = {},
  editable_files = {},
  readonly_files = {},
}

function M.get_lines_history()
  return state.history
end

function M.clear_lines_history()
  state.history = {}
end

function M.on_mode_change(callback)
  table.insert(state.mode_change_callbacks, callback)
end

function M.get_current_mode()
  return state.current_chat_mode
end

function M.get_editable_files()
  return state.editable_files
end

function M.get_readonly_files()
  return state.readonly_files
end

function M.check_chat_mode(line)
  local new_mode
  if line:match("^>%s*$") then
    new_mode = "code"
  elseif line:match("^ask>%s*$") then
    new_mode = "ask"
  elseif line:match("^architect>%s*$") then
    new_mode = "architect"
  end

  -- 只在模式確實改變時觸發回調
  if new_mode and new_mode ~= state.current_chat_mode then
    state.current_chat_mode = new_mode
    util.log("Chat mode changed to: " .. new_mode, vim.log.levels.INFO)
    -- 觸發所有註冊的回調
    for _, callback in ipairs(state.mode_change_callbacks) do
      callback(new_mode)
    end
  end
end

function M.check_editable(line)
  local editable_pattern = "^editable>%s*(.-)%s*$"
  local paths = line:match(editable_pattern)
  if paths then
    -- 清空之前的列表
    state.editable_files = {}
    -- 分割路徑字符串並存儲
    for path in paths:gmatch("[^%s,]+") do
      table.insert(state.editable_files, path)
    end
    util.log("Editable files updated: " .. vim.inspect(state.editable_files), vim.log.levels.INFO)
    return true
  end
  return false
end

function M.check_readonly(line)
  -- 修改模式以匹配 "Readonly:" 格式
  local readonly_pattern = "^Readonly:?%s*(.-)%s*$"
  local paths = line:match(readonly_pattern)
  if paths then
    -- 清空之前的列表
    state.readonly_files = {}
    -- 分割路徑字符串並存儲
    for path in paths:gmatch("[^%s,]+") do
      table.insert(state.readonly_files, path)
    end
    util.log("Readonly files updated: " .. vim.inspect(state.readonly_files), vim.log.levels.INFO)
    return true
  end
  return false
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

  local args_str = string.format(
    "buf=%d changedtick=%d first_line=%d last_line=%d last_line_in_range=%d byte_count=%d",
    buf,
    changedtick,
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

    local function remove_control_sequences(str)
      -- 移除 ANSI 控制序列
      str = str:gsub("\27%[%d+m", "")
      str = str:gsub("\27%[m", "")
      -- 移除控制字元
      str = str:gsub("%c", "")
      --移除所有 UTF-8 框線字元 (E2 94 80)
      str = str:gsub("\226\148\128+", "")
      -- 移除重複的空格
      -- str = str:gsub("%s+", " ")
      -- 移除首尾空白
      str = str:gsub("^%s*(.-)%s*$", "%1")
      return str
    end

    for index, line in ipairs(lines) do
      -- 移除控制序列
      local clean_line = remove_control_sequences(line)
      if clean_line:match("%S") then
        -- 只有當行有內容時才輸出 hex
        local hex = line:gsub(".", function(c)
          return string.format("%02X ", string.byte(c))
        end)
        util.log(string.format("%d -- Raw hex: %s", index, hex), vim.log.levels.TRACE)

        local msg = string.format("%s", clean_line)
        util.log(msg, vim.log.levels.DEBUG)
      end
      M.check_editable(clean_line)
      M.check_readonly(clean_line)
      M.check_chat_mode(clean_line)
    end

    table.insert(state.history, lines)

    -- Maintain history size limit
    while #state.history > state.max_history do
      table.remove(state.history, 1)
    end
  end
end

return M
