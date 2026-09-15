 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#231e1a',
    base01 = '#3b312b',
    base02 = '#362c26',
    base03 = '#716861',
    base04 = '#b6b2af',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#8f4e23',
    base09 = '#a1c171',
    base0A = '#c1b971',
    base0B = '#c99f83',
    base0C = '#c4d8a6',
    base0D = '#d8baa6',
    base0E = '#d8d3a6',
    base0F = '#e8e5ca',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f3f2f2',          bg = '#231e1a' })
  hi('TelescopeBorder',         { fg = '#716861',             bg = '#231e1a' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',          bg = '#231e1a' })
  hi('TelescopePromptBorder',   { fg = '#716861',             bg = '#231e1a' })
  hi('TelescopePromptPrefix',   { fg = '#c99f83',             bg = '#231e1a' })
  hi('TelescopePromptCounter',  { fg = '#b6b2af',  bg = '#231e1a' })
  hi('TelescopePromptTitle',    { fg = '#231e1a',             bg = '#c99f83' })
  hi('TelescopePreviewTitle',   { fg = '#231e1a',             bg = '#c1b971' })
  hi('TelescopeResultsTitle',   { fg = '#231e1a',             bg = '#a1c171' })
  hi('TelescopeSelection',      { fg = '#f3f2f2',          bg = '#362c26' })
  hi('TelescopeSelectionCaret', { fg = '#c99f83',             bg = '#362c26' })
  hi('TelescopeMatching',       { fg = '#c99f83',             bold = true })
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
