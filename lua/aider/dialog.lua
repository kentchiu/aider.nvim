local M = {}

local util = require("aider.util")

local state = {
  buf = nil,
  win = nil,
  content = nil, -- Initialize as nil instead of empty string
  filetype = "markdown",
}

local function template(input, filetype)
  if #input == 0 then
    return ""
  end
  local tpl = "```" .. filetype .. "\n"
  tpl = tpl .. input
  tpl = tpl .. "\n```" .. "\n"
  return tpl
end

function M.toggle(opts)
  opts = opts or {}
  state.content = opts.content or state.content or ""
  state.filetype = opts.filetype or state.filetype

  -- 如果窗口存在且有效，則關閉它
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    return
  end

  -- 如果窗口不存在，則打開新窗口
  M.open(opts)
end

function M.open(opts)
  opts = opts or {}

  if opts.content then
    state.content = opts.content
  end

  -- Create buffer if not exists
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(state.buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(state.buf, "filetype", "markdown")
  end

  local content = template(state.content, state.filetype)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, vim.split(content or "", "\n"))

  -- Close existing window if open
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.5)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Set up floating window options
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    title = " Input Text ",
    title_pos = "center",
  }

  -- Create the floating window
  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)

  -- 設置行號
  vim.wo[state.win].number = true
  vim.wo[state.win].relativenumber = false

  -- Set up keymaps for the dialog
  local keymap_opts = { buffer = state.buf, silent = true }

  -- Close dialog
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(state.win, true)
  end, keymap_opts)

  -- Send content to terminal and close
  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    local data = table.concat(vim.api.nvim_buf_get_lines(state.buf, 0, -1, false), "\n")
    local terminal = require("aider.terminal")
    terminal.send(data, true)
    vim.api.nvim_win_close(state.win, true)
  end, keymap_opts)

  -- Clear content
  vim.keymap.set("n", "<C-l>", function()
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
    state.content = ""
  end, keymap_opts)

  -- Enter insert mode and scroll to end
  vim.cmd("normal! G$")
  vim.cmd("startinsert")
end

return M
