return {
  { 
    "NMAC427/guess-indent.nvim", -- detect tabstop and shiftwidth automatically
  },
  {
    "folke/todo-comments.nvim", -- highlight todo, notes, etc in comments
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },
  {
    "folke/which-key.nvim", -- show keybind hints
    event = "VimEnter",
    opts = { delay = 0 },
    spec = {
      { "<leader>s", group = "[S]earch" },
      { "<leader>t", group = "[T]oggle" },
    },
  },
  {
    'folke/noice.nvim', -- notifications / cmdline menu
    event = 'VeryLazy',
    opts = {},
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    }
  },
  {
    "brenoprata10/nvim-highlight-colors", -- show CSS colors
    config = function()
      require("nvim-highlight-colors").setup({})
    end
  },
  {
    "nvim-tree/nvim-web-devicons", -- provides NerdFont icons
    opts = {} 
  },
  {
    "echasnovski/mini.nvim", -- collection of various small independent plugins/modules
    config = function()
      -- Better Around/Inside textobjects
      --  va)  - [V]isually select [A]round [)]paren
      --  yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  ci'  - [C]hange [I]nside [']quote
      require("mini.ai").setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      -- saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- sd'   - [S]urround [D]elete [']quotes
      -- sr)'  - [S]urround [R]eplace [)] [']
      require("mini.surround").setup()

      -- Comment lines (gcc - toggle comment line)
      require("mini.comment").setup()

      -- Highlights trailing whitespaces
      require("mini.trailspace").setup()
    end,
  },
}
