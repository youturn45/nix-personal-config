# NixVim Plugins and Configuration Guide

## Overview

This document provides comprehensive information about NixVim plugin configuration, particularly focusing on which-key and hydra mode functionality, along with lessons learned from implementing a fully-featured Neovim configuration.

## Table of Contents

1. [Which-Key Plugin](#which-key-plugin)
2. [Hydra Plugin](#hydra-plugin)
3. [Plugin Configuration Patterns](#plugin-configuration-patterns)
4. [Common Issues and Solutions](#common-issues-and-solutions)
5. [LSP Configuration](#lsp-configuration)
6. [Formatting and Completion](#formatting-and-completion)
7. [Best Practices](#best-practices)

## Which-Key Plugin

### Basic Configuration

```nix
which-key = {
  enable = true;
  settings = {
    preset = "modern";           # Use modern preset for better UI
    delay = 500;                 # Delay before showing popup (default)
    timeout = 3000;              # Timeout for key sequences
    win = {
      border = "rounded";        # Border style
      padding = { 2, 2, 2, 2 };  # Padding around popup
    };
  };
};
```

### Advanced Configuration with Key Groups

```nix
which-key = {
  enable = true;
  settings = {
    preset = "modern";
    spec = [
      {
        __unkeyed-1 = "<leader>f";
        group = "Find";
        icon = "🔍";
      }
      {
        __unkeyed-1 = "<leader>g";
        group = "Git";
        icon = "🌳";
      }
      {
        __unkeyed-1 = "<leader>c";
        group = "Code";
        icon = "💻";
      }
      {
        __unkeyed-1 = "<leader>t";
        group = "Terminal";
        icon = "📟";
      }
      {
        __unkeyed-1 = "<leader>w";
        group = "Window";
        icon = "🪟";
      }
    ];
  };
};
```

### Hydra Mode in Which-Key (Known Issues)

**Status**: Not recommended due to stability issues as of 2024.

The which-key plugin theoretically supports hydra mode with:
```lua
require("which-key").show({
  keys = "<C-w>",
  loop = true  -- Keeps popup open until <Esc>
})
```

However, this has known issues including:
- Recursion problems
- Nil value errors in modes field
- Inconsistent behavior across different configurations

## Hydra Plugin

### Overview

The dedicated hydra plugin provides a more robust solution for sticky key modes. It creates modal interfaces that stay active until explicitly exited.

### Basic Configuration

```nix
hydra = {
  enable = true;
  hydras = [
    {
      name = "example";
      body = "<leader>h";
      config = {
        color = "pink";          # Color theme: pink, red, blue, etc.
        invoke_on_body = true;   # Activate on body key press
        hint = {
          position = "bottom";   # Position: top, bottom, middle
          border = "rounded";    # Border style
        };
      };
      mode = "n";               # Vim mode: n, v, i, etc.
      hint = "Custom hint text";
      heads = [
        ["j" "next action" {desc = "Next";}]
        ["k" "prev action" {desc = "Previous";}]
        ["<Esc>" "nil" {exit = true; desc = "Exit";}]
      ];
    }
  ];
};
```

### Window Management Hydra

```nix
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
    ["<Esc>" "nil" {exit = true; desc = "Exit";}]
  ];
}
```

### Git Operations Hydra

```nix
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
    ["<Esc>" "nil" {exit = true; desc = "Exit";}]
  ];
}
```

## Plugin Configuration Patterns

### 1. Basic Plugin Enablement

```nix
# Simple enablement
plugin-name.enable = true;

# With basic settings
plugin-name = {
  enable = true;
  settings = {
    option1 = "value1";
    option2 = true;
  };
};
```

### 2. Complex Plugin Configuration

```nix
# Advanced configuration with nested settings
telescope = {
  enable = true;
  extensions = {
    fzf-native.enable = true;
    ui-select.enable = true;
  };
  settings = {
    defaults = {
      file_ignore_patterns = [".git/" "node_modules/"];
      mappings = {
        i = {
          "<C-u>" = false;
          "<C-d>" = false;
        };
      };
    };
  };
};
```

### 3. Using Raw Lua Code

```nix
# For complex Lua functions
keymaps = [
  {
    key = "<leader>example";
    action = {
      __raw = ''
        function()
          -- Complex Lua logic here
          local result = vim.fn.input("Enter value: ")
          vim.cmd("echo '" .. result .. "'")
        end
      '';
    };
    mode = "n";
    options.desc = "Example function";
  }
];
```

## Common Issues and Solutions

### 1. Deprecated Options

**Problem**: Plugin options change between versions.

**Examples**:
- `tsserver` → `ts_ls` (TypeScript LSP)
- `nvim-cmp` → `cmp` (Completion plugin)
- `lualine.theme` → `lualine.settings.options.theme`

**Solution**: Always check plugin documentation and nixvim updates.

### 2. Unfree Packages

**Problem**: Some plugins require unfree packages.

**Example**: `copilot-vim` requires `allowUnfree = true`.

**Solution**: 
```nix
# Comment out until allowUnfree is configured
# copilot-vim.enable = true;
```

### 3. Rust Analyzer Configuration

**Problem**: Rust analyzer tries to install cargo/rustc.

**Solution**:
```nix
rust_analyzer = {
  enable = true;
  installCargo = false;
  installRustc = false;
};
```

### 4. Icon Dependencies

**Problem**: Some plugins require explicit icon enablement.

**Solution**:
```nix
web-devicons.enable = true;
```

## LSP Configuration

### Basic LSP Setup

```nix
lsp = {
  enable = true;
  servers = {
    # Nix
    nil_ls.enable = true;
    
    # Lua
    lua_ls.enable = true;
    
    # Rust
    rust_analyzer = {
      enable = true;
      installCargo = false;
      installRustc = false;
    };
    
    # Python
    pyright.enable = true;
    
    # TypeScript/JavaScript
    ts_ls.enable = true;  # Note: renamed from tsserver
    
    # Bash
    bashls.enable = true;
    
    # Markdown
    marksman.enable = true;
  };
};
```

### LSP Keybindings

```nix
keymaps = [
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
    options.desc = "Hover documentation";
  }
  {
    key = "<Leader>ca";
    action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
    mode = "n";
    options.desc = "Code action";
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
```

## Formatting and Completion

### Conform.nvim (Formatting)

```nix
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
```

### Completion Setup

```nix
cmp = {
  enable = true;
  autoEnableSources = true;
  settings = {
    sources = [
      {name = "nvim_lsp";}
      {name = "luasnip";}
      {name = "buffer";}
      {name = "path";}
    ];
    mapping = {
      "<C-Space>" = "cmp.mapping.complete()";
      "<C-e>" = "cmp.mapping.abort()";
      "<CR>" = "cmp.mapping.confirm({ select = true })";
      "<Tab>" = "cmp.mapping.select_next_item()";
      "<S-Tab>" = "cmp.mapping.select_prev_item()";
    };
  };
};
```

## Best Practices

### 1. Incremental Development

Use the 7-step method for complex configurations:
1. Basic options
2. Colorscheme
3. Core plugins (treesitter)
4. Language support (LSP)
5. Completion & snippets
6. File management
7. Additional plugins

### 2. Build Testing

Always test configurations before applying:
```bash
just build-test    # Test build without switching
just safe-build    # Full safe build process
```

### 3. Documentation

- Keep configuration changes documented
- Use descriptive names for keybindings
- Comment deprecated options
- Document plugin-specific issues

### 4. Error Handling

- Check for deprecated options in plugin updates
- Test each plugin addition individually
- Use `just fmt` to maintain code formatting
- Monitor build output for warnings

### 5. Plugin Selection

- Prefer well-maintained plugins
- Check nixvim compatibility
- Consider plugin dependencies
- Test plugin interactions

## Conclusion

NixVim provides a powerful declarative approach to Neovim configuration. The key to success is:

1. **Incremental development** - Add features step by step
2. **Thorough testing** - Test each change before proceeding
3. **Documentation** - Keep track of configurations and issues
4. **Community resources** - Leverage nixvim documentation and examples

For hydra mode specifically, use the dedicated hydra plugin rather than which-key's hydra mode due to stability issues. The hydra plugin provides robust modal interfaces perfect for window management, git operations, and other repetitive tasks.