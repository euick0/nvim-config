return {
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      only_first_definition = true, -- show a variable only where it's first defined
      all_references = false,       -- don't repeat it on every line that uses it
      highlight_changed_variables = true,
      virt_text_pos = "eol",
      display_callback = function(variable, _buf, stackframe, node, _options)
        -- node row is 0-based, stackframe.line is 1-based
        local row = node:range()
        if row >= stackframe.line then
          return nil -- skip lines after the current execution line
        end
        -- hide noisy values like `self`
        if variable.name == "self" then
          return nil
        end
        local value = variable.value:gsub("%s+", " ")
        if #value > 40 then
          value = value:sub(1, 37) .. "..."
        end
        return "  " .. variable.name .. " = " .. value
      end,
    },
    config = function(_, opts)
      require("nvim-dap-virtual-text").setup(opts)
      -- dim, italic look similar to VS Code inline values
      vim.api.nvim_set_hl(0, "NvimDapVirtualText", { link = "Comment", italic = true })
      vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = "#e5c07b", italic = true })
    end,
  },
}
