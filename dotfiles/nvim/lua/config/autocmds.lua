-- highlight when copying text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = "Highlight when copying text",
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- set tabs to 2 spaces for appropriate file types
local tab_group = vim.api.nvim_create_augroup("CustomTabWidths", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "lua", "javascript", "typescript",
    "html", "json", "xml", "yaml",
  },
  group = tab_group,
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- trim trailing whitespace before write
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" }, -- Apply to all file types
  callback = function(ev)
    -- Save cursor position to restore later
    local curpos = vim.api.nvim_win_get_cursor(0)

    -- Search and replace trailing whitespaces
    vim.cmd([[keeppatterns %s/\s\+$//e]])

    -- Restore cursor position
    vim.api.nvim_win_set_cursor(0, curpos)
  end,
})
