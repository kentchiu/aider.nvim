local util = require("aider.util")

---@class PatternHandler
---@field enabled boolean
---@field pattern string
---@field name string
---@field priority number 處理優先級
local PatternHandler = {}

function PatternHandler:new(name, pattern, priority)
  local instance = {
    name = name,
    pattern = pattern,
    enabled = true,
    priority = priority or 0
  }
  setmetatable(instance, { __index = PatternHandler })
  return instance
end

function PatternHandler:validate(matches)
  return true
end

function PatternHandler:preprocess(matches, state)
  -- 在處理前執行的邏輯
end

function PatternHandler:postprocess(matches, state)
  -- 在處理後執行的邏輯
end

function PatternHandler:handle(matches, state)
  error("handle method must be implemented by subclass")
end

---@class ReadonlyHandler : PatternHandler
local ReadonlyHandler = {}
setmetatable(ReadonlyHandler, { __index = PatternHandler })

function ReadonlyHandler:new()
  local instance = PatternHandler:new("readonly", "^Readonly:%s*(.-)%s*$", 10)
  setmetatable(instance, { __index = ReadonlyHandler })
  return instance
end

function ReadonlyHandler:handle(matches, state)
  self:preprocess(matches, state)
  
  state.readonly_files = {}
  for path in matches[1]:gmatch("[^,]+") do
    path = path:match("^%s*(.-)%s*$") -- Trim whitespace
    table.insert(state.readonly_files, path)
    util.log("add readonly file: " .. path)
  end
  
  self:postprocess(matches, state)
end

---@class EditableHandler : PatternHandler
local EditableHandler = {}
setmetatable(EditableHandler, { __index = PatternHandler })

function EditableHandler:new()
  local instance = PatternHandler:new("editable", "^Editable:%s*(.-)%s*$", 20)
  setmetatable(instance, { __index = EditableHandler })
  return instance
end

function EditableHandler:handle(matches, state)
  self:preprocess(matches, state)
  
  state.editable_files = {}
  for path in matches[1]:gmatch("%S+") do
    table.insert(state.editable_files, path)
    util.log("add editable file: " .. path)
  end
  
  self:postprocess(matches, state)
end

---@class PromptHandler : PatternHandler
local PromptHandler = {}
setmetatable(PromptHandler, { __index = PatternHandler })

function PromptHandler:new()
  local instance = PatternHandler:new("prompt", "^([%w%-]+)>%s*$", 30)
  setmetatable(instance, { __index = PromptHandler })
  return instance
end

function PromptHandler:handle(matches, state)
  self:preprocess(matches, state)
  state:trigger_mode_change(matches[1])
  self:postprocess(matches, state)
end

---@class ReadyHandler : PatternHandler
local ReadyHandler = {}
setmetatable(ReadyHandler, { __index = PatternHandler })

function ReadyHandler:new()
  local instance = PatternHandler:new("ready", "([%w]*)>%s*$", 40)
  setmetatable(instance, { __index = ReadyHandler })
  return instance
end

function ReadyHandler:handle(matches, state)
  self:preprocess(matches, state)
  state.ready = true
  util.log("terminal ready")
  self:postprocess(matches, state)
end

---@class FeedbackHandler : PatternHandler
local FeedbackHandler = {}
setmetatable(FeedbackHandler, { __index = PatternHandler })

function FeedbackHandler:new()
  local instance = PatternHandler:new("feedback", ".*%? %(Y%)es/%(N%)o.*", 50)
  setmetatable(instance, { __index = FeedbackHandler })
  return instance
end

function FeedbackHandler:handle(matches, state)
  self:preprocess(matches, state)
  state.wait_for_feedback = matches[1]
  util.log("Wait For Feedback" .. matches[1])
  self:postprocess(matches, state)
end

return {
  ReadonlyHandler = ReadonlyHandler,
  EditableHandler = EditableHandler,
  PromptHandler = PromptHandler,
  ReadyHandler = ReadyHandler,
  FeedbackHandler = FeedbackHandler,
}
