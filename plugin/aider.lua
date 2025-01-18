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

vim.api.nvim_create_user_command("AiderTest", function(opts)
  -- 創建一個新的 terminal buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- 設置 buffer 的回調函數
  vim.api.nvim_buf_attach(buf, false, {
    on_bytes = function(
      _,
      _,
      _,
      start_row,
      start_col,
      offset,
      old_end_row,
      old_end_col,
      old_len,
      new_end_row,
      new_end_col,
      new_len
    )
      -- 記錄詳細的調試信息
      util.log("on_bytes callback triggered")
      util.log(
        string.format(
          "Buffer change details: start(%d,%d) old(%d,%d,%d) new(%d,%d,%d)",
          start_row,
          start_col,
          old_end_row,
          old_end_col,
          old_len,
          new_end_row,
          new_end_col,
          new_len
        )
      )

      -- 檢查 buffer 是否仍然有效
      if not vim.api.nvim_buf_is_valid(buf) then
        util.log("Buffer is no longer valid")
        return false
      end

      -- 嘗試獲取緩衝區內容
      local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, -1, false)
      if ok then
        util.log("Current buffer content:")
        for i, line in ipairs(lines) do
          util.log(string.format("%d: %s", i, line))
        end
      else
        util.log("Failed to get buffer lines: " .. tostring(lines))
      end

      -- 打印到命令行
      print("on_bytes callback executed successfully")
      return true
    end,
    -- 添加 on_lines callback 作為備選
    on_lines = function(_, buf, changedtick, firstline, lastline, new_lastline)
      print(string.format("Lines changed: first=%d, last=%d, new_last=%d", firstline, lastline, new_lastline))
      return true
    end,
  })

  -- 打開 terminal
  local chan_id = vim.api.nvim_open_term(buf, {})

  -- 測試發送數據
  vim.schedule(function()
    print("Sending test data...")

    -- 測試發送單行文字
    vim.api.nvim_chan_send(chan_id, "Hello\n")

    -- 延遲發送其他測試數據
    vim.defer_fn(function()
      print("Sending multi-line text...")
      vim.api.nvim_chan_send(chan_id, "Line 1\nLine 2\n")
    end, 1000)

    vim.defer_fn(function()
      print("Sending special chars...")
      vim.api.nvim_chan_send(chan_id, "Special chars: 測試中文\n")
    end, 2000)
  end)

  -- 在新窗口中顯示 buffer
  vim.api.nvim_command("vsplit")
  vim.api.nvim_win_set_buf(0, buf)

  -- 記錄測試信息
  local util = require("aider.util")
  util.log("Terminal test started - channel ID: " .. chan_id)
  print("Test started with channel ID: " .. chan_id)
end, {
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
util.default_level = vim.log.levels.DEBUG
util.log("adider.nvim start")
require("aider")
