---@class AiderState
---@field history string[][] 儲存buffer變化的歷史記錄
---@field max_history number 最大歷史記錄數量
---@field editable_files string[] 可編輯文件路徑列表
---@field readonly_files string[] 唯讀文件路徑列表
---@field ready boolean is aider ready or processing
---@field current_chat_mode string 當前聊天模式
---@field wait_for_feedback string|nil 等待用戶反饋
---@field mode_change_callbacks function[] 模式變更回調函數列表
local State = {}

function State:new()
  local instance = {
    history = {},
    max_history = 1000,
    readonly_files = {},
    editable_files = {},
    ready = false,
    current_chat_mode = nil,
    wait_for_feedback = nil,
    mode_change_callbacks = {},
  }
  setmetatable(instance, { __index = State })
  return instance
end

-- 添加狀態變更事件
function State:on_mode_change(callback)
  table.insert(self.mode_change_callbacks, callback)
end

function State:trigger_mode_change(new_mode)
  if new_mode ~= self.current_chat_mode then
    self.current_chat_mode = new_mode
    for _, callback in ipairs(self.mode_change_callbacks) do
      callback(new_mode)
    end
  end
end

function State:reset()
  self.history = {}
  self.readonly_files = {}
  self.editable_files = {}
  self.ready = false
  self.current_chat_mode = nil
  self.wait_for_feedback = nil
end

return State
