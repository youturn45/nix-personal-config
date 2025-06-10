{ pkgs, ... }:
 let
   pyver = "312";
 in
 {
   home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenvwrapper
    python312Packages.kaggle
    python312Packages.ipython
    python312Packages.pytest
    python312Packages.black
    python312Packages.ruff
    python312Packages.mypy
    python312Packages.poetry-core

    # Data Science Core
    python312Packages.numpy
    python312Packages.pandas
    python312Packages.scipy
    python312Packages.scikit-learn
    python312Packages.matplotlib
    python312Packages.seaborn
    python312Packages.plotly
    python312Packages.jupyter
    python312Packages.jupyterlab
    python312Packages.notebook

    # Deep Learning
    python312Packages.torch
    python312Packages.torchvision
    python312Packages.torchaudio
    python312Packages.tensorflow
    python312Packages.keras

    # Data Processing & Analysis
    python312Packages.polars
    python312Packages.dask
    python312Packages.xarray
    python312Packages.statsmodels
    python312Packages.scikit-image

    # Visualization
    python312Packages.bokeh
    python312Packages.altair
    python312Packages.holoviews

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