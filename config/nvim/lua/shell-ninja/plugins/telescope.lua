return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
        "folke/trouble.nvim",
    },
    keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Fuzzy find files in cwd" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Fuzzy find recent files" },
        { "<leader>fs", "<cmd>Telescope live_grep<cr>", desc = "Find string in cwd" },
        { "<leader>fc", "<cmd>Telescope grep_string<cr>", desc = "Find string under cursor in cwd" },
        { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find todos" },
        {
            "<leader>fg",
            function()
                require("telescope.builtin").live_grep({
                    prompt_title = "Global Search (Word)",
                    cwd = vim.fn.expand("%:p:h"), -- Search from the current file's directory
                })
            end,
            desc = "Global search in directory",
        },
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local transform_mod = require("telescope.actions.mt").transform_mod

        local trouble = require("trouble")
        local trouble_telescope = require("trouble.sources.telescope")

        -- or create your custom action
        local custom_actions = transform_mod({
            open_trouble_qflist = function(prompt_bufnr)
                trouble.toggle("quickfix")
            end,
        })

        telescope.setup({
            defaults = {
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        -- ["<C-j>"] = actions.move_selection_next,     -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
                        ["<C-t>"] = trouble_telescope.open,
                        ["<C-v>"] = actions.select_vertical, -- open in vertical split
                    },
                },
            },
        })

        telescope.load_extension("fzf")
    end,
}
