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

vim.api.nvim_create_user_command("AiderAddFiles", function(opts)
  require("aider").add_files()
end, {
  nargs = "*",
  desc = "Add Files to Aider",
})

vim.api.nvim_create_user_command("AiderDropFile", function(opts)
  require("aider").drop_file()
end, {
  nargs = "*",
  desc = "Drop Current File from Aider",
})

vim.api.nvim_create_user_command("AiderReadonly", function(opts)
  require("aider").readonly()
end, {
  nargs = "*",
  desc = "Add Current File as Readonly to Aider",
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

vim.api.nvim_create_user_command("AiderModels", function(opts)
  require("aider").models()
end, {
  nargs = "*",
  desc = "Test Terminal Buffer",
})

vim.api.nvim_create_user_command("AiderHistory", function(opts)
  require("aider").history()
end, {
  nargs = "*",
  desc = "Commnad History",
})

vim.api.nvim_create_user_command("AiderStart", function(opts)
  local tmux = require("aider.tmux")
  vim.ui.input({ prompt = "Enter text to send to Aider pane:" }, function(input)
    if input and input ~= "" then
      -- Send the user's input.
      -- It will use the stored aider_pane_id by default.
      tmux.send(input)
    else
      vim.notify("Input cancelled or empty, nothing sent.", vim.log.levels.INFO, { title = "Aider" })
    end
  end)
end, {
  nargs = "*",
  desc = "Select the Aider tmux pane (asynchronous)",
})

vim.api.nvim_create_user_command("AiderTest", function(opts)
  print("🟥[181]: aider.lua:81 (after vim.api.nvim_create_user_command(AiderTe…)")
  require("aider").history()
end, {
  nargs = "*",
  desc = "Prompt for input and send to selected Aider pane",
})
vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>AiderTest<cr>", { desc = "Aider Test" })

vim.keymap.set("n", "<leader>as", "<cmd>AiderStart<cr>", { desc = "Aider Send" })

-- vim.keymap.set({ "n", "v", "i", "t" }, "<M-a>", "<cmd>Aider<cr>", { desc = "Toggle Aider" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-y>", "<cmd>AiderYes<cr>", { desc = "Answer Yes" })
vim.keymap.set({ "n", "v", "i", "t" }, "<M-n>", "<cmd>AiderNo<cr>", { desc = "Answer No" })
-- vim.keymap.set("n", "<leader>aa", "<cmd>Aider<cr>", { desc = "Toggle Aider" })
vim.keymap.set("n", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("v", "<leader>af", "<cmd>AiderFix<cr>", { desc = "Fix Diagnostic" })
vim.keymap.set("n", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Open Dialog" })
vim.keymap.set("v", "<leader>ad", "<cmd>AiderDialog<cr>", { desc = "Open Dialog" })
vim.keymap.set("n", "<leader>a+", "<cmd>AiderAddFile<cr>", { desc = "Add Current File" })
vim.keymap.set("n", "<leader>a-", "<cmd>AiderDropFile<cr>", { desc = "Drop Current File" })
vim.keymap.set("n", "<leader>a*", "<cmd>AiderAddFiles<cr>", { desc = "Add Files" })
vim.keymap.set("n", "<leader>ar", "<cmd>AiderReadonly<cr>", { desc = "Add Current File as readonly" })
vim.keymap.set("n", "<leader>am", "<cmd>AiderModel<cr>", { desc = "Select LLM Model" })
vim.keymap.set("n", "<leader>ah", "<cmd>AiderHistory<cr>", { desc = "History" })
