---@class Aider
local M = {}

---@class AiderState
---@field buf number|nil Buffer ID for the aider terminal
---@field initialized boolean Whether aider has been initialized

-- Store buffer ID and state
local state = {
  buf = nil,
  win_id = nil,
  initialized = false,
}

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
    vim.fn.termopen("aider")
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Exit terminal mode" })
    vim.keymap.set("t", "q", "<CMD>Aider<CR>", { buffer = state.buf, desc = "Close aider chat window" })
    state.initialized = true
  else
    -- Buffer 已存在,只需要創建新窗口
    vim.cmd("vsplit")
    state.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win_id, state.buf)
  end
end

---Send text to the aider buffer
---@param text string Text to send to aider
---@return nil
function M.send(text)
  if not state.initialized then
    require("aider").toggle()
  end

  -- mutil-line chat
  if text:find("\n") then
    text = "{DATA\n" .. text .. "\nDATA}"
  end

  vim.api.nvim_chan_send(vim.bo[state.buf].channel, text)
end

function M.toggle()
  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    -- Window exists, close it
    M.cleanup()
  else
    -- Window doesn't exist, create it
    M.start()
  end
end

return M
