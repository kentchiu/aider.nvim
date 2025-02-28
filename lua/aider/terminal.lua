---@class Aider
local M = {}
local terminal_events = require("aider.terminal_events")
local util = require("aider.util")

util.log("aider/init.lua")

---@class AiderTerminalState
local state = {
  bufnr = nil,
  winid = nil,
  initialized = false,
  job_id = nil,
}

---@class AiderTerminalConfig
local config = {
  -- openrouter/anthropic/claude-3.7-sonnet
  -- openrouter/deepseek/deepseek-chat
  -- openrouter/deepseek/deepseek-r1
  -- gemini/gemini-2.0-flash
  --
  default_model = "gemini/gemini-2.0-flash",
  default_language = "Traditional-Chinese",
  extra_config = "", -- 用户可以添加额外的 Aider 配置
}

---Configures the Aider terminal with user settings.
---@param user_config AiderTerminalConfig User-provided configuration that overrides the defaults.
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
end

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

---Hides the Aider terminal window if it is currently visible.
function M.hide()
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
    state.winid = nil
  end
end

---Builds the Aider command line configuration string.
---@return string The Aider command line configuration.
local function build_aider_config()
  local aider_config = "--no-auto-commits --watch-files --no-auto-lint"
  aider_config = aider_config .. " --read .cursorrules"
  aider_config = aider_config .. " --model " .. config.default_model
  aider_config = aider_config .. " --no-show-release-notes"
  aider_config = aider_config .. " --no-check-update"
  aider_config = aider_config .. " --chat-language " .. config.default_language
  aider_config = aider_config .. " " .. config.extra_config

  return aider_config
end

---Attaches buffer to handle input
---@return nil
local function attach_buffer()
  vim.api.nvim_buf_attach(state.bufnr, false, {
    on_lines = function(_, buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
      terminal_events.handle_lines(buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
    end,
  })
end

---Sets up key mappings for the Aider terminal buffer.
---@return nil
local function setup_keymaps()
  vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], { buffer = state.bufnr, desc = "Exit terminal mode" })
  vim.keymap.set("n", "q", "<CMD>Aider<CR>", { buffer = state.bufnr, desc = "Close aider chat window" })
end

---Sets up autocommands for the Aider terminal buffer.
---@return nil
local function setup_autocommands()
  vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
    buffer = state.bufnr,
    callback = function()
      vim.cmd("startinsert")
    end,
    desc = "Enter to insert mode when terminal gains focus",
  })
end

---Initializes the Aider terminal buffer and window.
---@return nil
local function initialize_terminal()
  local win_config = {
    split = "right",
    win = 0,
  }

  state.bufnr = vim.api.nvim_create_buf(false, true)
  state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
  vim.api.nvim_set_current_win(state.winid)

  vim.wo[state.winid].number = false
  vim.wo[state.winid].relativenumber = false
  vim.cmd("startinsert")

  setup_keymaps()
  attach_buffer()
  setup_autocommands()
end

---Starts the Aider process in the terminal buffer.
---@return nil
local function start_aider()
  local aider_config = build_aider_config()
  state.job_id = vim.fn.jobstart("aider " .. aider_config, { term = true })
end

---Starts the Aider terminal if it is not already running.
---@param args table Arguments passed to the start function (currently unused).
function M.start(args)
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    initialize_terminal()
    start_aider()
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

---Toggles the visibility of the Aider terminal.
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
      title = "Aider",
    }
    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config or {})
    vim.api.nvim_set_current_win(state.winid)
    vim.cmd("startinsert")
  end
end

return M
