---@class EventEmitter
local EventEmitter = {}

function EventEmitter:new()
  local instance = {
    handlers = {}
  }
  setmetatable(instance, { __index = EventEmitter })
  return instance
end

function EventEmitter:on(event, handler)
  self.handlers[event] = self.handlers[event] or {}
  table.insert(self.handlers[event], handler)
end

function EventEmitter:off(event, handler)
  if self.handlers[event] then
    for i, h in ipairs(self.handlers[event]) do
      if h == handler then
        table.remove(self.handlers[event], i)
        break
      end
    end
  end
end

function EventEmitter:emit(event, ...)
  if self.handlers[event] then
    for _, handler in ipairs(self.handlers[event]) do
      handler(...)
    end
  end
end

function EventEmitter:clear(event)
  if event then
    self.handlers[event] = {}
  else
    self.handlers = {}
  end
end

return EventEmitter 