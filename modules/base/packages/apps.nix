##########################################################################
# 
#  Install all packages here.
#
#  Feel free to modify this file to fit your needs.
#
##########################################################################

{
  config,
  pkgs,
  myvars,
  nuenv,
  ...
} @ args: {

  environment.systemPackages = with pkgs; [
    # System tools
    curl       # Command-line tool for transferring data with URLs
    findutils  # Utilities to find files meeting specified criteria
    file       # Determines file type
    git        # Version control system
    gnutar     # GNU version of the tar archiving utility
    rsync      # Fast, versatile, remote (and local) file-copying tool
    tree       # Displays directory tree in a visually appealing way
    which      # Shows the full path of shell commands

    # Monitoring
    btop       # Resource monitor that shows usage and stats
    coreutils  # Basic file, shell, and text manipulation utilities
    duf        # Disk usage utility

    # Text editors
    nano       # Simple text editor
    neovim     # Vim-based text editor

    # GUI tools in terminal
    fzf        # Command-line fuzzy finder
    glow       # Markdown previewer in terminal
    jq         # Command-line JSON processor
    yazi       # Terminal file manager
    yq-go      # YAML processor

    # Archives
    p7zip      # File archiver with high compression ratio
    zip        # Package and compress (archive) files
    zstd       # Fast compression algorithm

    # Text processing
    gawk       # Pattern scanning and processing language
    gnugrep    # Search for patterns in files
    gnused     # Stream editor for filtering and transforming text

    # Networking tools
    aria2      # Multi-protocol & multi-source download utility
    dnsutils   # DNS query utilities
    ipcalc     # IP subnet calculator
    iperf3     # Network performance measurement tool
    ldns       # DNS utilities (replacement for dig)
    mtr        # Network diagnostic tool
    nmap       # Network discovery and security auditing
    socat      # Multipurpose relay (SOcket CAT)
    wget       # Network downloader

    # Development tools
    delta      # Syntax-highlighting pager for git and diff output
    gh         # GitHub CLI
    git-lfs    # Git extension for versioning large files
    just       # Command runner
    lazygit    # Simple terminal UI for git commands
    nushell    # Modern shell for the GitHub era

    # Network tools
    httpie     # User-friendly HTTP client
  ];

  /*nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';*/
}
