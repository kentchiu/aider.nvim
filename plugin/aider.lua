vim.api.nvim_create_user_command("Aider", function(opts)
  require("aider").toggle()
end, {
  nargs = "*",
  desc = "Start Aider",
})

-- vim.api.nvim_create_user_command("AiderSend", function(opts)
--   local ask = vim.fn.input("Ask Aider: ")
--   if ask ~= "" then
--     require("aider").send(ask)
--   else
--     require("aider").send()
--   end
-- end, {
--   nargs = "*",
--   desc = "Send text to Aider",
-- })

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

vim.api.nvim_create_user_command("AiderTest", function(opts)
  local util = require("aider.util")
  local lines = util.get_visual_selection()
  require("aider.terminal").send(table.concat(lines, "\n"))
end, {
  nargs = "*",
  desc = "For Test",
})

vim.keymap.set("v", "<leader>aa", "<cmd>AiderTest<cr>", { desc = "Adier Test" })
vim.keymap.set("n", "<leader>a/", "<cmd>Aider<cr>", { desc = "Toggle Adier" })
-- vim.keymap.set("v", "<leader>as", "<cmd>AiderSend<cr>", { desc = "Send Selection to Aider" })
vim.keymap.set("n", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("n", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Fix Dialog" })
vim.keymap.set("v", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Fix Dialog" })

-- require("aider").watch_file()
--

local util = require("aider.util")
util.default_level = vim.log.levels.TRACE
util.log("adider.nvim start")
require("aider")
