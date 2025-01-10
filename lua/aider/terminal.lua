---@class Aider
local M = {}
local util = require("aider.util")
util.log("aider/init.lua")

---@class AiderState
---@field buf number|nil Buffer ID for the aider terminal
---@field initialized boolean Whether aider has been initialized

-- Store buffer ID and state
local state = {
  buf = nil,
  win_id = nil,
  initialized = false,
}

---Check if terminal buffer is visible in any window
---@return boolean
local function is_visible()
  if not state.buf then
    return false
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.buf then
      return true
    end
  end
  return false
end

---Get the aider buffer ID
---@return number|nil buffer Buffer ID of the aider terminal
function M.get_buffer()
  return state.buf
end

---Check if aider is initialized
---@return boolean initialized Whether aider has been initialized
function M.is_initialized()
  return state.initialized
end

---Clean up aider state and close buffer
---@return nil
function M.cleanup()
  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_win_close(state.win_id, true)
    state.win_id = nil
  end
end

---Start the aider terminal
---@param args table|nil Optional arguments for aider
---@return nil
function M.start(args)
  -- 如果 buffer 不存在才創建新的
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.cmd("vsplit")
    state.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win_id, state.buf)
    local config = "--no-auto-commits --watch-files --no-auto-lint"
    config = config .. " --read .cursorrules"
    -- config = config .. " --multiline"
    -- config = config .. " --no-pretty"
    vim.fn.termopen("aider " .. config)
    vim.api.nvim_buf_set_option(state.buf, "number", false)
    vim.api.nvim_buf_set_option(state.buf, "relativenumber", false)
    vim.cmd("startinsert")
    vim.keymap.set("t", "<c-x>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Exit terminal mode" })
    -- vim.keymap.set("t", "q", "<CMD>Aider<CR>", { buffer = state.buf, desc = "Close aider chat window" })
    state.initialized = true
  else
    -- Buffer 已存在,只需要創建新窗口
    vim.cmd("vsplit")
    state.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win_id, state.buf)
    vim.cmd("startinsert")
  end
end

---Send text to the aider buffer
---@param text string Text to send to aider
---@param enter boolean? Whether to send enter key after text (defaults to false)
---@return nil
function M.send(text, enter)
  if not is_visible() then
    require("aider").toggle()
  end

  -- Use bracketed paste sequences
  local paste_start = "\27[200~" -- paste start
  local paste_end = "\27[201~" -- paste end and enter
  local paste_data = paste_start .. text .. paste_end
  local data = paste_data
  if enter then
    data = data .. "\n"
  end

  vim.fn.chansend(vim.bo[state.buf].channel, data)
end

function M.toggle()
  util.log("aider info: " .. vim.inspect(state))
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    -- First time: create new terminal
    M.start()
  elseif is_visible() then
    -- Terminal is visible: hide it
    M.cleanup()
  else
    -- Terminal exists but not visible: show it
    vim.cmd("vsplit")
    state.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win_id, state.buf)
  end
end

return M
