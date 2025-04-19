return {
    {
        "akinsho/toggleterm.nvim",
        config = true,
        cmd = "ToggleTerm",
        keys = {
            { "<C-cr>", "<cmd>ToggleTerm<cr>", desc = "Toggle floating terminal" },
        },
        opts = {
            open_mapping = [[<C-cr>]],
            direction = "float",
            shade_filetypes = {},
            hide_numbers = true,
            insert_mappings = true,
            terminal_mappings = true,
            start_in_insert = true,
            close_on_exit = true,
        },
    },
}
