---@class AiderInit
local M = {}

local actions = require("aider.actions")
local config = require("aider.config")
local terminal = require("aider.terminal")
local util = require("aider.util")

function M.setup(opts)
  config.setup(opts)
  util.log("aider start")
  require("aider.file_watcher")
end

function M.get_config()
  return config.options
end

function M.toggle()
  terminal.toggle()
end

function M.send(ask)
  actions.send(ask)
end

function M.fix()
  actions.fix()
end

function M.dialog()
  actions.dialog()
end

function M.add_file()
  actions.add_file()
end

function M.add_files()
  actions.add_files()
end

function M.drop_file()
  actions.drop_file()
end

function M.yes()
  terminal.send("Yes", true)
end

function M.no()
  terminal.send("No", true)
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
