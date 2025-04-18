local M = {}

local events = require("aider.terminal_events")
local terminal = require("aider.terminal") -- 將 terminal 載入到局部變數
local util = require("aider.util")

---Fix diagnostics at the current cursor position
---@return nil
function M.fix()
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
    -- pcall(terminal.send, "/add " .. filename, true)

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
  if content then
    terminal.send(content) -- 使用局部變數 terminal
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
  local editable_files = events.state.editable_files

  -- 將絕對路徑轉換為相對路徑
  local relative_path = vim.fn.fnamemodify(filename, ":.")

  -- 檢查檔案是否已存在於 editable_files
  local exists = false
  for _, file in ipairs(editable_files) do
    if file == relative_path then
      exists = true
      break
    end
  end

  if exists then
    vim.notify("File " .. relative_path .. " is already being edited by aider", vim.log.levels.WARN)
    return
  end

  terminal.send("/add " .. filename, true)
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
        terminal.send("/add " .. files, true)
      elseif item then
        terminal.send("/add " .. item.file, true)
      end
      picker:close()
    end,
  })
end

--- Drop current file from aider
function M.drop_file()
  local filename = vim.fn.expand("%")
  terminal.send("/drop " .. filename, true) -- 使用局部變數 terminal
end

return M
