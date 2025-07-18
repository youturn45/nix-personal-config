{pkgs, ...}: {
  home.packages = with pkgs; [
    # UV - fast Python package manager
    uv

    # Python runtime (minimal - UV will manage versions)
    python312

    # Keep essential system-level formatters that editors expect
    python312Packages.black
    python312Packages.ruff
  ];

  # UV configuration
  home.file.".config/uv/uv.toml".text = ''
    # Use system Python as base but allow UV to install others
    python-preference = "system"

    # Cache settings for faster installs
    cache-dir = "~/.cache/uv"

    # Default index URL (can be overridden per project)
    index-url = "https://pypi.org/simple"
  '';

  # Shell integration and aliases
  programs.zsh.shellAliases = {
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
  };

  # Environment variables for UV
  home.sessionVariables = {
    # UV cache directory
    UV_CACHE_DIR = "$HOME/.cache/uv";

    # UV configuration directory
    UV_CONFIG_DIR = "$HOME/.config/uv";

    # Prefer UV over pip
    UV_SYSTEM_PYTHON = "1";
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
