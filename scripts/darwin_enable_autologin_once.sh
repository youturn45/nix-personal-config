#!/usr/bin/env bash
set -euo pipefail

# One-time macOS auto-login initializer.
#
# Why this exists:
# - Nix can set loginwindow defaults, but macOS also needs secure autologin
#   credential state (kcpassword) created via privileged system tooling.
# - This script performs that one-time step and drops a marker so it is
#   intentionally non-repeating.

USER_NAME="${1:-youturn}"
MARKER_FILE="/var/db/.nightowl-autologin-initialized"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run as your normal user (it will sudo internally), not as root."
  exit 1
fi

if ! id "${USER_NAME}" >/dev/null 2>&1; then
  echo "User '${USER_NAME}' does not exist on this machine."
  exit 1
fi

if [[ -f "${MARKER_FILE}" ]]; then
  echo "Autologin already initialized (marker exists: ${MARKER_FILE})."
  echo "If you need to re-run, remove marker manually and run again."
  exit 0
fi

read -r -s -p "Enter login password for '${USER_NAME}': " USER_PASS
echo

# Creates macOS autologin credential state.
sudo /usr/sbin/sysadminctl -autologin "${USER_NAME}" -password "${USER_PASS}"

# Persist explicit loginwindow key as a sanity check.
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "${USER_NAME}"

# One-time marker.
sudo /usr/bin/touch "${MARKER_FILE}"

echo "Auto-login initialized for '${USER_NAME}'."
echo "Verify: defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser"
