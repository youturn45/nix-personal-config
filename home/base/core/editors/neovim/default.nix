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
  # Enable NixVim
  programs.nixvim = {
    enable = true;
    
    # Use unstable neovim
    package = pkgs-unstable.neovim;
    
    # Default editor settings
    viAlias = true;
    vimAlias = true;
    
    # Global settings
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };
    
    # Vim options
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
      
      # UI
      termguicolors = true;
      signcolumn = "auto";
      spell = false;
      swapfile = false;
      title = true;
      titlelen = 20;
      
      # Clipboard
      clipboard = "unnamedplus";
      
      # Completion
      completeopt = ["menu" "menuone" "noselect"];
      
      # Split behavior
      splitbelow = true;
      splitright = true;
      
      # Folding
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldenable = false;
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
          rust_analyzer.enable = true;
          pyright.enable = true;
          tsserver.enable = true;
          bashls.enable = true;
          marksman.enable = true; # Markdown LSP
        };
      };
      
      # Completion
      nvim-cmp = {
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
      
      # Git
      gitsigns.enable = true;
      fugitive.enable = true;
      
      # Terminal
      toggleterm.enable = true;
      
      # Autopairs
      nvim-autopairs.enable = true;
      
      # Comments
      comment.enable = true;
      
      # Surround
      nvim-surround.enable = true;
      
      # Which-key
      which-key.enable = true;
      
      # Statusline
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
      
      # Bufferline
      bufferline.enable = true;
      
      # Indent guides
      indent-blankline.enable = true;
      
      # Markdown preview
      markdown-preview.enable = true;
      
      # Copilot
      copilot-vim.enable = true;
      
      # Undo tree
      undotree.enable = true;
      
      # Diagnostics
      trouble.enable = true;
      
      # Formatting
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = [ "alejandra" ];
            rust = [ "rustfmt" ];
            python = [ "black" ];
            javascript = [ "prettier" ];
            typescript = [ "prettier" ];
            json = [ "prettier" ];
            yaml = [ "prettier" ];
            markdown = [ "prettier" ];
            lua = [ "stylua" ];
          };
          format_on_save = {
            timeout_ms = 500;
            lsp_fallback = true;
          };
        };
      };
    };
    
    # Key mappings
    keymaps = [
      # Buffer navigation
      {
        key = "<Leader>bn";
        action = "<cmd>tabnew<cr>";
        mode = "n";
        options.desc = "New tab";
      }
      
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
      {
        key = "<Leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        mode = "n";
        options.desc = "Help tags";
      }
      
      # LSP
      {
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<cr>";
        mode = "n";
        options.desc = "Go to definition";
      }
      {
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<cr>";
        mode = "n";
        options.desc = "Go to references";
      }
      {
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<cr>";
        mode = "n";
        options.desc = "Hover";
      }
      {
        key = "<Leader>rn";
        action = "<cmd>lua vim.lsp.buf.rename()<cr>";
        mode = "n";
        options.desc = "Rename";
      }
      {
        key = "<Leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        mode = "n";
        options.desc = "Code action";
      }
      
      # Diagnostics
      {
        key = "<Leader>d";
        action = "<cmd>lua vim.diagnostic.open_float()<cr>";
        mode = "n";
        options.desc = "Open diagnostic float";
      }
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