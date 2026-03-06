# LaTeX Configuration

TeX Live setup with automated font management for reproducible document builds.

## Overview

This configuration provides:
- **TeX Live scheme-full**: Complete LaTeX distribution with all packages
- **Automated font linking**: Nix-managed fonts automatically synced to TEXMF
- **Cross-platform**: Works identically on macOS (nix-darwin) and NixOS
- **Reproducible**: Font versions locked to Nix store, ensuring consistent compilation

## Architecture

### Font System Design

This configuration uses **Option 1: TEXMF Font Management** for reproducibility:

```
Nix Fonts Flow:
┌─────────────────────────────────────────────────────────────┐
│ modules/common/fonts.nix                                    │
│ (defines: nerd-fonts, source-sans, etc.)                    │
└────────────┬────────────────────────────────────────────────┘
             │
             ├─────────────────────┬─────────────────────────┐
             ↓                     ↓                         ↓
    /Library/Fonts/Nix Fonts/  ~/.texmf/fonts/        macOS FontBook
    (system-wide fonts)        (LaTeX fonts)          (GUI apps)
```

### Why Two Font Locations?

**macOS System Fonts** (`/Library/Fonts/Nix Fonts/`):
- Managed by `fonts.packages` in `modules/common/fonts.nix`
- Accessible to GUI applications (FontBook, browsers, editors)
- Updated when system is rebuilt

**LaTeX TEXMF Fonts** (`~/.texmf/fonts/`):
- Symlinked automatically from Nix store via Home Manager activation
- Only accessible to LaTeX engines (pdflatex, XeLaTeX, LuaLaTeX)
- Ensures reproducible document compilation
- Synced on every Home Manager rebuild

### Font Discovery in LaTeX

LaTeX engines search fonts in this order:

1. **TEXMFHOME**: `~/.texmf/fonts/` (user fonts - **our Nix fonts**)
2. **TEXMF-LOCAL**: TeX Live distribution fonts
3. **TEXMF-DIST**: `/nix/store/.../texlive-combined-full/`

**Important**: LaTeX does NOT search `/Library/Fonts/` by default. This is intentional for reproducibility.

## Font List

Fonts automatically available in LaTeX (synced from `modules/common/fonts.nix`):

### Nerd Fonts (Coding)
- **FiraCode Nerd Font**: Ligatures for programming
- **JetBrains Mono Nerd Font**: JetBrains' monospace font
- **Space Mono Nerd Font**: Google's geometric monospace
- **Maple Mono NF CN**: Maple Mono with Chinese glyphs

### Source Fonts
- **Source Sans 3**: Adobe's sans-serif (Latin)
- **Source Serif 4**: Adobe's serif (Latin)
- **Source Han Sans** (思源黑体): Pan-CJK sans-serif
- **Source Han Serif** (思源宋体): Pan-CJK serif

### Icon Fonts
- **Material Design Icons**: Google's material icons
- **Font Awesome**: Popular icon font

## Usage Examples

### XeLaTeX with Custom Fonts

```latex
\documentclass{article}
\usepackage{fontspec}

% Set main document fonts
\setmainfont{Source Sans 3}
\setsansfont{Source Sans 3}
\setmonofont{FiraCode Nerd Font}

\begin{document}
\section{Font Demo}

Regular text in Source Sans 3.

\texttt{Monospace code with ligatures: -> => != >= <=}

{\fontspec{Source Han Sans SC}中文内容使用思源黑体}

\end{document}
```

**Compile**: `xelatex document.tex`

### LuaLaTeX with CJK

```latex
\documentclass{article}
\usepackage{fontspec}

\setmainfont{Source Serif 4}
\newfontfamily\cjkfont{Source Han Serif SC}

\begin{document}
English text in Source Serif.

{\cjkfont 中文使用思源宋体}
\end{document}
```

**Compile**: `lualatex document.tex`

### Traditional LaTeX (pdflatex)

pdflatex uses only TeX-native fonts (Computer Modern, Latin Modern, etc.) and cannot access TrueType/OpenType fonts. Use XeLaTeX or LuaLaTeX for custom fonts.

## Available Commands

Shell aliases defined in this configuration:

```bash
# Clean LaTeX auxiliary files
texclean

# Quick compile and view (pdflatex + zathura)
texview document.tex
```

## Environment Variables

- `TEXMFHOME`: `~/.texmf` - User-specific TeX packages and fonts
- `PDFVIEWER`: `zathura` - Default PDF viewer

