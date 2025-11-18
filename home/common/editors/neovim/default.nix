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
      which-key = {
        enable = true;
        settings = {
          preset = "modern";
        };
      };
      undotree.enable = true;
      trouble.enable = true;

      # Hydra plugin for sticky key modes
      hydra = {
        enable = true;
        hydras = [
          {
            name = "window";
            body = "<leader>w";
            config = {
              color = "pink";
              invoke_on_body = true;
              hint = {
                position = "bottom";
                border = "rounded";
              };
            };
            mode = "n";
            hint = ''
              Window Management
              _h_: left   _j_: down   _k_: up   _l_: right
              _H_: resize left   _J_: resize down   _K_: resize up   _L_: resize right
              _s_: split horizontal   _v_: split vertical   _q_: close
              _<Esc>_: exit
            '';
            heads = [
              ["h" "<C-w>h" {desc = "Move left";}]
              ["j" "<C-w>j" {desc = "Move down";}]
              ["k" "<C-w>k" {desc = "Move up";}]
              ["l" "<C-w>l" {desc = "Move right";}]
              ["H" "<C-w>5<" {desc = "Resize left";}]
              ["J" "<C-w>5-" {desc = "Resize down";}]
              ["K" "<C-w>5+" {desc = "Resize up";}]
              ["L" "<C-w>5>" {desc = "Resize right";}]
              ["s" "<C-w>s" {desc = "Split horizontal";}]
              ["v" "<C-w>v" {desc = "Split vertical";}]
              ["q" "<C-w>q" {desc = "Close window";}]
              [
                "<Esc>"
                "nil"
                {
                  exit = true;
                  desc = "Exit";
                }
              ]
            ];
          }
          {
            name = "git";
            body = "<leader>g";
            config = {
              color = "red";
              invoke_on_body = true;
              hint = {
                position = "bottom";
                border = "rounded";
              };
            };
            mode = "n";
            hint = ''
              Git Operations
              _j_: next hunk   _k_: prev hunk   _s_: stage hunk
              _u_: undo stage  _p_: preview     _b_: blame line
              _d_: diff this   _S_: stage buffer _<Esc>_: exit
            '';
            heads = [
              ["j" {__raw = "function() require('gitsigns').next_hunk() end";} {desc = "Next hunk";}]
              ["k" {__raw = "function() require('gitsigns').prev_hunk() end";} {desc = "Previous hunk";}]
              ["s" {__raw = "function() require('gitsigns').stage_hunk() end";} {desc = "Stage hunk";}]
              ["u" {__raw = "function() require('gitsigns').undo_stage_hunk() end";} {desc = "Undo stage";}]
              ["p" {__raw = "function() require('gitsigns').preview_hunk() end";} {desc = "Preview hunk";}]
              ["b" {__raw = "function() require('gitsigns').blame_line() end";} {desc = "Blame line";}]
              ["d" {__raw = "function() require('gitsigns').diffthis() end";} {desc = "Diff this";}]
              ["S" {__raw = "function() require('gitsigns').stage_buffer() end";} {desc = "Stage buffer";}]
              [
                "<Esc>"
                "nil"
                {
                  exit = true;
                  desc = "Exit";
                }
              ]
            ];
          }
        ];
      };

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
