{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
###############################################################################
#
#  NixVim configuration - migrated from AstroNvim
#
###############################################################################
let
  shellAliases = {
    v = "nvim";
    vdiff = "nvim -d";
  };
in {
  # NixVim configuration - Step 1: Basic options
  programs.nixvim = {
    enable = true;

    # Default editor settings
    viAlias = true;
    vimAlias = true;

    # Global settings
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    # Basic vim options
    opts = {
      # Line numbers
      number = true;
      relativenumber = true;

      # Indentation
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smartindent = true;

      # Search
      ignorecase = true;
      smartcase = true;
      hlsearch = true;

      # UI basics
      termguicolors = true;
      signcolumn = "auto";

      # File handling
      swapfile = false;

      # Clipboard
      clipboard = "unnamedplus";
    };

    # Colorscheme
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
      };
    };

    # Essential plugins
    plugins = {
      # Core functionality
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          fold.enable = true;
        };
      };

      # LSP
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true; # Nix LSP
          lua_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false; # We have rustfmt in system packages
            installRustc = false;
          };
          pyright.enable = true;
          ts_ls.enable = true; # Renamed from tsserver
          bashls.enable = true;
          marksman.enable = true; # Markdown LSP
        };
      };

      # Completion
      cmp = {
        enable = true;
        autoEnableSources = true;
      };

      # Snippets
      luasnip.enable = true;

      # File explorer
      neo-tree.enable = true;

      # Telescope
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
      };

      # Icons (explicitly enabled to remove warning)
      web-devicons.enable = true;

      # Additional plugins
      gitsigns.enable = true;
      fugitive.enable = true;
      toggleterm.enable = true;
      nvim-autopairs.enable = true;
      comment.enable = true;
      nvim-surround.enable = true;
      which-key.enable = true;
      undotree.enable = true;
      trouble.enable = true;

      # UI plugins
      lualine = {
        enable = true;
        settings.options.theme = "catppuccin";
      };
      bufferline.enable = true;
      indent-blankline.enable = true;

      # Additional functionality
      markdown-preview.enable = true;
      # Note: copilot-vim requires allowUnfree = true
      # copilot-vim.enable = true;

      # Formatting (conform-nvim)
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = ["alejandra"];
            rust = ["rustfmt"];
            python = ["black"];
            javascript = ["prettier"];
            typescript = ["prettier"];
            json = ["prettier"];
            yaml = ["prettier"];
            markdown = ["prettier"];
            lua = ["stylua"];
          };
          format_on_save = {
            timeout_ms = 500;
            lsp_fallback = true;
          };
        };
      };
    };

    # Essential keymaps
    keymaps = [
      # Neo-tree
      {
        key = "<Leader>e";
        action = "<cmd>Neotree toggle<cr>";
        mode = "n";
        options.desc = "Toggle Neo-tree";
      }

      # Telescope
      {
        key = "<Leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        mode = "n";
        options.desc = "Find files";
      }
      {
        key = "<Leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        mode = "n";
        options.desc = "Live grep";
      }
      {
        key = "<Leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        mode = "n";
        options.desc = "Find buffers";
      }

      # LSP keymaps
      {
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
        mode = "n";
        options.desc = "Go to definition";
      }
      {
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<cr>";
        mode = "n";
        options.desc = "Hover";
      }
      {
        key = "<Leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        mode = "n";
        options.desc = "Code action";
      }

      # Diagnostics
      {
        key = "[d";
        action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        mode = "n";
        options.desc = "Previous diagnostic";
      }
      {
        key = "]d";
        action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        mode = "n";
        options.desc = "Next diagnostic";
      }
    ];
  };

  # Shell aliases
  home.shellAliases = shellAliases;
  programs.nushell.shellAliases = shellAliases;
}
