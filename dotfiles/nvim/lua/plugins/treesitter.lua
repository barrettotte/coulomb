return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
        local configs = require("nvim-treesitter.configs")
        configs.setup({
            highlight = { enable = true },
            indent = { enable = true },
            -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
            ensure_installed = {
                "asm",
                "bash",
                "c",
                "css",
                "go",
                "html",
                "javascript",
                "json",
                "lua",
                "make",
                "markdown",
                "python",
                "rust",
                "sql",
                "tcl",
                "typescript",
                "verilog",
                "vhdl",
                "vim",
                "vue",
                "xml",
                "yaml",
            },
            auto_install = false, -- don't auto-install new ones
        })
    end
}
