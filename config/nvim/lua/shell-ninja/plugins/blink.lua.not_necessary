return {
    'saghen/blink.nvim',
    build = 'cargo build --release', -- for delimiters
    keys = {
        -- chartoggle
        {
            '<C-;>',
            function()
                require('blink.chartoggle').toggle_char_eol(';')
            end,
            mode = { 'n', 'v' },
            desc = 'Toggle ; at eol',
        },
        {
            ',',
            function()
                require('blink.chartoggle').toggle_char_eol(',')
            end,
            mode = { 'n', 'v' },
            desc = 'Toggle , at eol',
        },

        -- add missing imports (example key: <leader>mi)
        {
            '<leader>mi',
            function()
                vim.lsp.buf.code_action({
                    apply = true,
                    context = {
                        diagnostics = {},
                        only = { "source.addMissingImports.ts" },
                    },
                })
            end,
            mode = 'n',
            desc = 'Add missing imports (TS)',
        },

        -- tree
        { '<C-e>',     '<cmd>BlinkTree reveal<cr>',       desc = 'Reveal current file in tree' },
        { '<leader>E', '<cmd>BlinkTree toggle<cr>',       desc = 'Toggle file tree' },
        { '<leader>e', '<cmd>BlinkTree toggle-focus<cr>', desc = 'Toggle file tree focus' },
    },
    lazy = false,
    opts = {
        chartoggle = { enabled = true },
        indent = { enabled = true },
        tree = { enabled = true }
    }
}
