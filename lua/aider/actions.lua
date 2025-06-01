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
  tmux.send("/readonly")
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

return M
