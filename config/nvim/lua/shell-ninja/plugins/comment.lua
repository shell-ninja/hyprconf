-- Easily comment visual regions/lines
return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  config = function()
    -- import comment plugin safely
    local comment = require("Comment")

    local ts_context_commentstring = require("ts_context_commentstring")
    ts_context_commentstring.setup({
      enable_autocmd = false,
    })

    local comment_integration = require("ts_context_commentstring.integrations.comment_nvim")

    local ts_pre_hook = comment_integration.create_pre_hook()

    -- enable comment
    comment.setup({
      -- for commenting tsx, jsx, svelte, html files
      -- wrap pre_hook to prevent [Comment.nvim] nil warning when
      -- ts_context_commentstring returns nil (e.g. html, css filetypes)
      pre_hook = function(ctx)
        return ts_pre_hook(ctx) or require("Comment.utils").get_cstring(ctx, true)
      end,
    })

    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<C-_>", require("Comment.api").toggle.linewise.current, opts)
    vim.keymap.set("n", "<C-c>", require("Comment.api").toggle.linewise.current, opts)
    vim.keymap.set("n", "<C-/>", require("Comment.api").toggle.linewise.current, opts)
    vim.keymap.set("v", "<C-_>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set("v", "<C-c>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
    vim.keymap.set("v", "<C-/>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
  end,
}
