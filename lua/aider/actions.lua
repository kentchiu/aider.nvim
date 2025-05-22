local M = {}

local tmux = require("aider.tmux")
local util = require("aider.util")

---Fix diagnostics at the current cursor position
---@return nil
function M.fix()
  local lines, line_start, line_end = util.get_visual_selection()
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
    line_start = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based line number
    line_end = line_start + 1
    diagnostics = vim.diagnostic.get(0, { lnum = line_start, end_lnum = line_end }) -- Use 0-based line number for diagnostics
    code = vim.api.nvim_buf_get_lines(0, line_start, line_end, false)[1]
  end

  if #diagnostics > 0 then
    local content = ""
    local filename = vim.fn.expand("%:.")
    content = content .. util.template_code(code, vim.bo.filetype, line_start, line_end, filename) .. "\n\n"
    for _, diagnostic in ipairs(diagnostics) do
      content = content
        .. "For the code present, we get this error: \n\n"
        .. util.template_code(diagnostic.message)
        .. "\n"
      break -- only show 1 diagnostic
    end
    content = content .. "---\n"
    content = content .. "How can I resolve this? If you propose a fix, please make it concise.\n"
    content = content .. "\n\n"
    require("aider.dialog").toggle({ content = content })
    vim.api.nvim_command("stopinsert")
  else
    vim.notify("No diagnostics for current selection/line")
  end
end

---Send the current visual selection to aider
---@return nil
function M.send(content)
  if content then
    tmux.send(content)
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
  tmux.send("/add " .. filename)
end

function M.add_files()
  local snacks = require("snacks")
  snacks.picker.pick({
    source = "files",
    title = "Test files picker",
    confirm = function(picker, item, action)
      local selections = picker:selected()
      if #selections > 0 then
        local files = ""
        for _, selection in ipairs(selections) do
          files = files .. " " .. selection.file
        end
        tmux.send("/add " .. files)
      elseif item then
        tmux.send("/add " .. item.file)
      end
      picker:close()
    end,
  })
end

function M.drop_file()
  local filename = vim.fn.expand("%")
  tmux.send("/drop " .. filename)
end

function M.readonly()
  local filename = vim.fn.expand("%")
  tmux.send("/read-only " .. filename)
end

return M
