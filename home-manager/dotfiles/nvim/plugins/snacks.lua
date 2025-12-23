return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          layout = {
            preset = "sidebar",
            preview = "main", -- This makes preview use the main window
            hidden = { "preview" },
          },
        },
      },
    },
  },
}
