local M = {}

local util = require("aider.util")

---@type string[][] 儲存buffer變化的歷史記錄
local history = {}
---@type number 最大歷史記錄數量
local MAX_HISTORY = 1000

---取得lines歷史記錄
---@return string[][] lines變化歷史記錄
function M.get_lines_history()
  return history
end

---清除lines歷史記錄
function M.clear_lines_history()
  history = {}
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

  util.log("aider lines: " .. args_str, vim.log.levels.OFF)

  -- Get the changed lines content
  local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

  -- Add to lines history
  if #lines > 0 then
    util.log("aider lines: " .. vim.inspect(lines), vim.log.levels.DEBUG)
    table.insert(history, lines)

    -- Maintain history size limit
    while #history > MAX_HISTORY do
      table.remove(history, 1)
    end
  end
end

return M
