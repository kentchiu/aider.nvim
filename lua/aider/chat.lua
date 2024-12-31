local M = {}

M.BUF_NAME = "AIDER_CHAT_BUF"

M.toggle = function() end

M.open = function()
  -- Try to find existing buffer first
  local buf = vim.fn.bufnr(M.BUF_NAME)
  
  -- If buffer doesn't exist, create it
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    
    -- Set buffer options
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_name(buf, M.BUF_NAME)
    
    -- Set <C-s> mapping for Aider Chat buffer
    vim.keymap.set("n", "<C-s>", function()
      -- Get entire buffer content
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      -- Concatenate content into a single string
      local content = table.concat(lines, "\n")
      -- Send content using AiderSend
      require("aider").send("{EOF\n" .. content .. "\nEOF}")
    end, {
      buffer = buf,
      desc = "Send chat content to Aider",
      silent = true,
    })
  end

  -- Get current window width
  local width = vim.api.nvim_get_option_value("columns", {})

  -- Calculate dimensions (40% of screen width)
  local win_width = math.floor(width * 0.4)

  -- Configure window options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = vim.api.nvim_get_option_value("lines", {}) - 4,
    row = 1,
    col = width - win_width,
    anchor = "NW",
    border = "rounded",
  }

  -- Create window with existing or new buffer
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set window options
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  return buf, win
end

--- Insert text into the Aider Chat buffer
---@param text string|string[] Text to insert (string or array of strings)
M.insert = function(text)
  -- Get or create the buffer and window
  local bufnr = M.open()

  -- Convert single string to table
  local lines = type(text) == "string" and { text } or text

  -- Get the last line number
  local last_line = vim.api.nvim_buf_line_count(bufnr)

  -- Insert text at the end of buffer
  vim.api.nvim_buf_set_lines(bufnr, last_line, last_line, false, lines)
end

return M
