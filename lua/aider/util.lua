---@class AiderUtil
local M = {}
local config = require("aider.config")

-- Convert log level string to vim.log.levels value
local function get_log_level_from_string(level_str)
  local level_map = {
    ["TRACE"] = vim.log.levels.TRACE,
    ["DEBUG"] = vim.log.levels.DEBUG,
    ["INFO"] = vim.log.levels.INFO,
    ["WARN"] = vim.log.levels.WARN,
    ["ERROR"] = vim.log.levels.ERROR,
    ["OFF"] = vim.log.levels.OFF,
  }

  return level_map[level_str] or vim.log.levels.INFO
end

-- Get logger level from config, with fallback to INFO
local cfg = config.get()
local default_level_str = (cfg.logger and cfg.logger.level) or "INFO"

--- Default log level
M.default_level = get_log_level_from_string(default_level_str)

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
---@param level? string Log level: TRACE | DEBUG | INFO | WARN | ERROR | OFF, default INFO
function M.log(message, level)
  -- Convert string level to integer
  level = level or "INFO"
  local level_int = get_log_level_from_string(level)

  if level_int == vim.log.levels.OFF then
    return
  end

  -- Only log if level is >= default_level
  if level_int < M.default_level then
    return
  end

  local level_str = level

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

  return selected_text, start_line, end_line, start_col, end_col
end

--- Wrap content in a code block template
---@param input string The content to wrap
---@param filetype? string The language for the code block (default: nil)
---@param start_line? integer The start line number (default: nil)
---@param end_line? integer The end line number (default: nil)
---@param path? string The file path (default: nil)
---@return string
function M.template_code(input, filetype, start_line, end_line, path)
  if #input == 0 then
    return ""
  end
  local tpl = ""

  if start_line and end_line and path then
    tpl = tpl .. "file:" .. path .. ":" .. start_line .. "-" .. end_line .. "\n"
  end

  if filetype then
    tpl = tpl .. "```" .. filetype .. "\n"
  else
    tpl = tpl .. "```" .. "\n"
  end
  tpl = tpl .. input
  tpl = tpl .. "\n```\n"
  return tpl
end

return M
