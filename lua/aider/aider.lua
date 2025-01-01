---@class Aider
local M = {}

---@class AiderState
---@field buf number|nil Buffer ID for the aider terminal
---@field initialized boolean Whether aider has been initialized

-- Store buffer ID and state
local state = {
  buf = nil,
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
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  -- state.buf = nil
  -- state.initialized = false
end

---Start the aider terminal
---@param args table|nil Optional arguments for aider
---@return nil
function M.start(args)
  -- Clean up any existing buffer
  M.cleanup()

  -- Create a new buffer for the terminal
  state.buf = vim.api.nvim_create_buf(false, true)

  -- Split window at bottom and set its height
  vim.cmd("vsplit")
  -- vim.api.nvim_win_set_height(0, 15)

  -- Set buffer in the window
  vim.api.nvim_win_set_buf(0, state.buf)

  -- Open terminal with aider command
  vim.fn.termopen("aider")

  -- Set up terminal mappings for this buffer
  vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Exit terminal mode" })

  -- Mark as initialized
  state.initialized = true
end

---Send text to the aider buffer
---@param text string Text to send to aider
---@return nil
function M.send(text)
  if not state.initialized then
    vim.notify("Aider buffer not initialized. Call start() first.", vim.log.levels.ERROR)
    return
  end

  -- Send text to terminal followed by Enter
  vim.api.nvim_chan_send(vim.bo[state.buf].channel, text)
end

---Run an aider command
---@param command string Command name without leading slash (e.g. "add", "drop", "ask")
---@param args string|nil Optional arguments for the command
---@return nil
function M.command(command, args)
  local cmd = "/" .. command
  if args then
    cmd = cmd .. " " .. args .. "\n"
  else
    cmd = cmd .. " " .. "\n"
  end
  M.send(cmd)
end

return M
