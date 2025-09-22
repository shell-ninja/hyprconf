-- Highlight and search TODO/FIX/NOTE/HACK in comments
return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
        require("todo-comments").setup({
            keywords = {
                fix = { icon = " ", color = "error", alt = { "FIXME", "BUG" } },
                todo = { icon = " ", color = "todo" },
                wrong = { icon = " ", color = "hack" },
                warning = { icon = " ", color = "warning" },
                note = { icon = " ", color = "note", alt = { "INFO" } },
            },
            colors = {
                error   = { "DiagnosticError", "ErrorMsg", "#f38ba8" },  -- red
                warning = { "DiagnosticWarn", "WarningMsg", "#f9e2af" }, -- yellow
                hack    = { "DiagnosticWarn", "WarningMsg", "#fab387" }, -- orange
                todo    = { "DiagnosticInfo", "#89b4fa" },               -- blue
                note    = { "DiagnosticHint", "#a6e3a1" },               -- green
            }
        })

        -- 🔎 Optional keymaps
        vim.keymap.set("n", "]t", function()
            require("todo-comments").jump_next()
        end, { desc = "Next TODO comment" })

        vim.keymap.set("n", "[t", function()
            require("todo-comments").jump_prev()
        end, { desc = "Previous TODO comment" })

        vim.keymap.set("n", "<leader>st", ":TodoTelescope<CR>", { desc = "Search TODOs in project" })
    end,
}
