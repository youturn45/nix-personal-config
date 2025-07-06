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



  # Configuration for hostname "nixos"
  nixos = mkNixosHost {
    hostname = "nixos";
    system = "x86_64-linux";
    modules = [
      # No VM-specific modules for live system
      
      # Override home-manager configuration for minimal live system
      {
        home-manager.users.${myvars.username} = lib.mkForce {
          imports = [
            ../home/base/core/dev/npm
          ];
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
            starship
            nodejs_22
          ];
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            
            # Key bindings applied early in zsh initialization
            localVariables = {
              # Set terminal options immediately
              TERM = "xterm-256color";
            };
            
initContent = ''
              # Initialize starship prompt
              eval "$(starship init zsh)"
            '';
          };
          programs.git = {
            enable = true;
            userName = myvars.userfullname;
            userEmail = myvars.useremail;
          };
          programs.starship = {
            enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
            settings = {
              username = {
                show_always = true;
                style_user = "bold blue";
                style_root = "bold red";
                format = "[$user]($style)";
              };
              hostname = {
                ssh_only = false;
                format = "[@$hostname](bold green) ";
              };
              character = {
                success_symbol = "[➜](bold green)";
                error_symbol = "[➜](bold red)";
                vimcmd_symbol = "[🔒](bold yellow)";
              };
              directory = {
                format = "📁 [$path]($style)[$read_only]($read_only_style) ";
                style = "bold cyan";
                read_only = "🔒";
                truncation_length = 3;
                truncate_to_repo = true;
              };
              git_branch = {
                symbol = "🌱 ";
                format = "[$symbol$branch]($style) ";
                style = "bold purple";
              };
              format = "$username$hostname$line_break$directory$git_branch$character";
            };
          };

        };
      }
    ];
  };

  # anotherVm = mkNixosHost { ... };
}
