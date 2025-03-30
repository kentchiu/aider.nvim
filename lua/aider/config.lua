---@class AiderConfig
---@field logger table
local M = {
  ---@type AiderConfig
  defaults = {
    logger = {
      level = "INFO",
    },
  },

  ---@type AiderConfig
  options = {},
}

--- @param opts? AiderConfig
function M.setup(opts)
  local project_config = {}

  -- Try to load config from project root
  local config_path = vim.fn.findfile(".aider.conf.lua", ".;")
  if config_path ~= "" then
    local ok, config = pcall(dofile, config_path)
    if ok and type(config) == "table" then
      project_config = config
    end
  end

  -- Apply configs with precedence: project defaults < opts < project_config
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {}, project_config)
end

function M.get()
  return M.options
end

return M
