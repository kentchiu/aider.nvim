---@class AiderConfig.Logger
---@field level string # 日誌級別 (例如 "INFO", "WARN", "ERROR", "OFF").

---@class AiderConfig
---@field logger AiderConfig.Logger # 日誌記錄器配置.
---@field models {model: string, description: string}[] # 常用模型列表.
local M = {
  --- 預設配置值。
  --- 如果未被用戶選項或專案特定配置覆蓋，則使用這些值。
  ---@type AiderConfig
  defaults = {
    logger = {
      level = "INFO", -- 預設日誌級別
    },
    -- 常用模型
    -- stylua: ignore
    models = {
      { model = "openrouter/openai/o3-mini", description = "o3-min" },
      { model = "openrouter/google/gemini-2.0-flash-001", description = "gemini 2.0 flash" },
      { model = "openrouter/google/gemini-2.0-flash-exp:free", description = "gemini 2.0 flash exp free" },
      { model = "openrouter/google/gemini-2.5-pro-exp-03-25", description = "gemini 2.5 pro exp 03-25" },
      { model = "openrouter/google/gemini-2.5-pro-preview-03-25", description = "gemini 2.5 pro preview 03-25" },
      { model = "vertex_ai-language-models/openrouter/google/gemini-2.5-pro-preview-03-25", description = "gemini 2.5 pro preview 03-25 (vertex)" },
      { model = "openrouter/google/gemini-2.5-pro-exp-03-25", description = "gemini 2.5 pro exp 03-25" },
      { model = "gemini/gemini-2.5-pro-preview-05-06", description = "gemini 2.5 pro preview 05-06" },
      { model = "gemini/gemini-2.5-pro-preview-06-05", description = "gemini 2.5 pro preview 06-05" },
      { model = "gemini/gemini-2.5-flash-preview-05-20", description = "gemini 2.5 flash preview 05-20" },
      { model = "openrouter/anthropic/claude-3.5-sonnet", description = "claude-3.5-sonnet" },
      { model = "openrouter/anthropic/claude-3.7-sonnet", description = "claude-3.7-sonnet" },
      { model = "openrouter/deepseek/deepseek-chat", description = "deepseek-chat" },
      { model = "openrouter/deepseek/deepseek-chat-v3-0324", description = "deepseek-chat-v3-0324" },
      { model = "openrouter/deepseek/deepseek-chat-v3-0324:free", description = "deepseek-chat-v3-0324:free" },
      { model = "openrouter/deepseek/deepseek-chat:free", description = "deepseek-chat:free" },
      { model = "openrouter/deepseek/deepseek-coder", description = "deepseek-coder" },
      { model = "openrouter/deepseek/deepseek-r1", description = "deepseek-r1" },
      { model = "openrouter/deepseek/deepseek-r1:free", description = "deepseek-r1:free" },
      { model = "openrouter/openai/gpt-4", description = "gpt-4" },
      { model = "openrouter/openai/gpt-4o", description = "gpt-4o" },
      { model = "openrouter/openai/gpt-4o-2024-05-13", description = "gpt-4o-2024-05-13" },
      { model = "openrouter/openai/gpt-4o-mini", description = "gpt-4o-mini" },
      { model = "openrouter/openai/o1", description = "o1" },
      { model = "openrouter/openai/o1-mini", description = "o1-mini" },
      { model = "openrouter/openai/o3-mini", description = "o3-mini" },
      { model = "openrouter/openai/o3-mini-high", description = "o3-mini-high" },
      { model = "openrouter/qwen/qwen-2.5-coder-32b-instruct", description = "qwen-2.5-coder-32b-instruct" },
    },
  },

  ---@type AiderConfig
  options = {},
}

--- @param opts? AiderConfig
function M.setup(opts)
  local project_config = {}
  local project_config_loaded = false -- 標記專案設定檔是否載入

  -- 嘗試從專案根目錄載入設定檔
  local config_path = vim.fn.findfile(".aider.conf.lua", ".;")
  if config_path ~= "" then
    local ok, config_module = pcall(dofile, config_path)
    if ok and type(config_module) == "table" then
      project_config = config_module
      project_config_loaded = true -- 成功載入
    else
      vim.notify("無法載入 .aider.conf.lua: " .. (config_module or "未知錯誤"), vim.log.levels.WARN)
    end
  end

  -- 步驟 1: 合併預設值和用戶傳入的 opts
  local base_config = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  -- 步驟 2: 根據是否載入專案設定檔決定最終設定
  if project_config_loaded then
    -- 如果載入了專案設定檔，則將其合併到基礎設定上 (專案設定優先)
    M.options = vim.tbl_deep_extend("force", base_config, project_config)
  else
    -- 如果未載入專案設定檔，使用基礎設定，並強制關閉日誌
    M.options = base_config
    -- 確保 logger 表存在
    if not M.options.logger then
      M.options.logger = {}
    end
    M.options.logger.level = "OFF" -- 強制關閉日誌
  end
end

function M.get()
  return M.options
end

return M
