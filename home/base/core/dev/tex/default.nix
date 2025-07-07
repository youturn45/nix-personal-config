{
  config,
  pkgs,
  lib,
  ...
}: {
  # TeX Live with comprehensive package set
  home.packages = with pkgs; [
    # Full TeX Live distribution with most packages
    texlive.combined.scheme-full

    # Additional TeX tools
    texlab # Language server for LaTeX
    latexrun # Tool to build LaTeX documents
    rubber # Automated system for building LaTeX documents
    texstudio # LaTeX editor (GUI)

    # Document viewers
    zathura # Lightweight document viewer
    evince # GNOME document viewer

    # Image conversion tools for LaTeX
    imagemagick # Convert images for inclusion in documents
    ghostscript # PostScript interpreter
  ];

  # Configure environment variables for TeX
  home.sessionVariables = {
    # Set TEXMFHOME for user-specific TeX packages
    TEXMFHOME = "${config.home.homeDirectory}/.texmf";

    # Set default PDF viewer
    PDFVIEWER = "zathura";
  };

  # Create TeX directories
  home.activation.setupTex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/tex/latex
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/bibtex/bib
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/fonts
  '';

  # Configure Zathura for PDF viewing
  programs.zathura = {
    enable = true;
    options = {
      # Use catppuccin colors
      default-bg = "#1e1e2e";
      default-fg = "#cdd6f4";
      statusbar-bg = "#313244";
      statusbar-fg = "#cdd6f4";
      inputbar-bg = "#313244";
      inputbar-fg = "#cdd6f4";
      notification-bg = "#313244";
      notification-fg = "#cdd6f4";
      notification-error-bg = "#f38ba8";
      notification-error-fg = "#1e1e2e";
      notification-warning-bg = "#fab387";
      notification-warning-fg = "#1e1e2e";
      highlight-color = "#f9e2af";
      highlight-active-color = "#a6e3a1";
      completion-bg = "#313244";
      completion-fg = "#cdd6f4";
      completion-highlight-bg = "#45475a";
      completion-highlight-fg = "#cdd6f4";
      recolor-lightcolor = "#1e1e2e";
      recolor-darkcolor = "#cdd6f4";
      recolor = true;
      recolor-keephue = true;
    };
  };

  # Shell aliases for common TeX operations
  home.shellAliases = {
    # Clean LaTeX auxiliary files
    texclean = "rm -f *.aux *.log *.out *.toc *.nav *.snm *.vrb *.fls *.fdb_latexmk *.synctex.gz";

    # Quick compile and view (using full path to avoid recursion)
    texview = "pdflatex -interaction=nonstopmode $1 && zathura \${1%.tex}.pdf";
  };
}
