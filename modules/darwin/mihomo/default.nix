{
  pkgs-stable,
  pkgs-unstable,
  myvars,
  lib,
  ...
}: let
  homeDir = "/Users/${myvars.username}";
  configDir = "${homeDir}/.config/clash.meta";
  logDir = "${homeDir}/Library/Logs/mihomo";
  repoUrl = "git@github.com:youturn45/clash.meta.git";
  sshKey = "${homeDir}/.ssh/Youturn";
  gitSSH = "ssh -i ${sshKey} -o StrictHostKeyChecking=accept-new -o BatchMode=yes";
  restartScript = ''
    set -e
    service=system/io.github.metacubex.mihomo
    plist=/Library/LaunchDaemons/io.github.metacubex.mihomo.plist

    if /usr/bin/sudo /bin/launchctl print "$service" >/dev/null 2>&1; then
      echo "mihomo: restarting system service..."
      /usr/bin/sudo /bin/launchctl kickstart -k "$service"
    else
      if [ ! -f "$plist" ]; then
        echo "mihomo: service plist missing: $plist (run darwin-rebuild switch)" >&2
        exit 1
      fi
      echo "mihomo: loading system service..."
      /usr/bin/sudo /bin/launchctl enable "$service"
      /usr/bin/sudo /bin/launchctl bootstrap system "$plist"
    fi
    echo "mihomo: system service started"
  '';
  # One-way local copy into iCloud Drive; macOS uploads it. See README.md.
  icloudDir = "${homeDir}/Library/Mobile Documents/com~apple~CloudDocs/Mihomo";
