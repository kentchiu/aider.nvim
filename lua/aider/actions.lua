local M = {}

local util = require("aider.util")

---Fix diagnostics at the current cursor position
---@return nil
function M.fix()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 行号从 0 开始
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  if #diagnostics > 0 then
    local filename = vim.fn.expand("%")
    local terminal = require("aider.terminal")
    terminal.send("/add " .. filename .. "\n")
    for _, diagnostic in ipairs(diagnostics) do
      local problem = vim.inspect(diagnostic):gsub("\n%s*", " ")
      terminal.send("Fix this diagnostic: " .. "\n" .. problem .. "\n")
    end
  else
    vim.notify("No diagnostics for current line")
  end
end

---Send the current visual selection to aider
---@return nil
function M.send(content)
  util.log(content, vim.log.levels.INFO)
  if content then
    require("aider.terminal").send(content)
  end
end

---Open a floating dialog for multi-line text input
---@return nil
function M.dialog()
  local lines = util.get_visual_selection()
  local filetype = vim.bo.filetype

  local dialog = require("aider.dialog")
  if lines then
    dialog.toggle({ content = lines, filetype = filetype })
  else
    dialog.toggle({ filetype = filetype })
  end
end

return M
