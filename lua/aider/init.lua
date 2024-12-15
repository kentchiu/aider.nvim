local M = {}

function M.start(args)
  require("aider.aider").start(args)
end

function M.send(text)
  require("aider.aider").send(text)
end

return M
