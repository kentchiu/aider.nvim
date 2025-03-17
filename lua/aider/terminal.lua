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
  last_cursor_col = 1, -- 追蹤最後光標列位置
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
  aider_config = aider_config
    .. " --architect --model openrouter/deepseek/deepseek-r1 --editor-model gemini/gemini-2.0-flash --weak-model gemini/gemini-2.0-flash"
  -- aider_config = aider_config .. " --model " .. config.default_model
  aider_config = aider_config .. " --no-show-release-notes"
  aider_config = aider_config .. " --no-check-update"
  aider_config = aider_config .. " --chat-language " .. config.default_language
  aider_config = aider_config .. " " .. config.extra_config

  return aider_config
end

---Attaches buffer to handle input and setup automatic horizontal scrolling
---@return nil
local function attach_buffer()
  -- 監聽緩衝區內容變化
  vim.api.nvim_buf_attach(state.bufnr, false, {
    on_lines = function(_, buf, changedtick, first_line, last_line, last_line_in_range, byte_count)
      terminal_events.handle_lines(buf, changedtick, first_line, last_line, last_line_in_range, byte_count)

      -- 自動調整水平滾動位置，確保左側內容可見
      vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
          -- 獲取終端緩衝區中最後一行的內容
          local line_count = vim.api.nvim_buf_line_count(buf)
          if line_count > 0 then
            local last_line_content = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1]

            -- 確保顯示區域包含提示符 (通常在行首)
            if last_line_content and #last_line_content > 0 then
              -- 強制將視圖滾動到最左側，確保行首可見
              local view = vim.fn.winsaveview()
              view.leftcol = 0
              vim.fn.winrestview(view)
            end
          end
        end
      end)
    end,
  })

  -- 監聽終端輸出事件，確保視圖自動調整
  vim.api.nvim_create_autocmd("TermChanged", {
    buffer = state.bufnr,
    callback = function()
      vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
          -- 確保滾動位置正確，顯示行首
          local view = vim.fn.winsaveview()
          view.leftcol = 0
          vim.fn.winrestview(view)
        end
      end)
    end,
  })
end

---Sets up key mappings for the Aider terminal buffer.
---@return nil
local function setup_keymaps()
  vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], { buffer = state.bufnr, desc = "Exit terminal mode" })
  vim.keymap.set("n", "q", "<CMD>Aider<CR>", { buffer = state.bufnr, desc = "Close aider chat window" })
  vim.keymap.set("t", "<M-a>", "<CMD>Aider<CR>", { buffer = state.bufnr, desc = "Close aider chat window" })
  -- 僅保留基本必要的按鍵映射，移除所有滾動和調整窗口大小的映射
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

  -- 添加自動滾動位置重置，確保提示符始終可見
  vim.api.nvim_create_autocmd("TermEnter", {
    buffer = state.bufnr,
    callback = function()
      vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
          local view = vim.fn.winsaveview()
          view.leftcol = 0
          vim.fn.winrestview(view)
        end
      end)
    end,
    desc = "Reset horizontal scroll position when entering terminal mode",
  })
end

---Initializes the Aider terminal buffer and window.
---@return nil
local function initialize_terminal()
  local win_config = {
    split = "below",
    win = 0,
    -- width = math.floor(vim.o.columns * 0.5), -- 設置合適的初始寬度
    height = math.floor(vim.o.lines * 0.3),
  }

  state.bufnr = vim.api.nvim_create_buf(false, true)
  state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
  vim.api.nvim_set_current_win(state.winid)

  vim.wo[state.winid].number = false
  vim.wo[state.winid].relativenumber = false
  vim.wo[state.winid].wrap = false
  -- 設置較大的 sidescrolloff 值以提供更好的水平滾動體驗
  vim.wo[state.winid].sidescrolloff = 0 -- 設為0，我們自行控制滾動行為
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
function M.start()
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
      split = "below",
      win = 0,
      height = math.floor(vim.o.lines * 0.3),
    }
    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config or {})
    vim.api.nvim_set_current_win(state.winid)
    vim.cmd("startinsert")
  end
end

return M
