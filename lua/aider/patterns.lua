local util = require("aider.util")

---@class PatternHandler
---@field enabled boolean
---@field pattern string
---@field name string
local PatternHandler = {}

function PatternHandler:new(name, pattern)
  local instance = {
    name = name,
    pattern = pattern,
    enabled = true,
  }
  setmetatable(instance, { __index = PatternHandler })
  return instance
end

function PatternHandler:handle(matches, state)
  error("handle method must be implemented by subclass")
end

---@class ReadonlyHandler : PatternHandler
local ReadonlyHandler = {}
setmetatable(ReadonlyHandler, { __index = PatternHandler })

function ReadonlyHandler:new()
  local instance = PatternHandler:new("readonly", "^Readonly:%s*(.-)%s*$")
  setmetatable(instance, { __index = ReadonlyHandler })
  return instance
end

function ReadonlyHandler:handle(matches, state)
  state.readonly_files = {}
  for path in matches[1]:gmatch("[^,]+") do
    path = path:match("^%s*(.-)%s*$") -- Trim whitespace
    table.insert(state.readonly_files, path)
    util.log("add readonly file: " .. path, vim.log.levels.INFO)
  end
end

---@class EditableHandler : PatternHandler
local EditableHandler = {}
setmetatable(EditableHandler, { __index = PatternHandler })

function EditableHandler:new()
  local instance = PatternHandler:new("editable", "^Editable:%s*(.-)%s*$")
  setmetatable(instance, { __index = EditableHandler })
  return instance
end

function EditableHandler:handle(matches, state)
  state.editable_files = {}
  for path in matches[1]:gmatch("%S+") do
    table.insert(state.editable_files, path)
    util.log("add editable file: " .. path, vim.log.levels.INFO)
  end
end

---@class PromptHandler : PatternHandler
local PromptHandler = {}
setmetatable(PromptHandler, { __index = PatternHandler })

function PromptHandler:new()
  local instance = PatternHandler:new("prompt", "^([%w%-]+)>%s*$")
  setmetatable(instance, { __index = PromptHandler })
  return instance
end

function PromptHandler:handle(matches, state)
  local new_mode = matches[1]
  if new_mode ~= state.current_chat_mode then
    state.current_chat_mode = new_mode
    util.log("Chat mode changed to: " .. new_mode, vim.log.levels.INFO)
    for _, callback in ipairs(state.mode_change_callbacks or {}) do
      callback(new_mode)
    end
  end
end

---@class ReadyHandler : PatternHandler
local ReadyHandler = {}
setmetatable(ReadyHandler, { __index = PatternHandler })

function ReadyHandler:new()
  local instance = PatternHandler:new("ready", "([%w]*)>%s*$")
  setmetatable(instance, { __index = ReadyHandler })
  return instance
end

function ReadyHandler:handle(matches, state)
  state.ready = true
  util.log("terminal ready", vim.log.levels.INFO)
end

---@class FeedbackHandler : PatternHandler
local FeedbackHandler = {}
setmetatable(FeedbackHandler, { __index = PatternHandler })

function FeedbackHandler:new()
  local instance = PatternHandler:new("feedback", ".*%? %(Y%)es/%(N%)o.*")
  setmetatable(instance, { __index = FeedbackHandler })
  return instance
end

function FeedbackHandler:handle(matches, state)
  local m1 = matches[1]
  state.wait_for_feedback = m1
  util.log("Wait For Feedback" .. m1, vim.log.levels.INFO)
end

return {
  ReadonlyHandler = ReadonlyHandler,
  EditableHandler = EditableHandler,
  PromptHandler = PromptHandler,
  ReadyHandler = ReadyHandler,
  FeedbackHandler = FeedbackHandler,
}
