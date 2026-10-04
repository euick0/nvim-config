return {
  "theHamsta/nvim-dap-virtual-text",
  opts = {
    only_first_definition = false, -- show at every assignment, not just the first
    all_references = true,         -- show at every line where the variable is used
    virt_text_pos = "eol",
  },
}
