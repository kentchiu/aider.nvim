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

vim.api.nvim_create_user_command("AiderChat", function(opts)
  require("aider.chat").open(opts.args)
end, {
  nargs = "*",
  desc = "Open Aider Chat",
})

vim.api.nvim_create_user_command("AiderTest", function(opts)
  local chat = require("aider.chat")
  local buf, win = chat.open(opts.args)
  chat.insert("Hello")
end, {
  nargs = "*",
  desc = "Aider Test",
})

vim.api.nvim_create_user_command("AiderInsert", function()
  local chat = require("aider.chat")

  -- Get visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  -- Get current buffer info
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.fn.expand("%:p")
  local filetype = vim.bo[current_buf].filetype

  -- Format the selection info
  local info = string.format("%s (lines %d-%d):", filename, start_pos[2], end_pos[2])

  -- Create markdown code block
  local markdown = {
    info,
    string.format("```%s", filetype),
  }

  -- Add selected lines
  vim.list_extend(markdown, lines)
  table.insert(markdown, "```")

  -- Insert into chat
  chat.insert(markdown)
end, {
  range = true,
  desc = "Insert selection into Aider Chat",
})

require("aider").watch_file()
