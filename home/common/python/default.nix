# Python tooling: uv for projects, Nix for ambient tools
#
# Ownership split:
#   - Nix (here): uv itself, ruff for ad-hoc lint/format, and a Python with
#     the JupyterLab stack for SSH/remote notebook serving.
#   - uv (per project): pytest, mypy, pinned ruff, ipykernel — added with
#     `uv add --dev` and run through `uv run`. No pip anywhere.
#
# On NixOS, binary wheels need system libraries on LD_LIBRARY_PATH and
# uv-managed interpreters don't run unpatched, hence the Linux blocks below.
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      uv
      ruff

      (python312.withPackages (ps:
        with ps; [
          # Jupyter server for SSH/remote development; projects register
          # their own kernels via `uv run python -m ipykernel install`
          jupyterlab
          jupyter-client
          ipykernel # plain global kernel, sees only this environment
          ipython
        ]))
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
    ];

  # NixOS: uv's managed interpreters are dynamically linked against paths
  # that don't exist on NixOS, so venvs must build on the Nix Python.
  # Darwin uses uv's default (managed) interpreters, which survive Nix
  # rebuilds and garbage collection.
  home.file.".config/uv/uv.toml" = lib.mkIf pkgs.stdenv.isLinux {
    text = ''
      python-preference = "system"
    '';
  };

  programs.zsh.shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
    # NixOS: Test scientific packages
    test-numpy = "uv run python -c \"import numpy; print('✅ numpy works:', numpy.__version__)\"";
    test-scipy = "uv run python -c \"import scipy; print('✅ scipy works:', scipy.__version__)\"";
    test-pandas = "uv run python -c \"import pandas; print('✅ pandas works:', pandas.__version__)\"";
    test-sklearn = "uv run python -c \"import sklearn; print('✅ scikit-learn works:', sklearn.__version__)\"";
    test-scientific = "uv run python -c \"import numpy, scipy, pandas, sklearn; print('✅ All scientific packages work!')\"";
  };

  home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux {
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

  programs.zsh.initContent = ''
    # UV shell completion
    if command -v uv &> /dev/null; then
      eval "$(uv generate-shell-completion zsh)"
    fi
  '';
}
