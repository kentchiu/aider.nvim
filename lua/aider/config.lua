---@class AiderConfig
---@field logger table
local M = {
  ---@type AiderConfig
  defaults = {
    logger = {
      level = "INFO", -- 預設日誌級別
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
