---@class AiderFileWatcher
local M = {}
local util = require("aider.util")

local handles = {}

local function watch_file()
  local uv = vim.uv
  local filename = vim.fn.expand("%:p")
  if not filename or filename == "" then
    return
  end
  util.log("start waitching file: " .. filename)

  util.log(vim.inspect(handles))

  if handles[filename] then
    handles[filename]:close()
    util.log("stop waitching file: " .. filename)
  end

  local handle = uv.new_fs_event()
  handle:start(filename, {}, function(err)
    if err then
      vim.notify("Error watching file: " .. err, vim.log.levels.ERROR)
      handle:close()
      handles[filename] = nil
      return
    end

    vim.schedule(function()
      if vim.bo.modified then
        util.log("Buffer has unsaved changes - not reloading")
      else
        local bufnr = vim.fn.bufnr(filename)
        if bufnr > 0 then
          vim.api.nvim_buf_call(bufnr, function()
            util.log("Buffer has changes reload file: " .. filename)
            vim.cmd("e!")
          end)
        end
      end
    end)
  end)

  handles[filename] = handle
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = watch_file,
})

vim.api.nvim_create_autocmd("BufDelete", {
  pattern = "*",
  callback = function()
    local filename = vim.fn.expand("<afile>:p")
    if handles[filename] then
      handles[filename]:close()
      handles[filename] = nil
      util.log("stop waitching file: " .. filename)
    end
  end,
})

return M
