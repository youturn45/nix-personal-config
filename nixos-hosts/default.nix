{ lib, specialArgs, }:

let
  # Get inputs from specialArgs
  inherit (specialArgs) home-manager myvars;
  
  mkNixosHost = { hostname, system, modules ? [ ] }:
    lib.nixosSystem {
      inherit specialArgs system;
      modules = modules ++ [
        ../modules/common # NOTE shared by nixos and nix-darwin
        ../modules/_nixos/common # shared by bare-metal and vm nixos machines
        { networking.hostName = hostname; }
        (lib.path.append ./. hostname) # NOTE config specific to this host
        
        # Add Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${myvars.username} = import ../home;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
in
{
  # steps to run this vm:
  #   1. nix build .#nixosConfigurations.myVm.config.system.build.vm
  #   2. NIX_DISK_IMAGE=~/myVm.qcow2 ./result/bin/run-myVm-vm
  myVm = mkNixosHost {
    hostname = "myVm";
    system = "x86_64-linux";
    modules = [
      ../modules/_nixos/vm # only for nixos vm
      
      # Override home-manager configuration for server - minimal packages only
      {
        home-manager.users.${myvars.username} = lib.mkForce {
          home.stateVersion = "25.05";
          home.packages = with specialArgs.pkgs; [
            # Only essential packages for server
            git
            vim
            curl
            wget
            htop
            tmux
            openssh
          ];
          programs.zsh.enable = true;
          programs.git = {
            enable = true;
            userName = myvars.userfullname;
            userEmail = myvars.useremail;
          };
        };
      }
    ];
  };

  # ISO configuration for installation media
  myVm-iso = lib.nixosSystem {
    inherit specialArgs;
    system = "x86_64-linux";
    modules = [
      ../modules/common # NOTE shared by nixos and nix-darwin
      ../modules/_nixos/common # shared by bare-metal and vm nixos machines
      ./myVm # Use myVm configuration as base
      
      # ISO-specific modules
      "${specialArgs.pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      
      {
        # Override some settings for ISO
        networking.hostName = "nixos-live";
        
        # Enable SSH for remote access
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "yes";
        users.users.root.initialPassword = "nixos";
        
        # Include useful packages for installation
        environment.systemPackages = with specialArgs.pkgs; [
          git
          curl
          wget
          vim
          htop
        ];
      }
    ];
  };

  # Live system configuration (not VM)
  mySystem = mkNixosHost {
    hostname = "mySystem";
    system = "x86_64-linux";
    modules = [
      # No VM-specific modules for live system
      
      # Override home-manager configuration for minimal live system
      {
        home-manager.users.${myvars.username} = lib.mkForce {
          home.stateVersion = "25.05";
          home.packages = with specialArgs.pkgs; [
            # Only essential packages for live system
            git
            vim
            curl
            wget
            htop
            tmux
            openssh
          ];
          programs.zsh.enable = true;
          programs.git = {
            enable = true;
            userName = myvars.userfullname;
            userEmail = myvars.useremail;
          };
        };
      }
    ];
  };

  # Configuration for hostname "nixos"
  nixos = mkNixosHost {
    hostname = "nixos";
    system = "x86_64-linux";
    modules = [
      # No VM-specific modules for live system
      
      # Override home-manager configuration for minimal live system
      {
        home-manager.users.${myvars.username} = lib.mkForce {
          home.stateVersion = "25.05";
          home.packages = with specialArgs.pkgs; [
            # Only essential packages for live system
            git
            vim
            curl
            wget
            htop
            tmux
            openssh
          ];
          programs.zsh.enable = true;
          programs.git = {
            enable = true;
            userName = myvars.userfullname;
            userEmail = myvars.useremail;
          };
        };
      }
    ];
  };

  # anotherVm = mkNixosHost { ... };
}
