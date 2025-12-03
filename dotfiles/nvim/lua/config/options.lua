vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 10 -- min number of lines to keep above/below the cursor
vim.opt.confirm = true -- raise dialog to save file if operation would fail due to unsaved changes in buffer
vim.opt.showmatch = true -- show matching brackets/parenthesis
vim.opt.wrap = false -- no line wrap
vim.opt.cmdheight = 1

vim.opt.shiftwidth = 4 -- size of an indent
vim.opt.tabstop = 4 -- number of spaces tabs count for
vim.opt.softtabstop = 4 -- number of spaces in tab when editing
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- syntax aware indentations for newline inserts
vim.opt.breakindent = true -- wrapped text respects indentation level of line it belongs to

-- undo history
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- case insensitive search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true

-- show invisibles
vim.opt.listchars = { tab = "  ", trail = "·", extends = "»", precedes = "«", nbsp = "░" }
vim.opt.list = true

-- sync clipboard between OS and neovim
vim.schedule(function()
    vim.opt.clipboard = "unnamedplus"
end)
