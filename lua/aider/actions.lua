local M = {}

local util = require("aider.util")

---Fix diagnostics at the current cursor position
---@return nil
function M.fix()
  local terminal = require("aider.terminal")
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })

  if #diagnostics > 0 then
    local filename = vim.fn.expand("%")
    local current_line = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
    terminal.send("/add " .. filename, true)

    for _, diagnostic in ipairs(diagnostics) do
      local problem = vim.inspect(diagnostic):gsub("\n%s*", " ")
      local content = util.template_code(current_line, vim.bo.filetype)
      content = content .. " Fix this diagnostic: \n" .. util.template_code(problem, "lua")
      require("aider.dialog").toggle({
        content = content,
        filetype = "markdown",
      })
    end
  else
    vim.notify("No diagnostics for current line")
  end
  local foo = "bar"
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

--- Send current file to aider
function M.add_file()
  local filename = vim.fn.expand("%")
  local terminal = require("aider.terminal")
  terminal.send("/add " .. filename, true)
end

--- Drop current file from aider
function M.drop_file()
  local filename = vim.fn.expand("%")
  local terminal = require("aider.terminal")
  terminal.send("/drop " .. filename, true)
end

return M
