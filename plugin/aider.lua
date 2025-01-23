vim.api.nvim_create_user_command("Aider", function(opts)
  require("aider").toggle()
end, {
  nargs = "*",
  desc = "Start Aider",
})

vim.api.nvim_create_user_command("AiderFix", function(opts)
  require("aider").fix()
end, {
  nargs = "*",
  desc = "Fix Diagnostic",
})

vim.api.nvim_create_user_command("AiderDialog", function(opts)
  require("aider").dialog()
end, {
  nargs = "*",
  desc = "Open Dialog",
})

vim.api.nvim_create_user_command("AiderAddFile", function(opts)
  require("aider").add_file()
end, {
  nargs = "*",
  desc = "Add Current File to Aider",
})

vim.api.nvim_create_user_command("AiderDropFile", function(opts)
  require("aider").drop_file()
end, {
  nargs = "*",
  desc = "Drop Current File from Aider",
})

vim.api.nvim_create_user_command("AiderTest", function(opts) end, {
  nargs = "*",
  desc = "Test Terminal Buffer",
})

-- vim.keymap.set("v", "<leader>aa", "<cmd>AiderTest<cr>", { desc = "Adier Test" })
vim.keymap.set("n", "<leader>aa", "<cmd>Aider<cr>", { desc = "Toggle Adier" })
vim.keymap.set("n", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("n", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Fix Dialog" })
vim.keymap.set("v", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Fix Dialog" })
vim.keymap.set("n", "<leader>a+", "<cmd>AiderAddFile<cr>", { desc = "Add Current File" })
vim.keymap.set("n", "<leader>a-", "<cmd>AiderDropFile<cr>", { desc = "Drop Current File" })

-- require("aider").watch_file()
--

local util = require("aider.util")
-- only enable logger when aider is found in path
if vim.fn.glob(".aider.*") ~= "" then
  util.default_level = vim.log.levels.WARN
else
  util.default_level = vim.log.levels.OFF
end
util.log("adider.nvim start")
require("aider")
