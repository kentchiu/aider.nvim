local M = {}
local tmux = require("aider.tmux")
-- local terminal = require("aider.terminal")

local state = {
  bufrn = nil,
  winid = nil,
  content = nil, -- Initialize as nil instead of empty string
}

function M.toggle(opts)
  opts = opts or {}
  state.content = opts.content or state.content or ""
  -- state.filetype = opts.filetype or state.filetype
  state.line_start = opts.line_start or state.line_start
  state.line_end = opts.line_end or state.line_end

  -- 如果窗口存在且有效，則關閉它
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
    state.winid = nil
    return
  end

  -- 如果窗口不存在，則打開新窗口
  M.open(opts)
end

function M.open(opts)
  -- terminal.start()
  opts = opts or {}

  if opts.content then
    state.content = opts.content
  end

  -- Create buffer if not exists
  if not state.bufrn or not vim.api.nvim_buf_is_valid(state.bufrn) then
    state.bufrn = vim.api.nvim_create_buf(false, true)
    vim.bo[state.bufrn].buftype = "nofile"
    vim.bo[state.bufrn].bufhidden = "hide"
    vim.bo[state.bufrn].filetype = "markdown"
  end

  -- get file path
  vim.api.nvim_buf_set_lines(state.bufrn, 0, -1, false, vim.split(state.content or "", "\n"))

  -- Close existing window if open
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
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
    border = "rounded",
    title = " Alt-s to Send ",
    title_pos = "center",
  }

  state.winid = vim.api.nvim_open_win(state.bufrn, true, win_opts)

  vim.wo[state.winid].wrap = true
  vim.wo[state.winid].number = false
  vim.wo[state.winid].relativenumber = false
  local keymap_opts = { buffer = state.bufrn, silent = true }

  -- Close dialog
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(state.winid, true)
  end, keymap_opts)

  -- Send content to terminal and close
  vim.keymap.set({ "n", "i" }, "<M-s>", function()
    local data = table.concat(vim.api.nvim_buf_get_lines(state.bufrn, 0, -1, false), "\n")
    tmux.send(data)
    vim.api.nvim_win_close(state.winid, true)
  end, keymap_opts)

  -- Clear content
  vim.keymap.set("n", "<M-l>", function()
    vim.api.nvim_buf_set_lines(state.bufrn, 0, -1, false, {})
    state.content = ""
  end, keymap_opts)

  -- Enter insert mode and scroll to end
  vim.cmd("normal! G$")
  vim.cmd("startinsert")
end

return M
