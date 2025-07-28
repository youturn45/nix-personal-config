# Python/UV Configuration with NixOS Binary Wheel Compatibility
#
# This configuration solves the common NixOS issue where UV-installed binary wheels
# fail with "libstdc++.so.6: cannot open shared object file" errors.
#
# Key solutions implemented:
# 1. System libraries made available via LD_LIBRARY_PATH
# 2. Build tools (gcc, pkg-config) configured for package compilation
# 3. UV wrapper function ensures proper environment setup
# 4. Fallback to Nix packages for problematic scientific libraries
#
# Usage:
#   uv add numpy        # Should work with these fixes
#   test-numpy         # Test numpy import
#   test-scientific    # Test all scientific packages
#
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      # UV - fast Python package manager
      uv

      # Python runtime (minimal - UV will manage versions)
      python312

      # Keep essential system-level formatters that editors expect
      python312Packages.black
      python312Packages.ruff

      # Jupyter and ipykernel for SSH/remote development
      python312Packages.jupyter
      python312Packages.ipykernel
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # NixOS: System libraries needed for binary wheels
      stdenv.cc.cc.lib # Use this instead of gcc-unwrapped.lib to avoid collision
      glibc
      zlib
      libffi
      openssl
      bzip2
      xz
      ncurses
      readline
      sqlite
      tk
      expat
      libxml2
      libxslt

      # Scientific computing libraries
      blas
      lapack
      # Note: gfortran.cc.lib removed to avoid collision with stdenv.cc.cc.lib
    ];

  # UV configuration
  home.file.".config/uv/uv.toml".text = ''
    # Use system Python as base but allow UV to install others
    python-preference = "system"

    # Cache settings for faster installs
    cache-dir = "~/.cache/uv"

    # Default index URL (can be overridden per project)
    index-url = "https://pypi.org/simple"

    ${lib.optionalString pkgs.stdenv.isLinux ''
      # NixOS: Prefer building from source for better compatibility
      # This helps avoid binary wheel issues with system libraries
      compile-bytecode = true

      # Allow fallback to source builds when binary wheels fail
      no-binary-package = []
    ''}
  '';

  # Shell integration and aliases
  programs.zsh.shellAliases =
    {
      # UV project management
      uv-init = "uv init";
      uv-add = "uv add";
      uv-remove = "uv remove";
      uv-sync = "uv sync";
      uv-lock = "uv lock";
      uv-run = "uv run";
      uv-shell = "uv shell";

      # Python environment aliases (UV style)
      py = "uv run python";
      pip = "uv pip";
      python = "uv run python";

      # Data science shortcuts
      jupyter = "uv run jupyter";
      ipython = "uv run ipython";

      # Development tools
      black = "uv run black";
      ruff = "uv run ruff";
      mypy = "uv run mypy";
      pytest = "uv run pytest";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      # NixOS: Test scientific packages
      test-numpy = "uv run python -c \"import numpy; print('✅ numpy works:', numpy.__version__)\"";
      test-scipy = "uv run python -c \"import scipy; print('✅ scipy works:', scipy.__version__)\"";
      test-pandas = "uv run python -c \"import pandas; print('✅ pandas works:', pandas.__version__)\"";
      test-sklearn = "uv run python -c \"import sklearn; print('✅ scikit-learn works:', sklearn.__version__)\"";
      test-scientific = "uv run python -c \"import numpy, scipy, pandas, sklearn; print('✅ All scientific packages work!')\"";
    };

  # Environment variables for UV
  home.sessionVariables =
    {
      # UV cache directory
      UV_CACHE_DIR = "$HOME/.cache/uv";

      # UV configuration directory
      UV_CONFIG_DIR = "$HOME/.config/uv";

      # Prefer UV over pip
      UV_SYSTEM_PYTHON = "1";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      # NixOS: Make system libraries available to UV-installed packages
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib # Use this instead of gcc-unwrapped.lib to avoid collision
        pkgs.glibc
        pkgs.zlib
        pkgs.libffi
        pkgs.openssl
        pkgs.bzip2
        pkgs.xz
        pkgs.ncurses
        pkgs.readline
        pkgs.sqlite
        pkgs.tk
        pkgs.expat
        pkgs.libxml2
        pkgs.libxslt
        pkgs.blas
        pkgs.lapack
        # Note: gfortran.cc.lib removed to avoid collision with stdenv.cc.cc.lib
      ];

      # Additional environment variables for binary compatibility
      CC = "${pkgs.gcc}/bin/gcc";
      CXX = "${pkgs.gcc}/bin/g++";

      # PKG_CONFIG_PATH for building packages that need system libraries
      PKG_CONFIG_PATH = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
        pkgs.openssl
        pkgs.zlib
        pkgs.libffi
        pkgs.sqlite
        pkgs.expat
        pkgs.libxml2
        pkgs.libxslt
        pkgs.blas
        pkgs.lapack
      ];
    };

  # Shell initialization for UV
  programs.zsh.initContent = ''
    # UV shell completion
    if command -v uv &> /dev/null; then
      eval "$(uv generate-shell-completion zsh)"
    fi

    # Auto-activate UV environment if pyproject.toml exists
    uv_auto_activate() {
      if [[ -f "pyproject.toml" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
        if uv venv --quiet 2>/dev/null; then
          source .venv/bin/activate
        fi
      fi
    }

    # Add auto-activation to prompt command
    autoload -U add-zsh-hook
    add-zsh-hook chpwd uv_auto_activate

    ${lib.optionalString pkgs.stdenv.isLinux ''
      # NixOS: UV wrapper function to ensure proper library paths
      uv_nixos_wrapper() {
        # Ensure LD_LIBRARY_PATH is set for this UV session
        if [[ -z "$LD_LIBRARY_PATH" ]]; then
          export LD_LIBRARY_PATH="${lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.glibc
        pkgs.zlib
        pkgs.libffi
        pkgs.openssl
        pkgs.bzip2
        pkgs.xz
        pkgs.ncurses
        pkgs.readline
        pkgs.sqlite
        pkgs.tk
        pkgs.expat
        pkgs.libxml2
        pkgs.libxslt
        pkgs.blas
        pkgs.lapack
      ]}"
        fi

        # Run the actual UV command
        command uv "$@"
      }

      # Replace uv command with our wrapper
      alias uv=uv_nixos_wrapper
    ''}
  '';

  # Create a sample pyproject.toml template for new projects
  home.file.".config/uv/pyproject-template.toml".text = ''
    [build-system]
    requires = ["hatchling"]
    build-backend = "hatchling.build"

    [project]
    name = "my-project"
    version = "0.1.0"
    description = "A new Python project"
    authors = [
        {name = "Your Name", email = "your.email@example.com"},
    ]
    readme = "README.md"
    requires-python = ">=3.12"
    dependencies = []

    [project.optional-dependencies]
    dev = [
        "pytest>=7.0",
        "black>=23.0",
        "ruff>=0.1.0",
        "mypy>=1.0",
        "ipython>=8.0",
    ]

    data = [
        "numpy>=1.24",
        "pandas>=2.0",
        "matplotlib>=3.7",
        "seaborn>=0.12",
        "jupyter>=1.0",
        "scikit-learn>=1.3",
        "scipy>=1.11",
    ]

    # NixOS: Alternative data science setup using Nix packages
    # Use this if UV binary wheels continue to cause issues
    data-nix = [
        "jupyter>=1.0",
        "seaborn>=0.12",
        # Note: Use system numpy, scipy, pandas, sklearn from nixpkgs
        # Add these to your Nix configuration instead of installing via UV
    ]

    ml = [
        "torch>=2.0",
        "tensorflow>=2.13",
        "transformers>=4.20",
        "datasets>=2.0",
    ]

    [tool.ruff]
    line-length = 88
    target-version = "py312"

    [tool.ruff.lint]
    select = ["E", "F", "I", "N", "W", "UP"]
    ignore = ["E501", "W503"]

    [tool.black]
    line-length = 88
    target-version = ['py312']

    [tool.mypy]
    python_version = "3.12"
    strict = true
    ignore_missing_imports = true
  '';
}
