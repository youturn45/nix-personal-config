{ config, lib, pkgs, myvars, ... }:

{
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
        identityFile = "~/.ssh/rorschach";  # Use standard SSH key
        identitiesOnly = true;
      };
    };

    # SSH client configuration
    extraConfig = ''
      # Add keys to agent automatically when used
      AddKeysToAgent yes
      
      # Use macOS keychain for storing passphrases
      UseKeychain yes
    '';
  };
}