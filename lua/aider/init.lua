---@class AiderInit
local M = {}

function M.setup(opts)
  -- require("aider.config").setup(opts)
  -- local util = require("aider.util")
  -- util.log("aider start")
  -- require("aider.file_watcher")
end

function M.get_config()
  local config = require("aider.config")
  return config.options
end

function M.toggle()
  require("aider.terminal").toggle()
end

function M.send(ask)
  require("aider.actions").send(ask)
end

function M.fix()
  require("aider.actions").fix()
end

function M.dialog()
  require("aider.actions").dialog()
end

function M.add_file()
  require("aider.actions").add_file()
end

function M.drop_file()
  require("aider.actions").drop_file()
end

function M.drop_files()
  require("aider.actions").drop_files()
end

function M.yes()
  require("aider.terminal").send("Yes", true)
end

function M.no()
  require("aider.terminal").send("No", true)
end

_G.dd = function(...)
  Snacks.debug.inspect(...)
end

_G.bt = function()
  Snacks.debug.backtrace()
end

_G.log = function(...)
  Snacks.debug.log(...)
end

vim.print = _G.dd

return M
