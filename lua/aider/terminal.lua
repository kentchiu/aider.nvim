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
  -- 73/90?, $ ?
  -- model = " --model gemini-2.5-pro",
  -- 64/100, $13
  -- model = " --architect --model r1 --editor-model sonnet",
  -- 60/93, $18
  -- model = " --model sonnet,"
  -- 57/97, $5.5
  -- model = " --model deepseek/deepseek-reasoner",
  -- 55/100, $1.12
  -- model = " --model deepseek/deepseek-chat",
  -- 36/100
  -- model =" --model gemini/gemini-2.0-pro-exp-02-05"
  -- model = " --architect --model gemini/gemini-2.0-flash-thinking-exp --editor-model gemini/gemini-2.0-pro-exp-02-05 --weak-model gemini/gemini-2.0-pro-exp-02-05",
  -- model = " --architect --model openrouter/deepseek/deepseek-r1 --editor-model gemini/gemini-2.0-flash --weak-model gemini/gemini-2.0-flash",
  -- free model
  model = " --model gemini/gemini-2.0-flash",
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
  -- aider_config = aider_config .. " --read .cursorrules"
  aider_config = aider_config .. config.model
  -- aider_config = aider_config
  --   .. " aider --architect --model openrouter/deepseek/deepseek-r1 --editor-model gemini/gemini-2.0-flash --weak-model gemini/gemini-2.0-flash"
  -- aider_config = aider_config .. " --model " .. config.default_model
  -- aider.nvim terminal events only work when pretty is true
  aider_config = aider_config .. " --pretty"
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

      -- 自动移动光标到最后一行
      vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
          vim.api.nvim_win_call(state.winid, function()
            local last_line_num = vim.api.nvim_buf_line_count(state.bufnr)
            vim.api.nvim_win_set_cursor(state.winid, { last_line_num, 0 })
          end)
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

  -- vim.api.nvim_create_autocmd("InsertEnter", {
  --   buffer = state.bufnr,
  --   callback = function()
  --     -- 直接設置游標，不使用 vim.schedule，以嘗試立即生效
  --     -- 確保視窗和緩衝區仍然有效
  --     if state.winid and vim.api.nvim_win_is_valid(state.winid) and state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
  --       local last_line_num = vim.api.nvim_buf_line_count(state.bufnr)
  --       -- 將游標設置到最後一行的末尾
  --       -- 使用一個非常大的列號 (e.g., 9999) 來表示行尾
  --       vim.api.nvim_win_set_cursor(state.winid, { last_line_num, 9999 })
  --     end
  --   end,
  --   desc = "Move cursor to the end of the last line on entering insert mode",
  -- })
end

---Initializes the Aider terminal buffer and window.
---@return nil
local function initialize_terminal()
  -- local current_win_heigh = vim.api.nvim_win_get_height(0)
  -- local current_win_width = vim.api.nvim_win_get_width(0)
  --
  -- local split = "below"
  -- if current_win_width > 160 then
  --   split = "right"
  -- end

  local win_config = {
    split = "right",
    win = 0,
    -- width = math.floor(vim.o.columns * 0.5), -- 設置合適的初始寬度
    -- height = math.floor(vim.o.lines * 0.3),
  }

  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "prompt" -- 將緩衝區類型設置為 prompt
  vim.bo[state.bufnr].filetype = "aider" -- 設置文件類型
  state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
  vim.api.nvim_set_current_win(state.winid)

  vim.wo[state.winid].number = false
  vim.wo[state.winid].relativenumber = false
  vim.wo[state.winid].wrap = false
  -- 移除 sidescrolloff = 0，使用 Neovim 預設或用戶配置
  vim.cmd("startinsert")

  setup_keymaps()
  attach_buffer()
  setup_autocommands()
end

---Starts the Aider process in the terminal buffer.
---@return nil
local function start_aider()
  local aider_config = build_aider_config()
  -- jobstat not work in macOS
  -- state.job_id = vim.fn.jobstart("aider " .. aider_config, { term = true })
  -- termopen work in macOS and windows
  state.job_id = vim.fn.termopen("aider " .. aider_config)
end

---Starts the Aider terminal if it is not already running.
function M.start()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    -- Reset states before initializing new terminal
    terminal_events.reset_state()
    initialize_terminal()
    start_aider()
  end
end

---Send text to the aider buffer
---@param text string Text to send to aider
---@param enter boolean? Whether to send enter key after text (defaults to false)
---@return nil
function M.send(text, enter)
  M.start()
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
    -- Reset states before starting new terminal
    terminal_events.reset_state()
    M.start()
  elseif is_visible() then
    M.hide()
  else
    local win_config = {
      split = "right",
      win = 0,
    }
    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config or {})
    vim.api.nvim_set_current_win(state.winid)
    vim.cmd("startinsert")
  end
end

return M
