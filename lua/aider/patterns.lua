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
    priority = priority or 0,
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

function PatternHandler:handle(matches, state) end

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
  -- 實作 ReadyHandler 的具體邏輯
  -- 觸發狀態變更，類似 PromptHandler
  util.log("ReadyHandler triggered with mode: " .. matches[1], "DEBUG")
  state:trigger_mode_change(matches[1])
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
  PromptHandler = PromptHandler,
  ReadyHandler = ReadyHandler,
  FeedbackHandler = FeedbackHandler,
}
