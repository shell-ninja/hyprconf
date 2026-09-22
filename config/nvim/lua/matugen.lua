 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#141316',
    base01 = '#211f23',
    base02 = '#2b292d',
    base03 = '#948e99',
    base04 = '#cbc4d0',
    base05 = '#e6e1e6',
    base06 = '#e6e1e6',
    base07 = '#e6e1e6',
    base08 = '#ffb4ab',
    base09 = '#f2b3e1',
    base0A = '#cdc2dd',
    base0B = '#d2bcfa',
    base0C = '#f2b3e1',
    base0D = '#d2bcfa',
    base0E = '#cdc2dd',
    base0F = '#eadefa',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e6e1e6',          bg = '#141316' })
  hi('TelescopeBorder',         { fg = '#948e99',             bg = '#141316' })
  hi('TelescopePromptNormal',   { fg = '#e6e1e6',          bg = '#141316' })
  hi('TelescopePromptBorder',   { fg = '#948e99',             bg = '#141316' })
  hi('TelescopePromptPrefix',   { fg = '#d2bcfa',             bg = '#141316' })
  hi('TelescopePromptCounter',  { fg = '#cbc4d0',  bg = '#141316' })
  hi('TelescopePromptTitle',    { fg = '#141316',             bg = '#d2bcfa' })
  hi('TelescopePreviewTitle',   { fg = '#141316',             bg = '#cdc2dd' })
  hi('TelescopeResultsTitle',   { fg = '#141316',             bg = '#f2b3e1' })
  hi('TelescopeSelection',      { fg = '#e6e1e6',          bg = '#2b292d' })
  hi('TelescopeSelectionCaret', { fg = '#d2bcfa',             bg = '#2b292d' })
  hi('TelescopeMatching',       { fg = '#d2bcfa',             bold = true })
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
