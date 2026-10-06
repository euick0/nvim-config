-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  group = vim.api.nvim_create_augroup("autosave", { clear = true }),
  callback = function(args)
    local buf = args.buf
    -- only real, named, modifiable files that have changes
    if
      vim.bo[buf].buftype == ""
      and vim.bo[buf].modifiable
      and vim.bo[buf].modified
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! update")
      end)
    end
  end,
})
--- ===== leetcode.nvim: free buffer switching =====
local function unpin(win)
  win = win or vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) and vim.wo[win].winfixbuf then
    vim.wo[win].winfixbuf = false
  end
end

vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "winfixbuf",
  callback = function()
    if vim.wo.winfixbuf then
      vim.schedule(unpin)
    end
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TabEnter" }, {
  callback = function()
    unpin()
  end,
})

-- ===== leetcode.nvim: description follows the solution buffer =====
local leet_dir = vim.fn.stdpath("data") .. "/leetcode"

local function is_leet_solution(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name:find(leet_dir, 1, true) == 1 then
    return true
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 80, false)) do
    if line:match("^%s*%S+%s*@leet start%s*$") then
      return true
    end
  end
  return false
end
local function desc_wins()
  local wins = {}
  local cur = vim.api.nvim_get_current_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= cur and vim.api.nvim_win_get_config(w).relative == "" then
      local b = vim.api.nvim_win_get_buf(w)
      local ft = vim.bo[b].filetype
      local name = vim.api.nvim_buf_get_name(b):lower()
      if ft:find("^leetcode") or (vim.bo[b].buftype == "nofile" and name:find("leetcode", 1, true)) then
        table.insert(wins, w)
      end
    end
  end
  return wins
end
-- Tabs whose description was hidden by this autocmd (not by you)
local auto_hidden = {}

local group = vim.api.nvim_create_augroup("leet_desc_follow", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) or vim.api.nvim_get_current_buf() ~= args.buf then
        return
      end
      local tab = vim.api.nvim_get_current_tabpage()
      local wins = desc_wins()

      if is_leet_solution(args.buf) then
        if auto_hidden[tab] and #wins == 0 then
          local cur = vim.api.nvim_get_current_win()
          pcall(vim.cmd, "Leet desc")
          if #desc_wins() == 0 then
            pcall(vim.cmd, "Leet desc")
          end
          if vim.api.nvim_win_is_valid(cur) then
            vim.api.nvim_set_current_win(cur)
          end
        end
        auto_hidden[tab] = nil
      else
        local hid = false
        for _, w in ipairs(wins) do
          if #vim.api.nvim_tabpage_list_wins(0) > 1 then
            hid = pcall(vim.api.nvim_win_hide, w) or hid
          end
        end
        if hid then
          auto_hidden[tab] = true
        end
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("TabClosed", {
  group = group,
  callback = function()
    for tab in pairs(auto_hidden) do
      if not vim.api.nvim_tabpage_is_valid(tab) then
        auto_hidden[tab] = nil
      end
    end
  end,
})
