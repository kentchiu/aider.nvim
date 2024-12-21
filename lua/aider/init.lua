---@class AiderInit
local M = {}

---Start aider terminal
---@param args table|nil Optional arguments for aider
---@return nil
function M.start(args)
  require("aider.aider").start(args)
end

---Send text to aider
---@param text string Text to send to aider
---@return nil
function M.send(text)
  require("aider.aider").send(text)
end

return M
