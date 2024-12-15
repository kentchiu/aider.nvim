vim.api.nvim_create_user_command("Aider", function(opts)
	local args
	if string.len(opts.args) > 0 then
		args = opts.args
	end
	print("🟥[17]: aider.lua:6: args=" .. vim.inspect(args))
	require("aider").start(args)
end, {
	nargs = "*",
	desc = "start aider",
})
