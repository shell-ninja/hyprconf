 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1f102d',
    base01 = '#331b4b',
    base02 = '#2e1844',
    base03 = '#696170',
    base04 = '#b3afb6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#cc6699',
    base0A = '#d65cd5',
    base0B = '#a667e4',
    base0C = '#e996bf',
    base0D = '#c093ec',
    base0E = '#e996e8',
    base0F = '#f4bef3',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1f102d' })
  hi('TelescopeBorder',         { fg = '#696170',             bg = '#1f102d' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1f102d' })
  hi('TelescopePromptBorder',   { fg = '#696170',             bg = '#1f102d' })
  hi('TelescopePromptPrefix',   { fg = '#a667e4',             bg = '#1f102d' })
  hi('TelescopePromptCounter',  { fg = '#b3afb6',  bg = '#1f102d' })
  hi('TelescopePromptTitle',    { fg = '#1f102d',             bg = '#a667e4' })
  hi('TelescopePreviewTitle',   { fg = '#1f102d',             bg = '#d65cd5' })
  hi('TelescopeResultsTitle',   { fg = '#1f102d',             bg = '#cc6699' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#2e1844' })
  hi('TelescopeSelectionCaret', { fg = '#a667e4',             bg = '#2e1844' })
  hi('TelescopeMatching',       { fg = '#a667e4',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