## Adding New Fonts

To add fonts to LaTeX:

### 1. Add to System Fonts

Edit `modules/common/fonts.nix`:

```nix
fonts.packages = with pkgs; [
  # ... existing fonts ...
  roboto  # Add new font package
];
```

### 2. Add to LaTeX Font List

Edit `home/common/dev-tools/tex/default.nix`:

```nix
texFonts = with pkgs; [
  # ... existing fonts ...
  roboto  # Add same font here
];
```

### 3. Rebuild Configuration

```bash
just build
```

The font will be automatically symlinked to `~/.texmf/fonts/` and available in LaTeX.

## Troubleshooting

### Font Not Found in XeLaTeX

**Check if font is linked:**
```bash
ls -la ~/.texmf/fonts/truetype/
ls -la ~/.texmf/fonts/opentype/
```

**Verify font name:**
```bash
# List fonts in TEXMF
find ~/.texmf/fonts -name "*.ttf" -o -name "*.otf"
```

**Check font name in LaTeX:**
```latex
% Use exact font name from file
\setmainfont{SourceSans3-Regular}  % Try with/without version numbers
```

### Fonts Not Syncing After Rebuild

**Manual activation:**
```bash
# Trigger Home Manager activation again
home-manager switch --flake ~/.config/nix-personal-config
```

**Check activation output:**
Look for: `TeX fonts synced to /Users/youturn/.texmf/fonts`

### Font Works in FontBook but Not LaTeX

This is **expected behavior**. macOS system fonts (`/Library/Fonts/`) are separate from LaTeX TEXMF fonts (`~/.texmf/fonts/`).

**Solution**: Add the font to both locations (see "Adding New Fonts" above).

### Stale Font Symlinks

If fonts were removed from config but still appear in TEXMF:

```bash
# Clean and rebuild
rm -rf ~/.texmf/fonts/truetype/* ~/.texmf/fonts/opentype/*
just build
```

## Why Not Use System Fonts?

We could enable `fontconfig` and `OSFONTDIR` to let LaTeX access `/Library/Fonts/`, but we chose TEXMF linking for:

**Reproducibility**: Documents compile identically across machines
- Font versions locked to Nix derivations
- No dependency on system state

**Portability**: Works on both macOS and NixOS
- `OSFONTDIR` is macOS-specific
- TEXMF paths are cross-platform

**Explicitness**: Clear which fonts a document uses
- Fonts declared in Nix configuration
- No hidden dependencies on system fonts

**Performance**: Faster font loading
- TeX searches smaller font directory
- No `fontconfig` cache overhead

## File Structure

```
~/.texmf/
├── fonts/
│   ├── truetype/          # TrueType fonts (.ttf)
│   │   ├── FiraCode/      # Symlink → /nix/store/.../
│   │   ├── SourceSans/
│   │   └── ...
│   └── opentype/          # OpenType fonts (.otf)
│       └── ...
├── tex/latex/             # Custom LaTeX packages
└── bibtex/bib/            # Bibliography files
```

## Additional Tools

### Installed Packages

- **texlab**: Language server for LaTeX (LSP)
- **latexrun**: Build automation tool
- **rubber**: Automated LaTeX compilation
- **texstudio**: LaTeX editor (GUI)
- **zathura**: Lightweight PDF viewer (configured with Catppuccin theme)
- **evince**: GNOME document viewer
- **imagemagick**: Image conversion for LaTeX
- **ghostscript**: PostScript interpreter

### Zathura Configuration

PDF viewer with Catppuccin Mocha theme:
- Dark mode by default (`recolor = true`)
- Vim-like keybindings
- Fast and minimal

**Usage**:
```bash
zathura document.pdf
```

## References

- [TeX Live Manual](https://www.tug.org/texlive/doc.html)
- [fontspec Documentation](https://ctan.org/pkg/fontspec) - XeLaTeX/LuaLaTeX font selection
- [TEXMF Directory Structure](https://www.tug.org/texmf-dist/)
- [Nix Fonts Configuration](../../modules/common/fonts.nix)
- [XeTeX Font Loading](https://www.tug.org/xetex/)

## Design Decisions

This configuration prioritizes:
1. **Reproducibility** over convenience
2. **Explicit dependencies** over implicit system fonts
3. **Cross-platform compatibility** over macOS-specific features
4. **Automated management** over manual font installation

For font experimentation and design work, consider enabling system font access (see CLAUDE.md for Option 2 implementation).
