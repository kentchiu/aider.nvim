local M = {}

local events = require("aider.terminal_events")
local util = require("aider.util")

---Fix diagnostics at the current cursor position
---@return nil
function M.fix()
  local terminal = require("aider.terminal")
  local lines, line_start, line_end = util.get_visual_selection()
  local filename = vim.fn.expand("%")
  local diagnostics = {}
  local code

  if lines then
    -- Visual selection exists, get diagnostics for the selection
    for i = line_start, line_end do
      local line_diagnostics = vim.diagnostic.get(0, { lnum = i })
      for _, diagnostic in ipairs(line_diagnostics) do
        table.insert(diagnostics, diagnostic)
      end
    end
    code = lines
  else
    -- No visual selection, get diagnostics for the current line
    line_start = vim.api.nvim_win_get_cursor(0)[1] - 1
    line_end = line_start + 1
    diagnostics = vim.diagnostic.get(0, { lnum = line_start })
    code = vim.api.nvim_buf_get_lines(0, line_start, line_end, false)[1]
  end

  if #diagnostics > 0 then
    pcall(terminal.send, "/add " .. filename, true)

    local content = ""
    for _, diagnostic in ipairs(diagnostics) do
      content = content .. util.template_code(code, vim.bo.filetype, line_start, line_end, filename)
      content = content
        .. "For the code present, we get this error: \n\n"
        .. util.template_code(diagnostic.message)
        .. "\n"
      content = content .. "How can I resolve this? If you propose a fix, please make it concise.\n"
      content = content .. "\n\n"
      require("aider.dialog").toggle({ content = content })
      vim.api.nvim_command("stopinsert")
    end
  else
    vim.notify("No diagnostics for current selection/line")
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
  local mode = vim.api.nvim_get_mode().mode
  local lines, line_start, line_end = util.get_visual_selection()
  if mode == "n" then
    lines = nil
  end

  local dialog = require("aider.dialog")
  if lines then
    local fullpath = vim.fn.expand("%:p")
    local filetype = vim.bo.filetype
    dialog.toggle({ content = util.template_code(lines, filetype, line_start, line_end, fullpath) })
  else
    dialog.toggle({ content = "" })
  end
end

--- Send current file to aider
function M.add_file()
  local filename = vim.fn.expand("%")
  local terminal = require("aider.terminal")
  local editable_files = events.state.editable_files
  print("🟥[124]: actions.lua:84: editable_files=" .. vim.inspect(editable_files))

  -- editable_files: lua/aider/actions.lua
  -- filename: /home/kent/dev/kent/aider.nvim/lua/aider/file_watcher.lua
  -- check exists before filename add to editable_files, note that, filename maybe absolution path or relatve path.
  -- however editable_files is always be relactive path
  -- implement the exist() function to check existing of filename. AI!

  terminal.send("/add " .. filename, true)
end

--- Drop current file from aider
function M.drop_file()
  local filename = vim.fn.expand("%")
  local terminal = require("aider.terminal")
  terminal.send("/drop " .. filename, true)
end

return M
