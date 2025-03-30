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

vim.api.nvim_create_user_command("AiderDropFiles", function(opts)
  require("aider").drop_files()
end, {
  nargs = "*",
  desc = "Drop Files from Aider",
})

vim.api.nvim_create_user_command("AiderTest", function(opts) end, {
  nargs = "*",
  desc = "Test Terminal Buffer",
})

vim.api.nvim_create_user_command("AiderYes", function(opts)
  require("aider").yes()
end, {
  nargs = "*",
  desc = "Test Terminal Buffer",
})

vim.api.nvim_create_user_command("AiderNo", function(opts)
  require("aider").no()
end, {
  nargs = "*",
  desc = "Test Terminal Buffer",
})

-- vim.keymap.set("v", "<leader>aa", "<cmd>AiderTest<cr>", { desc = "Aider Test" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-a>", "<cmd>Aider<cr>", { desc = "Toggle Aider" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-y>", "<cmd>AiderYes<cr>", { desc = "Answer Yes" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-n>", "<cmd>AiderNo<cr>", { desc = "Answer No" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-l>", "<cmd>AiderDropFiles<cr>", { desc = "Drop Files" })
vim.keymap.set("n", "<leader>aa", "<cmd>Aider<cr>", { desc = "Toggle Aider" })
vim.keymap.set("n", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("v", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("n", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Open Dialog" })
vim.keymap.set("v", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Open Dialog" })
vim.keymap.set("n", "<leader>a+", "<cmd>AiderAddFile<cr>", { desc = "Add Current File" })
vim.keymap.set("n", "<leader>a-", "<cmd>AiderDropFile<cr>", { desc = "Drop Current File" })
