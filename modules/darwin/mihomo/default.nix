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
    echo "mihomo: restarting system service..."
    /usr/bin/sudo /bin/launchctl kickstart -k system/io.github.metacubex.mihomo
    echo "mihomo restarted"
  '';
in {
  environment.systemPackages = [
    pkgs-unstable.mihomo

    (pkgs-stable.writeShellScriptBin "mihomo-reload" restartScript)

    (pkgs-stable.writeShellScriptBin "mihomo-sync" ''
      set -e
      echo "mihomo: pulling latest config..."
      export GIT_SSH_COMMAND="${gitSSH}"
      ${pkgs-stable.git}/bin/git -C ${configDir} pull --ff-only
      ${restartScript}
    '')
  ];

  # Bootstrap once; update existing checkouts explicitly with mihomo-sync.
  system.activationScripts.mihomoSetup = {
    text = ''
      mkdir -p ${logDir}
      touch ${logDir}/mihomo.log ${logDir}/mihomo.error.log
      chown -R ${myvars.username}:staff ${logDir}

      if [ ! -d "${configDir}/.git" ]; then
        echo "mihomo: cloning config repo..."
        sudo -u ${myvars.username} \
          GIT_SSH_COMMAND="${gitSSH}" \
          ${lib.getExe pkgs-stable.git} clone ${repoUrl} ${configDir}
      fi
    '';
  };

  # Stop the obsolete per-user job before launchd loads the system daemon.
  # The normal launchd activation cleanup removes its plist afterward.
  system.activationScripts.launchd.text = lib.mkBefore ''
    mihomo_user_uid=$(/usr/bin/id -u ${lib.escapeShellArg myvars.username})
    /bin/launchctl bootout "gui/$mihomo_user_uid/io.github.metacubex.mihomo" 2>/dev/null || true
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
