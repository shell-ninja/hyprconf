 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#0d1b30',
    base01 = '#162c50',
    base02 = '#132848',
    base03 = '#606770',
    base04 = '#afb2b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#a75ed4',
    base0A = '#695cd6',
    base0B = '#6797e4',
    base0C = '#c996e9',
    base0D = '#93b5ec',
    base0E = '#9f96e9',
    base0F = '#c4bef4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#0d1b30' })
  hi('TelescopeBorder',         { fg = '#606770',             bg = '#0d1b30' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#0d1b30' })
  hi('TelescopePromptBorder',   { fg = '#606770',             bg = '#0d1b30' })
  hi('TelescopePromptPrefix',   { fg = '#6797e4',             bg = '#0d1b30' })
  hi('TelescopePromptCounter',  { fg = '#afb2b6',  bg = '#0d1b30' })
  hi('TelescopePromptTitle',    { fg = '#0d1b30',             bg = '#6797e4' })
  hi('TelescopePreviewTitle',   { fg = '#0d1b30',             bg = '#695cd6' })
  hi('TelescopeResultsTitle',   { fg = '#0d1b30',             bg = '#a75ed4' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#132848' })
  hi('TelescopeSelectionCaret', { fg = '#6797e4',             bg = '#132848' })
  hi('TelescopeMatching',       { fg = '#6797e4',             bold = true })
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
