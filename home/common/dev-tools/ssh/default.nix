{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: {
  # Enable SSH agent service to start automatically (Linux only)
  services.ssh-agent = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        # Automatically add keys to SSH agent
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/Youturn";
      };

      github = {
        header = "Host github.com";
        HostName = "ssh.github.com";
        User = "git";
        Port = 443;
        # Use Youturn key, with fallback to other keys if not available
        IdentityFile = "~/.ssh/Youturn";
        IdentitiesOnly = false; # Allow SSH to try other keys if Youturn is not available
      };
    };

    # SSH client configuration
    extraConfig = ''
      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        # UseKeychain is an Apple-only directive; IgnoreUnknown must come
        # first so non-Apple ssh builds (e.g. mosh's bundled nixpkgs openssh)
        # skip it instead of aborting config parsing.
        IgnoreUnknown UseKeychain
        UseKeychain yes
      ''}
    '';
  };

  # Ensure SSH key is loaded automatically on login (Linux only)
  home.sessionVariables = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    # SSH agent socket will be set by the service
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  # sshd silently rejects keys if ~/.ssh or authorized_keys have wrong
  # permissions, so make sure both exist and are locked down on every build.
  home.activation.setupAuthorizedKeys = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.ssh
    $DRY_RUN_CMD chmod 700 ${config.home.homeDirectory}/.ssh
    $DRY_RUN_CMD touch ${config.home.homeDirectory}/.ssh/authorized_keys
    $DRY_RUN_CMD chmod 600 ${config.home.homeDirectory}/.ssh/authorized_keys
  '';

  # Add a shell init script to load SSH key if it's not already loaded
  programs.zsh.initContent = lib.mkAfter ''
    # Auto-load SSH key if agent is running but key isn't loaded
    if [ -n "$SSH_AUTH_SOCK" ]; then
      if [ -f ~/.ssh/Youturn ]; then
        if ! ssh-add -l | grep -q "$(ssh-keygen -lf ~/.ssh/Youturn.pub 2>/dev/null | awk '{print $2}')"; then
          ssh-add ~/.ssh/Youturn 2>/dev/null
        fi
      else
        echo "Warning: SSH key '~/.ssh/Youturn' not found."
        echo "Please add your SSH key to ~/.ssh/Youturn to enable automatic SSH authentication."
      fi
    fi
  '';
}
