{
  config,
  pkgs,
  myvars,
  lib,
  ...
}: let
  username = myvars.username;
  localClashDir = "${config.home.homeDirectory}/.config/clash.meta";
  clashRepo = "git@github.com:youturn45/clash.meta.git";

  # Clash Verge Rev active profile directory (macOS)
  vergeClashDir =
    if pkgs.stdenv.isDarwin
    then "${config.home.homeDirectory}/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev"
    else "";

  # Optional iCloud mirror location (can be overridden at runtime)
  iCloudMirrorDir =
    if pkgs.stdenv.isDarwin
    then "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/ClashVergeRev"
    else "";

  # Sync script that pulls from git and syncs to iCloud (macOS only)
  syncClashScript = pkgs.writeShellScriptBin "sync_clash" ''
    set -e

    LOCAL_DIR="${localClashDir}"
    VERGE_DIR="${vergeClashDir}"
    ICLOUD_DIR_DEFAULT="${iCloudMirrorDir}"
    ICLOUD_DIR="${ICLOUD_CLASH_DIR:-$ICLOUD_DIR_DEFAULT}"
    REPO="${clashRepo}"
    IS_DARWIN="${
      if pkgs.stdenv.isDarwin
      then "true"
      else "false"
    }"

    # Colors for output
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    echo -e "''${GREEN}[Clash Sync]''${NC} Starting sync process..."

    # Ensure local directory exists
    mkdir -p "$LOCAL_DIR"

    # Check if local directory is a git repository
    if [ ! -d "$LOCAL_DIR/.git" ]; then
      echo -e "''${YELLOW}[Git]''${NC} Cloning repository for the first time..."
      ${pkgs.git}/bin/git clone "$REPO" "$LOCAL_DIR"
    else
      echo -e "''${YELLOW}[Git]''${NC} Pulling latest changes..."
      cd "$LOCAL_DIR"
      ${pkgs.git}/bin/git pull origin main || ${pkgs.git}/bin/git pull origin master || {
        echo -e "''${RED}[Git]''${NC} Failed to pull from remote. Trying to fetch..."
        ${pkgs.git}/bin/git fetch origin
        BRANCH=$(${pkgs.git}/bin/git rev-parse --abbrev-ref HEAD)
        ${pkgs.git}/bin/git reset --hard "origin/$BRANCH"
      }
    fi

    echo -e "''${GREEN}[Git]''${NC} Local repository updated: $LOCAL_DIR"

    # Sync on macOS: push repo config to Clash Verge Rev active directory,
    # and optionally mirror to iCloud folder.
    if [ "$IS_DARWIN" = "true" ]; then
      if [ ! -d "$VERGE_DIR" ]; then
        echo -e "''${RED}[Warning]''${NC} Clash Verge Rev directory not found: $VERGE_DIR"
        echo "Please ensure Clash Verge Rev is installed and launched at least once."
        exit 1
      fi

      echo -e "''${YELLOW}[Sync]''${NC} Updating Clash Verge Rev active config.yaml..."
      install -m 0644 "$LOCAL_DIR/config.yaml" "$VERGE_DIR/config.yaml"

      if [ -n "$ICLOUD_DIR" ]; then
        mkdir -p "$ICLOUD_DIR"
        echo -e "''${YELLOW}[Rsync]''${NC} Mirroring Clash config -> iCloud..."
        ${pkgs.rsync}/bin/rsync -av --delete \
          --exclude='.git' \
          --exclude='.gitignore' \
          --exclude='.gitmodules' \
          --exclude='.github' \
          "$LOCAL_DIR/" "$ICLOUD_DIR/"
      fi

      echo -e "''${GREEN}[Done]''${NC} Clash configuration synced successfully!"
      echo -e "  Repo:   $LOCAL_DIR"
      echo -e "  Verge:  $VERGE_DIR"
      if [ -n "$ICLOUD_DIR" ]; then
        echo -e "  iCloud: $ICLOUD_DIR"
      fi
    else
      echo -e "''${GREEN}[Done]''${NC} Clash configuration updated!"
      echo -e "  Local: $LOCAL_DIR"
      echo -e "  (Verge/iCloud sync not available on Linux)"
    fi
  '';
in {
  # Add sync_clash command to user packages
  home.packages = [
    syncClashScript
  ];

  # Ensure git and rsync are available
  programs.git.enable = true;
}
