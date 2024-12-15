local M = {}

-- Store buffer ID and state
local state = {
  buf = nil,
  initialized = false,
}

-- Get aider buffer
function M.get_buffer()
  return state.buf
end

-- Check if aider is initialized
function M.is_initialized()
  return state.initialized
end

-- Clean up aider state
function M.cleanup()
  print("🟥[23]: init.lua:20: M.cleanup=" .. vim.inspect(M.cleanup))
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  -- state.buf = nil
  -- state.initialized = false
end

-- Create user command for sending text
vim.api.nvim_create_user_command("AiderSend", function(opts)
  M.send(opts.args)
end, {
  nargs = 1,
  desc = "Send text to aider buffer",
})

function M.start(args)
  print("Starting aider with args:")
  print(vim.inspect(args))

  -- Clean up any existing buffer
  M.cleanup()

  -- Create a new buffer for the terminal
  state.buf = vim.api.nvim_create_buf(false, true)

  -- Split window at bottom and set its height
  vim.cmd("botright split")
  vim.api.nvim_win_set_height(0, 15)

  -- Set buffer in the window
  vim.api.nvim_win_set_buf(0, state.buf)

  -- Open terminal with aider command
  vim.fn.termopen("aider")

  -- Set up terminal mappings for this buffer
  vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Exit terminal mode" })

  -- Mark as initialized
  state.initialized = true

  -- Set up cleanup on VimLeave
  -- vim.api.nvim_create_autocmd("VimLeave", {
  --   callback = M.cleanup,
  --   desc = "Cleanup aider buffer on exit",
  -- })
end

-- Send text to the aider buffer
function M.send(text)
  print("🟥[22]: init.lua:75: state=" .. vim.inspect(state))
  if not state.initialized then
    vim.notify("Aider buffer not initialized. Call start() first.", vim.log.levels.ERROR)
    return
  end

  print("🟥[21]: init.lua:81: state.buf=" .. vim.inspect(state.buf))
  -- Send text to terminal followed by Enter
  vim.api.nvim_chan_send(vim.bo[state.buf].channel, text)
end

return M
