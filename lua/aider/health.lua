local M = {}

M.check = function()
	if vim.fn.executable("aider") == 0 then
		vim.health.error("adier not found")
	end

	vim.health.ok("aider found on path")

	local results = vim.system({ "aider", "--version" }, { text = true }):wait()

	if results.code ~= 0 then
		vim.health.error("failed to retrieve aider's version", results.stderr)
	end
	local stdout = results.stdout
	-- remove last char (newline) of stdout
	local version = stdout:sub(1, -2)
	vim.health.ok("aider version:" .. version)
end

return M
