return {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPre", "BufNewFile" }, -- optional: lazy load on file open
    config = function()
        require("nvim-highlight-colors").setup({
            render = "background",      -- "foreground" | "first_column"
            enable_named_colors = true, -- Enable color names like 'red'
            enable_tailwind = true,     -- Enable Tailwind CSS colors
        })
    end,
}
