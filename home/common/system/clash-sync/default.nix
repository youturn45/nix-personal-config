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

  # Platform-specific iCloud path (macOS only)
  iCloudClashDir =
    if pkgs.stdenv.isDarwin
    then "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~com~metacubex~ClashX/Documents"
    else "";

  # Sync script that pulls from git and syncs to iCloud (macOS only)
  syncClashScript = pkgs.writeShellScriptBin "sync_clash" ''
    set -e

    LOCAL_DIR="${localClashDir}"
    ICLOUD_DIR="${iCloudClashDir}"
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

    # Sync to iCloud only on macOS
    if [ "$IS_DARWIN" = "true" ]; then
      # Check if iCloud directory exists
      if [ ! -d "$ICLOUD_DIR" ]; then
        echo -e "''${RED}[Warning]''${NC} iCloud directory not found: $ICLOUD_DIR"
        echo "Please ensure ClashX is installed and iCloud Drive is enabled."
        echo "Skipping iCloud sync..."
        exit 0
      fi

      # Sync to iCloud, excluding .git directory
      echo -e "''${YELLOW}[Rsync]''${NC} Syncing to iCloud (excluding .git)..."
      ${pkgs.rsync}/bin/rsync -av --delete \
        --exclude='.git' \
        --exclude='.gitignore' \
        --exclude='.gitmodules' \
        --exclude='.github' \
        "$LOCAL_DIR/" "$ICLOUD_DIR/"

      echo -e "''${GREEN}[Done]''${NC} Clash configuration synced successfully!"
      echo -e "  Local:  $LOCAL_DIR"
      echo -e "  iCloud: $ICLOUD_DIR"
    else
      echo -e "''${GREEN}[Done]''${NC} Clash configuration updated!"
      echo -e "  Local: $LOCAL_DIR"
      echo -e "  (iCloud sync not available on Linux)"
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
