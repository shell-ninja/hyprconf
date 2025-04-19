return {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        local nvimtree = require("nvim-tree")

        -- recommended settings from nvim-tree documentation
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        nvimtree.setup({
            view = {
                side = "right",
                relativenumber = true,
                float = {
                    enable = false,
                    quit_on_focus_loss = true,
                    open_win_config = {
                        relative = "editor",
                        border = "rounded",
                        width = 60,
                        height = 25,
                        row = 2,
                        col = math.floor((vim.o.columns - 50) / 2),
                    },
                },
            },
            actions = {
                open_file = {
                    quit_on_open = true, -- Keep nvim-tree open after selecting a file
                    window_picker = {
                        enable = false,  -- Disable window picker to avoid closing current file
                    },
                },
            },
            renderer = {
                indent_markers = {
                    enable = true,
                },
                icons = {
                    glyphs = {},
                },
            },
            filters = {
                custom = { ".DS_Store" },
            },
            git = {
                ignore = false,
            },
        })

        -- set keymaps
        local keymap = vim.keymap -- for conciseness

        keymap.set("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
        keymap.set("n", "<A-f>", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" })
        keymap.set("n", "<leader>c", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })
        keymap.set("n", "<leader>r", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })
    end,
}
