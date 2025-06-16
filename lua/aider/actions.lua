local config = require("aider.config")
local tmux = require("aider.tmux")
local util = require("aider.util")

local M = {}

---@param message? string
function M.fix(message)
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

---@param content string
function M.send(content)
  if content then
    tmux.send(content)
  end
end

---@param opts? { direction: "left" | "right" | "up" | "down" }
function M.dialog(opts)
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

function M.add_file()
  local filename = vim.fn.expand("%:p")
  if filename and filename ~= "" then
    tmux.send("/add " .. filename)
  else
    vim.notify("無法獲取當前檔案名。", vim.log.levels.WARN)
  end
end

function M.add_files()
  local snacks = require("snacks")
  snacks.picker.pick({
    source = "files",
    title = "Select files to add",
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
  local filename = vim.fn.expand("%:p")
  if filename and filename ~= "" then
    tmux.send("/drop " .. filename)
  else
    vim.notify("無法獲取當前檔案名。", vim.log.levels.WARN)
  end
end

function M.readonly()
  local filename = vim.fn.expand("%:p")
  if filename and filename ~= "" then
    tmux.send("/read-only " .. filename)
  else
    vim.notify("無法獲取當前檔案名。", vim.log.levels.WARN)
  end
end

function M.yes()
  tmux.send("/yes")
end

function M.no()
  tmux.send("/no")
end

function M.models()
  local config_options = config.get()
  -- config_models is now a list of tables: {model=string, description=string}
  local config_models = config_options.models or {}
  local picker_items = {}
  for i, model_entry in ipairs(config_models) do
    table.insert(picker_items, {
      idx = i,
      model = model_entry.model, -- The actual model ID string
      description = model_entry.description, -- The description
      score = 0,
      -- 添加 'text' 字段，供 snacks.picker 內部用於匹配和過濾
      text = model_entry.description .. " (" .. model_entry.model .. ")",
    })
  end

  local snacks = require("snacks")
  snacks.picker.pick({
    title = "Select a Model",
    items = picker_items,
    format = function(item, _)
      return {
        { item.description, "String" },
        { " (", "Comment" },
        { item.model, "Identifier" },
        { ")", "Comment" },
      }
    end,
    preview = function(ctx)
      ctx.preview:set_lines({ ctx.item.model })
      -- return {
      --   { "model: ", "Comment" },
      --   { item.model, "Identifier" },
      --   { "description: ", "Comment" },
      --   { item.description, "String" },
      -- }
      return false
    end,
    confirm = function(picker, item, action)
      tmux.send("/model " .. item.model)
      picker:close()
    end,
  })
end

function M.history()
  local project_root_markers = { ".git" } -- 可以添加其他标记，如 .project_root_file
  local current_buf_path = vim.api.nvim_buf_get_name(0)
  local project_root_path =
    vim.fs.find(project_root_markers, { path = vim.fn.fnamemodify(current_buf_path, ":h"), upward = true })

  local history_file_path
  if project_root_path and #project_root_path > 0 then
    -- project_root_path 返回的是包含标记的目录列表，取第一个
    local root_dir = vim.fn.fnamemodify(project_root_path[1], ":h")
    history_file_path = root_dir .. "/.aider.input.history"
  else
    -- 如果找不到项目根目录，尝试使用用户主目录下的文件
    history_file_path = vim.fn.expand("~/.aider.input.history")
    vim.notify(
      "Project root not found. Falling back to history file in home directory: " .. history_file_path,
      vim.log.levels.WARN
    )
  end

  local lines = {}
  local file = io.open(history_file_path, "r")

  if not file then
    vim.notify("History file not found: " .. history_file_path, vim.log.levels.ERROR)
    return
  end

  local file_content = file:read("*a")
  file:close() -- Close file immediately after reading all content

  local current_command_buffer = {}
  local processing_command = false -- True if we are after a '#' line and collecting command lines

  -- Split the entire file content into lines for processing.
  -- {plain = true} ensures '\n' is treated literally.
  -- {trimempty = false} ensures that empty lines within a multi-line command are preserved.
  local file_lines_list = vim.split(file_content, "\n", { plain = true, trimempty = false })

  for _, line_text in ipairs(file_lines_list) do
    if line_text:match("^#") then -- Line starts with '#', indicating a new command block follows.
      if processing_command and #current_command_buffer > 0 then
        -- If there's a command in the buffer, process and add it.
        local cmd_str = table.concat(current_command_buffer, "\n")
        -- Trim leading/trailing whitespace from the entire multi-line command.
        cmd_str = cmd_str:gsub("^%s+", ""):gsub("%s+$", "")
        if cmd_str ~= "" then
          table.insert(lines, cmd_str)
        end
      end
      current_command_buffer = {} -- Reset buffer for the new command.
      processing_command = true -- Start collecting lines for the new command.
    elseif processing_command then
      -- If we are in a command block (after a '#'), add the line to the buffer.
      -- Remove leading '+' if present, as it's not part of the command itself.
      local processed_line = line_text
      if processed_line:match("^%+") then
        processed_line = processed_line:sub(2) -- Get substring from the second character onwards
      end
      table.insert(current_command_buffer, processed_line)
    end
  end

  -- After the loop, process any remaining command in the buffer (for the last command in the file).
  if processing_command and #current_command_buffer > 0 then
    local cmd_str = table.concat(current_command_buffer, "\n")
    cmd_str = cmd_str:gsub("^%s+", ""):gsub("%s+$", "")
    if cmd_str ~= "" then
      table.insert(lines, cmd_str)
    end
  end

  if #lines == 0 then
    vim.notify("No command history found in " .. history_file_path, vim.log.levels.INFO)
    return
  end

  local picker_items = {}
  for i, line_content in ipairs(lines) do
    table.insert(picker_items, {
      idx = i,
      text = line_content,
      command = line_content, -- Store the original command
      score = 0,
    })
  end

  local snacks = require("snacks")
  snacks.picker.pick({
    title = "Select a Command from History",
    items = picker_items,
    format = function(item, _)
      return {
        { item.text, "String" },
      }
    end,
    preview = function(ctx)
      ctx.preview:set_lines({ ctx.item.command })
      return false
    end,
    confirm = function(picker, item, _)
      if item and item.command then
        tmux.send(item.command)
      end
      picker:close()
    end,
  })
end

return M
