local M = {}

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
      terminal.send("Fix this diagnostic: " .. problem .. "\n")
    end
  else
    vim.notify("No diagnostics for current line", vim.log.levels.WARN)
  end
end

---Send the current visual selection to aider
---@return nil
function M.send(ask)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_text(0, start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3], {})
  local filetype = vim.bo.filetype

  if #lines > 0 then
    local terminal = require("aider.terminal")
    local selection = table.concat(lines, "\n") .. "\n"
    local content = M.template_ask(selection, filetype, ask)
    terminal.send(content .. "\n")
  else
    vim.notify("No text selected", vim.log.levels.WARN)
  end
end

function M.template_ask(input, filetype, ask)
  local tpl = "```" .. filetype .. "\n"
  tpl = tpl .. input
  tpl = tpl .. "```" .. "\n"
  if ask then
    tpl = tpl .. ask .. "\n"
  end
  return tpl
end

return M
