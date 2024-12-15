vim.api.nvim_create_user_command("Aider", function(opts)
  require("aider").start(opts.args)
end, {
  nargs = "*",
  desc = "Start Aider",
})

vim.api.nvim_create_user_command("AiderSend", function(opts)
  require("aider").send(opts.args)
end, {
  nargs = "*",
  desc = "Send text to Aider",
})
