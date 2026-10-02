return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Leet",
    opts = {
      lang = "python3", -- or "cpp", "java", "javascript", "rust", etc.
    },
  },
}
