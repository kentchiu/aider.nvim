---@class AiderUtil
local M = {}

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
  local level_str = LEVELS[level] or "INFO"

  -- Get caller info
  local info = debug.getinfo(2, "Sl")
  local source = info.source:gsub("^@", "")
  local path, filename = string.match(source, "(.-)([^/]+)$")
  local name, ext = string.match(filename, "(.+)%.(.+)$")
  local line = info.currentline

  Snacks.debug.log(string.format("%s:%d %s\t%s", name, line, level_str, message))
end

return M
