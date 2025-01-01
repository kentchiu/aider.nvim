---@class AiderInit
local M = {}

---Start aider terminal
---@param args table|nil Optional arguments for aider
---@return nil
function M.start(args)
  require("aider.aider").start(args)
end

---Send text to aider
---@param text string Text to send to aider
---@return nil
function M.send(text)
  require("aider.aider").send(text)
end

--- Watch current buffer's file for changes and auto reload
--- This function sets up a file system watcher that monitors the current buffer's file
--- for changes. When changes are detected:
--- 1. Notifies the user
--- 2. Reloads the file if buffer is not modified
--- @note Uses vim.uv (libuv) for file system events
function M.watch_file()
  local function watch_file()
    local uv = vim.uv -- Use vim.uv for Neovim 0.10+
    local filename = vim.fn.expand("%:p")
    local handle = uv.new_fs_event()

    handle:start(filename, {}, function(err, _, _)
      if err then
        vim.api.nvim_err_writeln("Error watching file: " .. err)
        return
      end

      -- Schedule UI updates to run on the main thread
      -- This ensures buffer operations happen safely in Neovim's event loop
      vim.schedule(function()
        if vim.bo.modified then
        else
          -- Reload the buffer content directly from disk
          -- This is more efficient than using checktime
          local bufnr = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("e!")
          end)
        end
      end)
    end)
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = watch_file,
  })
end

function M.fix()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 行号从 0 开始
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  if #diagnostics > 0 then
    local filename = vim.fn.expand("%")
    M.send("/add " .. filename .. "\n")
    for _, diagnostic in ipairs(diagnostics) do
      local problem = vim.inspect(diagnostic):gsub("\n%s*", " ")
      M.send("Fix this diagnostic: " .. problem .. "\n")
    end
  else
    vim.notify("No diagnostics for current line", vim.log.levels.WARN)
  end
end

return M
