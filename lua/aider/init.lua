local M = {}

-- Create user command for sending text
vim.api.nvim_create_user_command("AiderSend", function(opts)
  M.send(opts.args)
end, {
  nargs = 1,
  desc = "Send text to aider buffer",
})

return M
