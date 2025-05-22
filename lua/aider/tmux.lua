local M = {}
local util = require("aider.util")

local aider_pane_id = nil ---@type string|nil Stores the selected Aider pane ID

--- Execute tmux command and handle the result
---@param cmd table The tmux command to execute
---@param error_msg string Error message to display on failure
---@return table|nil Result on success, nil on failure
local function execute_tmux_command(cmd, error_msg)
  util.log("Executing tmux command: " .. table.concat(cmd, " "), "DEBUG")
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 0 then
    return result
  end

  local errmsg = result.stderr ~= "" and result.stderr or result.stdout
  util.log(error_msg .. " Error code: " .. result.code .. ", Error: " .. vim.trim(errmsg), "ERROR")
  vim.notify(error_msg .. ": " .. vim.trim(errmsg), vim.log.levels.ERROR, { title = "Aider" })
  return nil
end

--- List tmux panes in the specified window
---@param window_id string The tmux window ID
---@return table|nil Panes info table or nil on error
local function list_panes(window_id)
  util.log("Listing panes for window ID: " .. window_id, "DEBUG")

  local cmd = {
    "tmux",
    "list-panes",
    "-t",
    window_id,
    "-F",
    "#{pane_id}:::#{pane_title}:::#{pane_current_command}",
  }

  local result = execute_tmux_command(cmd, "Error executing tmux list-panes command")
  if not result then
    return nil
  end

  local output = vim.trim(result.stdout)
  util.log("tmux list-panes output:\n" .. output, "DEBUG")

  if output == "" then
    util.log("No tmux panes found in window " .. window_id, "INFO")
    vim.notify("No tmux panes found in window " .. window_id, vim.log.levels.INFO, { title = "Aider" })
    return nil
  end

  -- Parse output into a list of panes
  local panes = {}

  for _, line in ipairs(vim.split(output, "\n", { plain = true, trimempty = true })) do
    local parts = vim.split(line, ":::", { plain = true })
    if #parts >= 3 then
      local pane_id = parts[1]
      local pane_title = parts[2] or ""
      local pane_command = parts[3] or ""

      if pane_id and string.sub(pane_id, 1, 1) == "%" then
        table.insert(panes, { id = pane_id, title = pane_title, command = pane_command })
      end
    end
  end

  if #panes == 0 then
    util.log("No valid tmux panes found in window " .. window_id, "WARN")
    vim.notify("No valid tmux panes found in window " .. window_id, vim.log.levels.WARN, { title = "Aider" })
    return nil
  end

  return panes
end

--- Get the current tmux window ID
---@return string|nil The current window ID, or nil on error
local function get_current_window_id()
  local tmux_env = vim.env.TMUX
  local tmux_pane_env = vim.env.TMUX_PANE

  if not tmux_env or not tmux_pane_env then
    util.log("Not running inside a tmux pane", "WARN")
    vim.notify("Not running inside a tmux pane", vim.log.levels.WARN, { title = "Aider" })
    return nil
  end

  local cmd = { "tmux", "display-message", "-p", "-t", tmux_pane_env, "#{window_id}" }
  local result = execute_tmux_command(cmd, "Error getting current tmux window ID")
  if not result then
    return nil
  end

  local window_id = vim.trim(result.stdout)
  if window_id == "" then
    util.log("Could not determine current tmux window ID", "ERROR")
    vim.notify("Could not determine current tmux window ID", vim.log.levels.ERROR, { title = "Aider" })
    return nil
  end

  util.log("Current tmux window ID: " .. window_id, "DEBUG")
  return window_id
end

--- Find the Aider pane ID
---@return boolean Whether an Aider pane was found
local function find_aider_pane_id()
  util.log("Attempting to find Aider pane ID", "DEBUG")

  local window_id = get_current_window_id()
  if not window_id then
    return false
  end

  local panes = list_panes(window_id)
  if not panes or #panes == 0 then
    return false
  end

  -- Automatically select pane containing "python"
  for _, pane_info in ipairs(panes) do
    if pane_info.command and string.match(pane_info.command:lower(), "python") then
      aider_pane_id = pane_info.id
      util.log("Found Aider pane ID: " .. aider_pane_id, "INFO")
      vim.notify("Selected Aider pane: " .. pane_info.id, vim.log.levels.INFO, { title = "Aider" })
      return true
    end
  end

  util.log("No Aider pane found", "DEBUG")
  return false
end

--- Send content to the specified tmux pane
---@param content string The content to send
---@param pane_id? string Target tmux pane ID, defaults to stored aider_pane_id
---@return boolean Whether content was successfully sent
function M.send(content, pane_id)
  -- Try to find Aider pane if not already set
  if not aider_pane_id and not pane_id then
    find_aider_pane_id()
  end

  local target_pane_id = pane_id or aider_pane_id

  -- Validate pane ID
  if not target_pane_id or target_pane_id == "" then
    util.log("No valid tmux pane ID available", "ERROR")
    vim.notify(
      "No valid tmux pane ID. Use :AiderStart first or provide a pane_id",
      vim.log.levels.ERROR,
      { title = "Aider" }
    )
    return false
  end

  -- Validate content
  if not content or content == "" then
    util.log("No content provided to send", "WARN")
    vim.notify("No content provided to send", vim.log.levels.WARN, { title = "Aider" })
    return true -- No error, just nothing to send
  end

  -- Use bracketed paste mode for proper handling of special characters
  local paste_data = "\27[200~" .. content .. "\27[201~"

  -- Send content and press Enter
  local paste_cmd = { "tmux", "send-keys", "-t", target_pane_id, paste_data }
  local enter_cmd = { "tmux", "send-keys", "-t", target_pane_id, "Enter" }

  if not execute_tmux_command(paste_cmd, "Error sending content to tmux pane") then
    return false
  end

  if not execute_tmux_command(enter_cmd, "Error sending Enter key to tmux pane") then
    return false
  end

  util.log("Content sent to tmux pane " .. target_pane_id, "INFO")
  return true
end

return M
