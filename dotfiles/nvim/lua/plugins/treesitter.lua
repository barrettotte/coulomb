return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  main = 'nvim-treesitter',
  opts = {
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
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    }
  },
}
