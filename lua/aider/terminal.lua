---@class Aider
local M = {}
local terminal_events = require("aider.terminal_events")
local util = require("aider.util")
util.log("aider/init.lua")

local state = {
  bufnr = nil,
  winid = nil,
  initialized = false,
  job_id = nil,
}

---Check if terminal buffer is visible in any window
---@return boolean
local function is_visible()
  if not state.bufnr then
    return false
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.bufnr then
      return true
    end
  end
  return false
end

function M.hide()
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
    state.winid = nil
  end
end

function M.start(args)
  -- 如果 buffer 不存在才創建新的
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    local config = "--no-auto-commits --watch-files --no-auto-lint"
    config = config .. " --read .cursorrules"
    -- config = config .. " --model deepseek/deepseek-chat"
    config = config .. " --model r1"
    config = config .. " --no-show-release-notes"
    config = config .. " --no-check-update "
    -- config = config .. " --no-pretty "
    -- config = config .. " --no-stream "
    config = config .. " --chat-language zh-TW "

    local win_config = {
      split = "right",
      win = 0,
    }

    state.bufnr = vim.api.nvim_create_buf(false, true)
    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
    vim.api.nvim_set_current_win(state.winid)

    -- config
    vim.wo[state.winid].number = false
    vim.wo[state.winid].relativenumber = false
    vim.cmd("startinsert")
    vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], { buffer = state.bufnr, desc = "Exit terminal mode" })
    vim.keymap.set("n", "q", "<CMD>Aider<CR>", { buffer = state.bufnr, desc = "Close aider chat window" })

    state.job_id = vim.fn.termopen("aider " .. config)

    -- 監聽 buffer 變化來捕獲輸入
    vim.api.nvim_buf_attach(state.bufnr, false, {
      on_lines = function(_, buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
        terminal_events.handle_lines(buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
      end,
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
      buffer = state.bufnr,
      callback = function()
        vim.cmd("startinsert")
      end,
      desc = "Enter to insert mode when terminal gains focus",
    })
  end
end

---Send text to the aider buffer
---@param text string Text to send to aider
---@param enter boolean? Whether to send enter key after text (defaults to false)
---@return nil
function M.send(text, enter)
  -- Use bracketed paste sequences
  local paste_start = "\27[200~" -- paste start
  local paste_end = "\27[201~" -- paste end and enter
  local paste_data = paste_start .. text .. paste_end
  local data = paste_data
  if enter then
    data = data .. "\n"
  end

  vim.fn.chansend(vim.bo[state.bufnr].channel, data)
end

function M.toggle()
  util.log("aider info: " .. vim.inspect(state))
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    M.start()
  elseif is_visible() then
    M.hide()
  else
    local win_config = {
      split = "right",
      win = 0,
    }
    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
    vim.api.nvim_set_current_win(state.winid)
    vim.cmd("startinsert")
  end
end

return M
