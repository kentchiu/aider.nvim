vim.api.nvim_create_user_command("Aider", function(opts)
  require("aider").toggle()
end, {
  nargs = "*",
  desc = "Start Aider",
})

vim.api.nvim_create_user_command("AiderSend", function(opts)
  local ask = vim.fn.input("Ask Aider: ")
  if ask ~= "" then
    require("aider").send(ask)
  else
    require("aider").send()
  end
end, {
  nargs = "*",
  desc = "Send text to Aider",
})

vim.api.nvim_create_user_command("AiderFix", function(opts)
  require("aider").fix()
end, {
  nargs = "*",
  desc = "Fix Diagnostic",
})

vim.keymap.set("n", "<leader>aa", "<cmd>Aider<cr>", { desc = "Toggle Adier" })
vim.keymap.set("v", "<leader>as", "<cmd>AiderSend<cr>", { desc = "Send Selection to Aider" })
vim.keymap.set("n", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })

-- require("aider").watch_file()
--

local util = require("aider.util")
util.log("adider.nvim start")
require("aider")
