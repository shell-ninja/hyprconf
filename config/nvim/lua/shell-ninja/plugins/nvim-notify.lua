return {
    "rcarriga/nvim-notify",
    lazy = false,
    config = function()
        local notify = require("notify")

        notify.setup({
            stages = "fade",

            timeout = 2000,

            -- 🔥 Make it smaller
            max_width = 40, -- reduce width
            max_height = 3, -- reduce height

            render = "compact",

            -- 🔥 Bottom-right placement
            top_down = false,

            background_colour = "#1e222a",

            icons = {
                ERROR = "",
                WARN  = "",
                INFO  = "",
                DEBUG = "",
                TRACE = "✎",
            },
        })

        vim.notify = notify
    end,

    vim.keymap.set("n", "<leader>j", function()
        require("notify").dismiss({ silent = true })
    end, { desc = "Dismiss notifications" })
}
