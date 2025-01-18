---@class AiderInit
local M = {}

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

local util = require("aider.util")
util.log("aider/init.lua")
require("aider.file_watcher")
return M
