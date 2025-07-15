{pkgs, ...}: {
  home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenvwrapper

    # Development tools
    python312Packages.ipython
    python312Packages.pytest
    python312Packages.black
    python312Packages.ruff
    python312Packages.mypy

    # Data Science Core
    python312Packages.numpy
    python312Packages.pandas
    python312Packages.scipy
    python312Packages.scikit-learn
    python312Packages.matplotlib
    python312Packages.seaborn
    python312Packages.jupyter
    python312Packages.notebook

    # Data Processing & Analysis
    python312Packages.statsmodels
    python312Packages.polars

    # Utilities
    python312Packages.tqdm
    python312Packages.requests
    python312Packages.pyyaml
    python312Packages.pillow
    python312Packages.openpyxl
    python312Packages.sqlalchemy
  ];

  programs.zsh.shellAliases = {
    # Virtual environment aliases
    mkv = "mkvirtualenv";
    rmv = "rmvirtualenv";
    lsv = "lsvirtualenv";
    wv = "workon";
    dv = "deactivate";
  };
}
