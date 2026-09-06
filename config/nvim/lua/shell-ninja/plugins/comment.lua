-- Easily comment visual regions/lines
return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  keys = {
    {
      "<C-_>",
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      mode = "n",
      desc = "Toggle comment line (Ctrl+/)",
    },
    {
      "<C-/>",
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      mode = "n",
      desc = "Toggle comment line (Ctrl+/)",
    },
    {
      "<C-_>",
      function()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end,
      mode = { "v", "x" },
      desc = "Toggle comment visual (Ctrl+/)",
    },
    {
      "<C-/>",
      function()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end,
      mode = { "v", "x" },
      desc = "Toggle comment visual (Ctrl+/)",
    },
  },
  config = function()
    -- Setup ts_context_commentstring first (no autocmd needed, Comment.nvim calls pre_hook)
    require("ts_context_commentstring").setup({
      enable_autocmd = false,
    })

    local ts_pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
    local ft = require("Comment.ft")

    -- Guard against Neovim 0.12+ nil parser bug where treesitter get_parser returns nil
    -- instead of erroring, which causes Comment.nvim's internal calculate to crash with nil:children()
    local orig_calculate = ft.calculate
    ft.calculate = function(ctx)
      local ok, parser = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
      if not ok or not parser then
        return ft.get(vim.bo.filetype, ctx.ctype)
      end
      return orig_calculate(ctx)
    end

    require("Comment").setup({
      -- Safe pre_hook: use treesitter commentstring for embedded languages (JSX/TSX, HTML/Vue, etc.),
      -- and fallback directly to Comment.ft or vim.bo.commentstring for normal files (bash, python, etc.)
      pre_hook = function(ctx)
        local ok, result = pcall(ts_pre_hook, ctx)
        if ok and result then
          return result
        end
        return ft.get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
      end,
    })

    local api = require("Comment.api")
    local opts = { noremap = true, silent = true }
    local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    local toggle_visual = function()
      vim.api.nvim_feedkeys(esc, "nx", false)
      api.toggle.linewise(vim.fn.visualmode())
    end

    -- Normal mode: toggle current line (works from anywhere on the line)
    vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, opts)
    vim.keymap.set("n", "<C-/>", api.toggle.linewise.current, opts)

    -- Visual mode: toggle selected lines
    vim.keymap.set("v", "<C-_>", toggle_visual, opts)
    vim.keymap.set("v", "<C-/>", toggle_visual, opts)
    vim.keymap.set("x", "<C-_>", toggle_visual, opts)
    vim.keymap.set("x", "<C-/>", toggle_visual, opts)
  end,
}
