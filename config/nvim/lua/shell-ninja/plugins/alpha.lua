return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Set header
        dashboard.section.header.val = {
            "____ _  _ ____ _    _    _  _ 󰫢 _  _  _ ____  ",
            "[__  |__| |___ |    |    |\\ | | |\\ |  | |__|",
            "___] |  | |___ |___ |___ | \\| | | \\| _| |  |",
            "                                              ",
            "                       ×            ",
            "                      +++           ",
            "                      +++           ",
            "                     ×+++×          ",
            "            =+++++    +++    +++++× ",
            "              ++++++++++++++++++++  ",
            "               + ++++++ ++++++++    ",
            "                   ++++ +++++       ",
            "                 +++++++++++++      ",
            "              +++++++++++++++++++   ",
            "            ++++++    +++    ++++++ ",
            "                      ++++          ",
            "                      +++           ",
            "                      +++           ",
            "                       ×            ",
        }

        -- Colors (you can change these highlight groups)
        vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#6DCDED", bold = true })   -- gold/yellow
        vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#7FFFD4" })               -- aquamarine
        vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#FF69B4", italic = true }) -- pink

        -- Assign highlights
        dashboard.section.header.opts.hl = "AlphaHeader"
        dashboard.section.buttons.opts.hl = "AlphaButtons"
        dashboard.section.footer.opts.hl = "AlphaFooter"

        -- Set menu
        dashboard.section.buttons.val = {
            dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files<CR>"),
            dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
            dashboard.button("q", "  > Quit NVIM", "<cmd>qa<CR>"),
        }

        -- Send config to alpha
        alpha.setup(dashboard.opts)

        -- Disable folding on alpha buffer
        vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
    end,
}
