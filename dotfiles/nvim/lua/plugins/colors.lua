return {
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        priority = 1000,
        config = function()
            require('catppuccin').setup({
                flavour = "mocha",
                auto_integrations = true,
            })
            vim.cmd.colorscheme "catppuccin"
        end,
    }
}