in {
  environment.systemPackages = [
    pkgs-unstable.mihomo

    # The only public management command; restart and export stay internal.
    (pkgs-stable.writeShellScriptBin "mihomo-sync" ''
      set -e
      export GIT_SSH_COMMAND=${lib.escapeShellArg gitSSH}
      git=${lib.escapeShellArg (lib.getExe pkgs-stable.git)}
      config_dir=${lib.escapeShellArg configDir}
      sync_fail() {
        echo "mihomo: $1" >&2
        echo "mihomo: Nothing was copied or restarted; no local changes were discarded." >&2
        exit 1
      }

      if [ ! -e "$config_dir/.git" ]; then
        echo "mihomo: cloning config repo..."
        "$git" clone ${lib.escapeShellArg repoUrl} "$config_dir" \
          || sync_fail "Config clone failed; check SSH access and the checkout path."
      else
        dirty=$("$git" -C "$config_dir" status --porcelain --untracked-files=all) \
          || sync_fail "Cannot read checkout status."
        if [ -n "$dirty" ]; then
          sync_fail "Checkout has uncommitted or untracked changes; save your local work before retrying."
        fi
        upstream=$("$git" -C "$config_dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) \
          || sync_fail "Current branch has no upstream (or HEAD is detached)."
        echo "mihomo: fast-forwarding from $upstream..."
        "$git" -C "$config_dir" pull --ff-only \
          || sync_fail "Fast-forward update failed; check network access or divergent history."
      fi

      # Validate with the same engine as the daemon before exporting or touching
      # launchd. Keep parser output private: config errors may contain secrets.
      echo "mihomo: checking updated configuration..."
      if ! ${pkgs-unstable.mihomo}/bin/mihomo -t -d "$config_dir" >/dev/null 2>&1; then
        sync_fail "config validation failed; the checkout is updated, but export and restart were skipped. Fix or explicitly revert the configuration before retrying."
      fi

      # A failed iCloud copy must not block the restart, but must not pass as success.
      icloud_status=0
      ${pkgs-stable.python3}/bin/python3 ${./sync-icloud.py} \
        --source ${lib.escapeShellArg configDir} \
        --destination ${lib.escapeShellArg icloudDir} || icloud_status=$?
      if [ "$icloud_status" -ne 0 ]; then
        echo "mihomo: WARNING: iCloud copy failed (exit $icloud_status); restarting anyway" >&2
      fi

      ${restartScript}

      if [ "$icloud_status" -ne 0 ]; then
        echo "mihomo: WARNING: config pulled and service restarted, but iCloud copy failed" >&2
        exit "$icloud_status"
      fi
    '')
  ];

  # Runs inside the recognized `launchd` activation script, before the system
  # daemon is (re)loaded: custom activationScripts names are not spliced by
  # nix-darwin. Stop the obsolete per-user job (launchd cleanup removes its
  # plist afterward), prepare logs, and clone once; mihomo-sync updates
  # existing checkouts. Failures abort activation instead of passing silently.
  # Root works inside a user-writable home here, so the log root and the two
  # known logs are refused if they are symlinks or the wrong file type, and
  # only those three paths are chowned (never recursively).
  system.activationScripts.launchd.text = lib.mkBefore ''
    mihomo_user=${lib.escapeShellArg myvars.username}
    mihomo_user_uid=$(/usr/bin/id -u "$mihomo_user")
    /bin/launchctl bootout "gui/$mihomo_user_uid/io.github.metacubex.mihomo" 2>/dev/null || true

    echo "mihomo: preparing log directory..." >&2
    mihomo_log_dir=${lib.escapeShellArg logDir}
    mihomo_log_fail() {
      echo "mihomo: FATAL: could not prepare log directory $mihomo_log_dir: $1" >&2
      exit 1
    }
    if [ -L "$mihomo_log_dir" ] || { [ -e "$mihomo_log_dir" ] && [ ! -d "$mihomo_log_dir" ]; }; then
      mihomo_log_fail "it is a symlink or not a directory; remove it and rerun darwin-rebuild switch"
    fi
    mkdir -p "$mihomo_log_dir" || mihomo_log_fail "mkdir failed"
    for mihomo_log in "$mihomo_log_dir/mihomo.log" "$mihomo_log_dir/mihomo.error.log"; do
      if [ -L "$mihomo_log" ] || { [ -e "$mihomo_log" ] && [ ! -f "$mihomo_log" ]; }; then
        mihomo_log_fail "$mihomo_log is a symlink or not a regular file; remove it and rerun darwin-rebuild switch"
      fi
    done
    for mihomo_log in "$mihomo_log_dir/mihomo.log" "$mihomo_log_dir/mihomo.error.log"; do
      touch "$mihomo_log" || mihomo_log_fail "cannot create $mihomo_log"
    done
    /usr/sbin/chown "$mihomo_user:staff" "$mihomo_log_dir" \
      "$mihomo_log_dir/mihomo.log" "$mihomo_log_dir/mihomo.error.log" \
      || mihomo_log_fail "chown to $mihomo_user:staff failed"

    if [ ! -d ${lib.escapeShellArg "${configDir}/.git"} ]; then
      if [ ! -f ${lib.escapeShellArg sshKey} ]; then
        echo "mihomo: FATAL: config checkout ${configDir} is missing and SSH key ${sshKey} does not exist; cannot clone ${repoUrl}" >&2
        exit 1
      fi
      echo "mihomo: cloning config repo into ${configDir}..." >&2
      if ! /usr/bin/sudo -u "$mihomo_user" \
        GIT_SSH_COMMAND=${lib.escapeShellArg gitSSH} \
        ${lib.getExe pkgs-stable.git} clone ${lib.escapeShellArg repoUrl} ${lib.escapeShellArg configDir}; then
        echo "mihomo: FATAL: git clone of ${repoUrl} into ${configDir} failed; fix SSH access and rerun darwin-rebuild switch" >&2
        exit 1
      fi
    fi
  '';

  # Run one root-owned system daemon so privileged proxy setup and process
  # management always refer to the same launchd service.
  launchd.daemons.mihomo = {
    serviceConfig = {
      Label = "io.github.metacubex.mihomo";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          mkdir -p ${logDir}
          # No TCP precheck here: Mihomo is not listening until exec below.
          # Shared private helper reports every failed service/action and exits
          # nonzero. Never launch an apparently healthy engine after setup fails.
          ${import ../../../home/common/terminal/shells/proxy-helper.nix {pkgs = pkgs-stable;}} \
            system-on http://127.0.0.1:7890 socks5://127.0.0.1:7891 || exit $?
          exec ${pkgs-unstable.mihomo}/bin/mihomo -d ${configDir}
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/mihomo.log";
      StandardErrorPath = "${logDir}/mihomo.error.log";
    };
  };
}
