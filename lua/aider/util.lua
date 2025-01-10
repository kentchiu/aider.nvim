---@class AiderUtil
local M = {}

--- Default log level
M.default_level = vim.log.levels.INFO

--- Log level mapping
local LEVELS = {
  [vim.log.levels.TRACE] = "TRACE",
  [vim.log.levels.DEBUG] = "DEBUG",
  [vim.log.levels.INFO] = "INFO",
  [vim.log.levels.WARN] = "WARN",
  [vim.log.levels.ERROR] = "ERROR",
  [vim.log.levels.OFF] = "OFF",
}

--- Log a message
---@param message string|table The message to log
---@param level? integer vim.log.levels (default: INFO)
function M.log(message, level)
  level = level or vim.log.levels.INFO

  -- Only log if level is >= default_level
  if level < M.default_level then
    return
  end

  local level_str = LEVELS[level] or "INFO"

  -- Get caller info
  local info = debug.getinfo(2, "Sl")
  local source = info.source:gsub("^@", "")
  local path, filename = string.match(source, "(.-)([^/]+)$")
  local name, ext = string.match(filename, "(.+)%.(.+)$")
  local line = info.currentline

  Snacks.debug.log(string.format("%s:%d %s\t%s", name, line, level_str, message))
end

--- 取得選中範圍的文字
function M.get_visual_selection()
  -- 保存當前的選擇模式
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "" then
    return nil
  end

  -- 獲取當前視窗和緩衝區
  local buf = vim.api.nvim_get_current_buf()

  -- 獲取選擇範圍
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  -- 確保起始位置在結束位置之前
  local start_line = math.min(start_pos[2], end_pos[2])
  local end_line = math.max(start_pos[2], end_pos[2])
  local start_col = math.min(start_pos[3], end_pos[3])
  local end_col = math.max(start_pos[3], end_pos[3])

  -- 獲取選中的行
  local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

  -- 處理選中的文字
  if mode == "V" then
    -- V-LINE 模式：保持整行內容
    -- 不需要做任何修改
  else
    -- 一般 visual 模式：根據列位置截取
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end

  local selected_text = table.concat(lines, "\n")

  return selected_text
end

return M
