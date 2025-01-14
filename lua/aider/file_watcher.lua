---@class AiderFileWatcher
local M = {}
local DEBOUNCE_MS = 3000 -- 3 second debounce time
local util = require("aider.util")

local handles = {}
local processing_files = {}

local function watch_file()
  local uv = vim.uv
  local fullpath = vim.fn.expand("%:p")
  local filename = vim.fn.fnamemodify(fullpath, ":t")
  local relate_path = vim.fn.fnamemodify(fullpath, ":.")

  if not fullpath or fullpath == "" then
    return
  end

  -- Skip non-normal buffers
  local bufnr = vim.fn.bufnr(fullpath)
  if bufnr == -1 or vim.bo[bufnr].buftype ~= "" then
    util.log("skip non-normal buffer: " .. fullpath, vim.log.levels.DEBUG)
    return
  end

  util.log("start watching file: " .. relate_path)

  if handles[fullpath] then
    handles[fullpath]:close()
    util.log("stop watching file: " .. relate_path)
  end

  local handle = uv.new_fs_event()
  handle:start(fullpath, {
    recursive = false,
    stat = true,
    watch_entry = true, -- 監控檔案本身
    -- persistent = true, -- 持續監控
  }, function(err, filename, events)
    if err then
      vim.notify("Error watching file: " .. err, vim.log.levels.ERROR)
      handle:close()
      handles[fullpath] = nil
      return
    end

    util.log("File event detected for: " .. fullpath)

    local current_stat = vim.loop.fs_stat(fullpath)
    if not current_stat then
      util.log("Failed to get file stat for: " .. fullpath)
      return
    end

    -- 檢查檔案是否被刪除或重命名
    if events.rename then
      util.log("File renamed or deleted: " .. fullpath)
      -- 清理相關資源
      handle:close()
      handles[fullpath] = nil
      processing_files[fullpath] = nil
      return
    end

    vim.schedule(function()
      util.log("Change detected in file: " .. relate_path)

      local current_time = vim.loop.now()

      if processing_files[fullpath] and (current_time - processing_files[fullpath]) < DEBOUNCE_MS then
        util.log("Skipping due to debounce for: " .. relate_path)
        return
      end

      processing_files[fullpath] = current_time

      local bufnr = vim.fn.bufnr(fullpath)
      if bufnr > 0 then
        -- 強制重新讀取buffer
        vim.cmd("checktime " .. bufnr)
        vim.notify(relate_path .. " changed from external", vim.log.levels.INFO)
      else
        util.log("Buffer not found for: " .. fullpath)
      end
    end)
  end)

  handles[fullpath] = handle
  util.log("Watch handle created for: " .. relate_path)
end

-- 監聽檔案進入 buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = watch_file,
})

-- 監聽檔案寫入
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    -- 短暫延遲後重新設置 watch，確保檔案系統操作完成
    vim.defer_fn(function()
      watch_file()
    end, 100)
  end,
})

-- 監聽檔案刪除
vim.api.nvim_create_autocmd("BufDelete", {
  pattern = "*",
  callback = function()
    local filename = vim.fn.expand("<afile>:p")
    if handles[filename] then
      handles[filename]:close()
      handles[filename] = nil
      util.log("stop watching file: " .. filename)
    end
    -- 清除處理狀態
    processing_files[filename] = nil
  end,
})

-- 監聽檔案重新載入
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  callback = function()
    local fullpath = vim.fn.expand("%:p")
    -- 重設處理狀態，允許下次變更能被處理
    processing_files[fullpath] = nil
    -- 重新設置 watch
    watch_file()
  end,
})

return M
