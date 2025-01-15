local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0
if is_not_a_directory then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end

local snacks_dir = os.getenv("SNACKS_DIR") or "/tmp/snacks.nvim"
if vim.fn.isdirectory(snacks_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/folke/snacks.nvim.git", snacks_dir })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(snacks_dir)

vim.cmd("runtime plugin/plenary.vim")
vim.cmd("runtime plugin/snacks.lua")
require("plenary.busted")
