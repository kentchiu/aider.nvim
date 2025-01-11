local M = {}
local util = require("aider.util")

---@param filename string
---@param bufnr number
function M.handle_file_change(filename, bufnr)
  -- Save current content to temp file
  local temp_file = os.tmpname()
  local current_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local f = io.open(temp_file, "w")
  if f then
    f:write(table.concat(current_content, "\n"))
    f:close()
  end

  -- Read file content from disk to detect external changes
  local disk_content = {}
  f = io.open(filename, "r")
  if f then
    for line in f:lines() do
      table.insert(disk_content, line)
    end
    f:close()
  end

  -- Always open diff view
  vim.cmd("tabnew " .. temp_file)
  vim.cmd("setlocal buftype=nofile")
  vim.cmd("diffthis")
  
  -- Split and open current file
  vim.cmd("vsplit " .. filename)
  vim.cmd("diffthis")
  
  -- Show notification about diff status
  if vim.v.shell_error ~= 0 then
    vim.notify("External changes detected in diff view.", vim.log.levels.INFO)
  else
    vim.notify("No external changes detected in diff view.", vim.log.levels.INFO)
  end

  -- Register autocmd to cleanup temp file when diff is closed
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = vim.fn.bufnr(temp_file),
    callback = function()
      os.remove(temp_file)
      -- Turn off diff mode in the original buffer
      vim.cmd("diffoff!")
    end,
    once = true,
  })
end

return M
