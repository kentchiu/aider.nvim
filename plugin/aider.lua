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

vim.api.nvim_create_user_command("AiderCommand", function(opts)
  require("aider.aider").command(opts.fargs[1], opts.fargs[2])
end, {
  nargs = "*",
  desc = "Run Aider Command",
})
