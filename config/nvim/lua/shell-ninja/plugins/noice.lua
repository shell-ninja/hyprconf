return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    config = function()
        require("noice").setup({
            cmdline = {
                enabled = true,
                view = "cmdline_popup", -- use floating popup
                format = {
                    cmdline = { pattern = "^:", icon = "", lang = "vim", title = " COMMAND " },
                    search_down = { kind = "search", pattern = "^/", icon = "", lang = "regex", title = " SEARCH " },
                },
                format_insert = true,
            },
            popupmenu = {
                enabled = true,                      -- enable popupmenu for completions
                relative = "editor",                 -- relative to editor
                position = { row = 8, col = "50%" }, -- can tweak
                size = { width = 40, height = 10 },
                border = { style = "rounded", padding = { 0, 0 } },
                win_options = {
                    winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
                },
            },
            views = {
                cmdline_popup = {
                    border = {
                        style = "rounded",
                        padding = { 0, 0 },
                    },
                    position = {
                        row = "90%", -- vertical center
                        col = "50%", -- horizontal center
                    },
                    size = {
                        width = 40,
                        height = "auto",
                    },
                },
            },
            messages = {
                enabled = true,
                view_search = "virtualtext",
            },
            presets = {
                bottom_search = false,  -- disable classic bottom search
                command_palette = true, -- group cmdline + popupmenu together
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = true,
            },
        })
    end,
}
