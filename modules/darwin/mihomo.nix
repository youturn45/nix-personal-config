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
  # Install mihomo binary system-wide
  environment.systemPackages = [pkgs.mihomo];

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
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        configDir
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/mihomo.log";
      StandardErrorPath = "${logDir}/mihomo.error.log";
    };
  };
}
