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
            
            initExtraFirst = ''
              # Fix key bindings FIRST - before anything else loads
              bindkey "^[[3~" delete-char           # Delete key (standard)
              bindkey "^[3;5~" delete-char          # Ctrl+Delete  
              bindkey "^[[P" delete-char            # Delete key alternative
              bindkey "^H" backward-delete-char     # Backspace (Ctrl+H)
              bindkey "^?" backward-delete-char     # Backspace (DEL)
              bindkey "^[[H" beginning-of-line      # Home key
              bindkey "^[[F" end-of-line            # End key
              bindkey "^[[1~" beginning-of-line     # Home alternative
              bindkey "^[[4~" end-of-line           # End alternative
              bindkey "\e[3~" delete-char           # Delete with escape prefix
              bindkey "\177" backward-delete-char   # DEL character (127)
              
              # Set terminal options for better compatibility
              stty erase '^?'
            '';
            
            initContent = ''
              # Initialize starship prompt
              eval "$(starship init zsh)"
              
              # Run claude-code installation on first login
              if [[ ! -f "$HOME/.npm-global/bin/claude-code" && -f "$HOME/.local/bin/install-claude-code" ]]; then
                echo "Setting up claude-code..."
                "$HOME/.local/bin/install-claude-code"
              fi
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

          # NPM configuration matching home/base/core/dev/npm/
          home.sessionVariables = {
            NPM_CONFIG_PREFIX = "\${HOME}/.npm-global";
            NPM_CONFIG_CACHE = "\${HOME}/.npm-cache";
          };

          home.sessionPath = [
            "\${HOME}/.npm-global/bin"
          ];

          home.file.".npmrc".text = ''
            prefix=''${HOME}/.npm-global
            cache=''${HOME}/.npm-cache
            init-author-name=${myvars.username}
            init-license=MIT
            fund=false
            audit=false
          '';

          # Claude-code installation via shell script approach
          home.file.".local/bin/install-claude-code".source = specialArgs.pkgs.writeShellScript "install-claude-code" ''
            export PATH="${specialArgs.pkgs.nodejs_22}/bin:$PATH"
            export NPM_CONFIG_PREFIX="$HOME/.npm-global"
            export NPM_CONFIG_CACHE="$HOME/.npm-cache"
            
            # Create directories
            mkdir -p "$HOME/.npm-global" "$HOME/.npm-cache" "$HOME/.config/claude-code"
            
            # Install claude-code if not present
            if ! "$HOME/.npm-global/bin/claude-code" --version 2>/dev/null; then
              echo "Installing claude-code..."
              "${specialArgs.pkgs.nodejs_22}/bin/npm" install -g @anthropic-ai/claude-code@latest
            else
              echo "claude-code already installed"
            fi
          '';

          home.file.".config/claude-code/config.json".text = builtins.toJSON {
            editor = "vim";
            theme = "dark";
          };

          # Shell aliases for claude-code
          programs.zsh.shellAliases = {
            claude = "claude-code";
            cc = "claude";
          };
        };
      }
    ];
  };

  # anotherVm = mkNixosHost { ... };
}
