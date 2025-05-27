local config = require("aider.config")
local tmux = require("aider.tmux")
local util = require("aider.util")

local M = {}

---@param message string
function M.fix(message)
  tmux.send("/fix " .. message)
end

---@param content string
function M.send(content)
  tmux.send(content)
end

---@param opts? { direction: "left" | "right" | "up" | "down" }
function M.dialog(opts)
  local dialog = require("aider.dialog")
  dialog.toggle(opts)
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
