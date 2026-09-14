# Python tooling: uv for projects, Nix for ambient tools
#
# Ownership split:
#   - Nix (here): uv itself and ruff for ad-hoc lint/format.
#   - uv (per project): pytest, mypy, pinned ruff, ipykernel — added with
#     `uv add --dev` and run through `uv run`. No pip anywhere.
#
# On NixOS, binary wheels need system libraries on LD_LIBRARY_PATH and
# uv-managed interpreters don't run unpatched, hence the Linux blocks below.
{
  pkgs-stable,
  lib,
  ...
}: {
  home.packages = with pkgs-stable;
    [
      uv
      ruff
    ]
    ++ lib.optionals pkgs-stable.stdenv.isLinux [
      # uv is configured to use the system interpreter on NixOS.
      python312

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
  home.file.".config/uv/uv.toml" = lib.mkIf pkgs-stable.stdenv.isLinux {
    text = ''
      python-preference = "system"
    '';
  };

  programs.zsh.shellAliases = lib.optionalAttrs pkgs-stable.stdenv.isLinux {
    # NixOS: Test scientific packages
    test-numpy = "uv run python -c \"import numpy; print('✅ numpy works:', numpy.__version__)\"";
    test-scipy = "uv run python -c \"import scipy; print('✅ scipy works:', scipy.__version__)\"";
    test-pandas = "uv run python -c \"import pandas; print('✅ pandas works:', pandas.__version__)\"";
    test-sklearn = "uv run python -c \"import sklearn; print('✅ scikit-learn works:', sklearn.__version__)\"";
    test-scientific = "uv run python -c \"import numpy, scipy, pandas, sklearn; print('✅ All scientific packages work!')\"";
  };

  home.sessionVariables = lib.optionalAttrs pkgs-stable.stdenv.isLinux {
    # NixOS: Make system libraries available to UV-installed packages
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs-stable.stdenv.cc.cc.lib # Use this instead of gcc-unwrapped.lib to avoid collision
      pkgs-stable.glibc
      pkgs-stable.zlib
      pkgs-stable.libffi
      pkgs-stable.openssl
      pkgs-stable.bzip2
      pkgs-stable.xz
      pkgs-stable.ncurses
      pkgs-stable.readline
      pkgs-stable.sqlite
      pkgs-stable.tk
      pkgs-stable.expat
      pkgs-stable.libxml2
      pkgs-stable.libxslt
      pkgs-stable.blas
      pkgs-stable.lapack
    ];

    # Additional environment variables for binary compatibility
    CC = "${pkgs-stable.gcc}/bin/gcc";
    CXX = "${pkgs-stable.gcc}/bin/g++";

    # PKG_CONFIG_PATH for building packages that need system libraries
    PKG_CONFIG_PATH = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
      pkgs-stable.openssl
      pkgs-stable.zlib
      pkgs-stable.libffi
      pkgs-stable.sqlite
      pkgs-stable.expat
      pkgs-stable.libxml2
      pkgs-stable.libxslt
      pkgs-stable.blas
      pkgs-stable.lapack
    ];
  };

  programs.zsh.initContent = ''
    # UV shell completion
    if command -v uv &> /dev/null; then
      eval "$(uv generate-shell-completion zsh)"
    fi
  '';
}
