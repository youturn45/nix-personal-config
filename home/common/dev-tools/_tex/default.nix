{
  config,
  pkgs,
  lib,
  ...
}: let
  # Define fonts to make available in TEXMF
  # These match the fonts defined in modules/common/fonts.nix
  texFonts = with pkgs; [
    # Nerd Fonts for coding
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.space-mono
    maple-mono.NF-CN-unhinted

    # Source fonts with Chinese support
    source-sans
    source-serif
    source-han-sans
    source-han-serif

    # Google Noto CJK fonts - comprehensive Chinese/Japanese/Korean support
    noto-fonts-cjk-sans # 思源黑体 (Google's version)
    noto-fonts-cjk-serif # 思源宋体 (Google's version)

    # Additional Chinese fonts
    shanggu-fonts # 上古字体 - archaic Chinese characters

    # Icon fonts
    material-design-icons
    font-awesome
  ];

  # Script to symlink fonts from Nix store to TEXMF
  linkFontsScript = let
    homeDir = config.home.homeDirectory;
    texmfFonts = "${homeDir}/.texmf/fonts";
  in ''
    # Remove old font symlinks to prevent stale links
    if [ -d "${texmfFonts}/truetype" ]; then
      $DRY_RUN_CMD rm -rf ${texmfFonts}/truetype/*
    fi
    if [ -d "${texmfFonts}/opentype" ]; then
      $DRY_RUN_CMD rm -rf ${texmfFonts}/opentype/*
    fi

    # Create font directories
    $DRY_RUN_CMD mkdir -p ${texmfFonts}/truetype
    $DRY_RUN_CMD mkdir -p ${texmfFonts}/opentype

    # Symlink each font package to TEXMF
    ${lib.concatMapStringsSep "\n" (font: ''
        # Look for TrueType fonts (handle nested directories)
        if [ -d "${font}/share/fonts/truetype" ]; then
          find "${font}/share/fonts/truetype" -mindepth 1 -type d | while read -r fontdir; do
            # Get relative path from truetype directory
            relpath="''${fontdir#${font}/share/fonts/truetype/}"
            targetdir="${texmfFonts}/truetype/''${relpath}"

            # Create parent directory if needed
            $DRY_RUN_CMD mkdir -p "$(dirname "$targetdir")"

            # Symlink the directory
            if [ ! -e "$targetdir" ]; then
              $DRY_RUN_CMD ln -sf "$fontdir" "$targetdir" 2>/dev/null || true
            fi
          done
        fi

        # Look for OpenType fonts (handle nested directories)
        if [ -d "${font}/share/fonts/opentype" ]; then
          find "${font}/share/fonts/opentype" -mindepth 1 -type d | while read -r fontdir; do
            # Get relative path from opentype directory
            relpath="''${fontdir#${font}/share/fonts/opentype/}"
            targetdir="${texmfFonts}/opentype/''${relpath}"

            # Create parent directory if needed
            $DRY_RUN_CMD mkdir -p "$(dirname "$targetdir")"

            # Symlink the directory
            if [ ! -e "$targetdir" ]; then
              $DRY_RUN_CMD ln -sf "$fontdir" "$targetdir" 2>/dev/null || true
            fi
          done
        fi
      '')
      texFonts}

    echo "TeX fonts synced to ${texmfFonts}"
  '';
in {
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

  # Create TeX directories and symlink fonts
  home.activation.setupTex = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/tex/latex
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/bibtex/bib
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.texmf/fonts

    # Symlink Nix fonts to TEXMF for reproducible LaTeX builds
    ${linkFontsScript}
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
