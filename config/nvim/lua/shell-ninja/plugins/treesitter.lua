return { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs", -- Sets main module to use for opts
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
        ensure_installed = {
            "lua",
            "python",
            "javascript",
            "typescript",
            "vimdoc",
            "vim",
            "regex",
            "terraform",
            "sql",
            "dockerfile",
            "toml",
            "json",
            "java",
            "groovy",
            "go",
            "gitignore",
            "graphql",
            "yaml",
            "make",
            "cmake",
            "markdown",
            "markdown_inline",
            "bash",
            "tsx",
            "css",
            "html",
        },
        auto_install = true,
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = { "ruby" },
        },
        indent = { enable = true, disable = { "ruby" } },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
                    ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
                    ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
                    ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

                    ["a:"] = { query = "@property.outer", desc = "Select outer part of an object property" },
                    ["i:"] = { query = "@property.inner", desc = "Select inner part of an object property" },
                    ["l:"] = { query = "@property.lhs", desc = "Select left part of an object property" },
                    ["r:"] = { query = "@property.rhs", desc = "Select right part of an object property" },

                    ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
                    ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

                    ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
                    ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

                    ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
                    ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

                    ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
                    ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

                    ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
                    ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

                    ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
                    ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ["<leader>na"] = "@parameter.inner",
                    ["<leader>n:"] = "@property.outer",
                    ["<leader>nm"] = "@function.outer",
                },
                swap_previous = {
                    ["<leader>pa"] = "@parameter.inner",
                    ["<leader>p:"] = "@property.outer",
                    ["<leader>pm"] = "@function.outer",
                },
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]f"] = { query = "@call.outer", desc = "Next function call start" },
                    ["]m"] = { query = "@function.outer", desc = "Next method/function def start" },
                    ["]c"] = { query = "@class.outer", desc = "Next class start" },
                    ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
                    ["]l"] = { query = "@loop.outer", desc = "Next loop start" },
                    ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
                    ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
                },
                goto_next_end = {
                    ["]F"] = { query = "@call.outer", desc = "Next function call end" },
                    ["]M"] = { query = "@function.outer", desc = "Next method/function def end" },
                    ["]C"] = { query = "@class.outer", desc = "Next class end" },
                    ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
                    ["]L"] = { query = "@loop.outer", desc = "Next loop end" },
                },
                goto_previous_start = {
                    ["[f"] = { query = "@call.outer", desc = "Prev function call start" },
                    ["[m"] = { query = "@function.outer", desc = "Prev method/function def start" },
                    ["[c"] = { query = "@class.outer", desc = "Prev class start" },
                    ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
                    ["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
                },
                goto_previous_end = {
                    ["[F"] = { query = "@call.outer", desc = "Prev function call end" },
                    ["[M"] = { query = "@function.outer", desc = "Prev method/function def end" },
                    ["[C"] = { query = "@class.outer", desc = "Prev class end" },
                    ["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
                    ["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
                },
            },
        },
    },
}
