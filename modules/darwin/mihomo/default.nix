{
  pkgs,
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
  reloadScript = ''
    if ! pgrep -x mihomo >/dev/null; then
      echo "mihomo is not running, starting it..." >&2
      exec launchctl kickstart -k gui/$(id -u)/io.github.metacubex.mihomo
    fi
    sudo pkill -HUP -x mihomo && echo "mihomo reloaded"
  '';
in {
  environment.systemPackages = [
    pkgs.mihomo

    (pkgs.writeShellScriptBin "mihomo-reload" reloadScript)

    (pkgs.writeShellScriptBin "mihomo-sync" ''
      set -e
      echo "mihomo: pulling latest config..."
      ${pkgs.git}/bin/git -C ${configDir} pull --ff-only
      echo "mihomo: reloading..."
      ${reloadScript}
    '')
  ];

  # Clone config repo on first build; pull on subsequent builds
  system.activationScripts.mihomoSetup = {
    text = ''
      mkdir -p ${logDir}
      touch ${logDir}/mihomo.log ${logDir}/mihomo.error.log
      chown -R ${myvars.username}:staff ${logDir}

      if [ ! -d "${configDir}/.git" ]; then
        echo "mihomo: cloning config repo..."
        sudo -u ${myvars.username} \
          GIT_SSH_COMMAND="${gitSSH}" \
          ${lib.getExe pkgs.git} clone ${repoUrl} ${configDir}
      else
        echo "mihomo: pulling latest config..."
        sudo -u ${myvars.username} \
          GIT_SSH_COMMAND="${gitSSH}" \
          ${lib.getExe pkgs.git} -C ${configDir} pull --ff-only
      fi
    '';
  };

  # Register mihomo as a per-user launchd agent
  # Runs automatically at login, restarts if it crashes
  launchd.agents.mihomo = {
    serviceConfig = {
      Label = "io.github.metacubex.mihomo";
      ProgramArguments = [
        "/bin/sh" "-c"
        ''
          mkdir -p ${logDir}
          if [ ! -w ${logDir} ]; then
            logger -t mihomo "FATAL: ${logDir} not writable by $(id -un) -- fix with: sudo chown -R $(id -un):staff ${logDir} (see modules/darwin/mihomo/debug.md)"
            exit 1
          fi
          networksetup -listallnetworkservices | tail -n +2 \
            | grep -viE "tailscale|bridge|jtag|bluetooth|vpn" \
            | while IFS= read -r svc; do
              networksetup -setwebproxy "$svc" 127.0.0.1 7890 2>/dev/null
              networksetup -setsecurewebproxy "$svc" 127.0.0.1 7890 2>/dev/null
              networksetup -setsocksfirewallproxy "$svc" 127.0.0.1 7891 2>/dev/null
              networksetup -setproxybypassdomains "$svc" \
                "127.0.0.1" "localhost" "*.local" "169.254/16" \
                "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" 2>/dev/null
            done
          exec ${pkgs.mihomo}/bin/mihomo -d ${configDir}
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/mihomo.log";
      StandardErrorPath = "${logDir}/mihomo.error.log";
    };
  };
}
