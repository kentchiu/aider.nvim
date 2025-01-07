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
    vim.notify("No diagnostics for current line", vim.log.levels.WARN)
  end
end

---Send the current visual selection to aider
---@return nil
function M.send(ask)
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  -- Ensure start_col <= end_col
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3]

  if start_row == end_row and start_col > end_col then
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  local filetype = vim.bo.filetype

  if #lines > 0 then
    local terminal = require("aider.terminal")
    local selection = table.concat(lines, "\n") .. "\n"
    local content = M.template_ask(selection, filetype, ask)
    util.log(content)
    terminal.send(content)
  else
    vim.notify("No text selected", vim.log.levels.WARN)
  end
end

function M.template_ask(input, filetype, ask)
  local tpl = "\n```" .. filetype .. "\n"
  tpl = tpl .. input
  tpl = tpl .. "```" .. "\n"
  if ask then
    tpl = tpl .. ask .. "\n"
  end
  return tpl
end

return M
