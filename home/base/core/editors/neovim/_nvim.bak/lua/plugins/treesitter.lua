-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    -- NOTE: additional parser
    { "nushell/tree-sitter-nu" }, -- nushell scripts
  },
  opts = function(_, opts)
    opts.incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>", -- Ctrl + Space
        node_incremental = "<C-space>",
        scope_incremental = "<A-space>", -- Alt + Space
        node_decremental = "<bs>", -- Backspace
      },
    }
    
    -- Disable auto-install since we use Nix treesitter.withAllGrammars
    opts.auto_install = false
    opts.ignore_install = { "gotmpl", "wing", "systemverilog" }
    
    -- Prevent systemverilog from being installed
    if opts.ensure_installed then
      opts.ensure_installed = vim.tbl_filter(function(lang)
        return lang ~= "systemverilog"
      end, opts.ensure_installed)
    end

    -- Clear ensure_installed since we get parsers from Nix
    opts.ensure_installed = {}
  end,
}
