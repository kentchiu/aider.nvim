---@class AiderInit
local M = {}

local actions = require("aider.actions")
local tmux = require("aider.tmux")

function M.setup(opts)
  local util = require("aider.util")
  local config = require("aider.config")
  config.setup(opts)

  local current_config = config.get()
  if current_config and current_config.logger and current_config.logger.level ~= "OFF" then
    vim.notify("Aider logger level: " .. current_config.logger.level, vim.log.levels.INFO)
  end
  util.log("aider start")
  require("aider.file_watcher")
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

function M.readonly()
  actions.readonly()
end

function M.yes()
  tmux.send("Yes")
end

function M.no()
  tmux.send("No")
end

function M.models()
  actions.models()
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
