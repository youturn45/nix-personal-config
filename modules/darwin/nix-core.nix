{ pkgs, lib, myvars, ... }:

{
  # Nix configuration
  nix = {
    enable = true;
    package = pkgs.nix;
    optimise.automatic = true;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      interval.Day = 1;
    };

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
    };
  };
  
  networking = {
    hostName = myvars.hostname;
    computerName = myvars.hostname;
  };

  system.defaults.smb.NetBIOSName = myvars.hostname;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."${myvars.username}" = {
    home = "/Users/${myvars.username}";
    description = myvars.username;
    shell = pkgs.zsh;
  };
  
  # Homemanager location
  home-manager = {
    users."${myvars.username}" = import ../../home-manager;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.zsh = {
    enable = true;
    shellInit = ''
      # Nix
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
      # End Nix
    '';
  };

  environment.shells = [
    pkgs.zsh
  ];

  # Fonts
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.space-mono

      # 思源系列字体是 Adobe 主导的。其中汉字部分被称为「思源黑体」和「思源宋体」，是由 Adobe + Google 共同开发的
      source-sans # 无衬线字体，不含汉字。字族名叫 Source Sans 3 和 Source Sans Pro，以及带字重的变体，加上 Source Sans 3 VF
      source-serif # 衬线字体，不含汉字。字族名叫 Source Code Pro，以及带字重的变体
      source-han-sans # 思源黑体
      source-han-serif # 思源宋体
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}