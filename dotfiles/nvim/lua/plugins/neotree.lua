return {
    'nvim-neo-tree/neo-tree.nvim',
    version = 'v3.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'MunifTanjim/nui.nvim',
    },
    lazy = false,
    opts = {
        filesystem = {
            follow_current_file = { enabled = true },
            bind_to_cwd = false,
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = false,
            },
        },
    },
}