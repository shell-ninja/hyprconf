return {
  'RRethy/base16-nvim',
  priority = 1001, -- Higher than catppuccin (1000) so this wins
  config = function()
    -- Apply Noctalia/matugen colors immediately on startup
    local ok, matugen = pcall(require, 'matugen')
    if ok then
      matugen.setup()
    end

    -- Re-apply after any colorscheme change (e.g. if catppuccin fires late)
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      once = true,
      callback = function()
        local ok2, m = pcall(require, 'matugen')
        if ok2 then m.setup() end
      end,
    })

    -- Also ensure we force our colorscheme if catppuccin somehow wins
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function()
        local ok2, m = pcall(require, 'matugen')
        if ok2 then m.setup() end
      end,
    })
  end,
}
