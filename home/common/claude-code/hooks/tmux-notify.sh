#!/usr/bin/env bash
# tmux-notify.sh - Claude Code Notification hook that raises a desktop banner
#
# DESCRIPTION
#   Claude Code can't detect Ghostty from inside tmux (TERM_PROGRAM=tmux), so
#   its own notifications never reach the outer terminal. This hook writes an
#   OSC 777 notification to the Claude pane's tty, wrapped in tmux passthrough
#   (requires `allow-passthrough on`), which Ghostty turns into a macOS banner.
#
# INPUT
#   JSON via stdin with Notification event data (`.message`)

set -euo pipefail

# OSC 777 fields are `;`-separated and terminated by BEL — strip anything that
# could end the sequence early or inject another one.
sanitize() {
    tr -d '\000-\037\177' | tr ';' ','
}

message="$(jq -r '.message // "Claude needs your attention"' | sanitize)"
title="Claude Code"

if [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]]; then
    pane_tty="$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}')"
    printf '\ePtmux;\e\e]777;notify;%s;%s\a\e\\' "$title" "$message" >"$pane_tty"
    exit 0
fi

printf '\e]777;notify;%s;%s\a' "$title" "$message" >/dev/tty 2>/dev/null || true
