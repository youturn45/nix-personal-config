{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: {
  # Enable SSH agent service to start automatically (Linux only)
  services.ssh-agent = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
  };

  programs.ssh = {
    enable = true;

    # Automatically add keys to SSH agent
    addKeysToAgent = "yes";

    matchBlocks = {
      github = {
        host = "github.com";
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        # Use standard ed25519 key, with fallback to other keys if not available
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = false; # Allow SSH to try other keys if id_ed25519 is not available
      };
    };

    # SSH client configuration
    extraConfig = ''
      # Add keys to agent automatically when used
      AddKeysToAgent yes

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Use macOS keychain for storing passphrases (Darwin only)
        UseKeychain yes
      ''}
    '';
  };

  # Ensure SSH key is loaded automatically on login (Linux only)
  home.sessionVariables = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # SSH agent socket will be set by the service
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  # Add a shell init script to load SSH key if it's not already loaded
  programs.zsh.initContent = lib.mkAfter ''
    # Auto-load SSH key if agent is running but key isn't loaded
    if [ -n "$SSH_AUTH_SOCK" ] && [ -f ~/.ssh/id_ed25519 ]; then
      if ! ssh-add -l | grep -q "$(ssh-keygen -lf ~/.ssh/id_ed25519.pub | awk '{print $2}')"; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
      fi
    fi
  '';
}
