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
in {
  environment.systemPackages = [
    pkgs.mihomo

    (pkgs.writeShellScriptBin "mihomo-reload" ''
      pid=$(pgrep mihomo) || { echo "mihomo is not running" >&2; exit 1; }
      sudo kill -HUP "$pid" && echo "mihomo reloaded (PID $pid)"
    '')

    (pkgs.writeShellScriptBin "mihomo-sync" ''
      set -e
      echo "mihomo: pulling latest config..."
      ${pkgs.git}/bin/git -C ${configDir} pull --ff-only
      echo "mihomo: reloading..."
      pid=$(pgrep mihomo) || { echo "mihomo is not running" >&2; exit 1; }
      sudo kill -HUP "$pid" && echo "mihomo reloaded (PID $pid)"
    '')
  ];

  # Clone config repo on first build; pull on subsequent builds
  system.activationScripts.mihomoSetup = {
    text = ''
      mkdir -p ${logDir}
      chown ${myvars.username}:staff ${logDir}

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
          networksetup -listallnetworkservices | tail -n +2 \
            | grep -viE "tailscale|bridge|jtag|bluetooth|vpn" \
            | while IFS= read -r svc; do
              networksetup -setwebproxy "$svc" 127.0.0.1 7890 2>/dev/null
              networksetup -setsecurewebproxy "$svc" 127.0.0.1 7890 2>/dev/null
              networksetup -setsocksfirewallproxy "$svc" 127.0.0.1 7893 2>/dev/null
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
