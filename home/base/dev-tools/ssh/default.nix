{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: {
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
        # Try rorschach key first, but allow fallback to other keys if not available
        identityFile = "~/.ssh/rorschach";
        identitiesOnly = false; # Allow SSH to try other keys if rorschach is not available
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
}
