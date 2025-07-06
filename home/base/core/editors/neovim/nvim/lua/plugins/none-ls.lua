-- Replace none-ls with conform.nvim for better compatibility

---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    -- Define formatters by filetype
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      go = { "goimports", "gofmt" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      terraform = { "terraform_fmt" },
      nix = { "alejandra" },
      sql = { "sqlfluff" },
      fennel = { "fnlfmt" },
    },
    -- Set up format on save
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
