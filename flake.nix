{
  description = "Nix configuration";

  # the nixConfig here only affects the flake itself, not the system configuration!
  /*nixConfig = {
    substituters = [
      # Query the mirror of USTC first, and then the official cache.
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };*/

  inputs = {
    # official nix pkgs sources
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew, used for managing homebrew packages
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # haumea, used for managing flake imports
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ghostty, used for managing ghostty packages
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    
    # nur-ryan4yin, custom packages used from ryan4yin
    nur-ryan4yin.url = "github:ryan4yin/nur-packages";
  };
 
  outputs = inputs @ { 
    self, 
    nixpkgs, 
    nixpkgs-unstable,
    nur-ryan4yin,
    nix-darwin, 
    nix-homebrew, 
    home-manager, 
    haumea,
    ghostty,
    ... }:
  let 
    inherit (nixpkgs) lib;
    myLib = import ./my-lib { inherit lib; haumeaLib = haumea.lib; };
    myvars = import ./vars { inherit lib; };
    
    # Helper function to create consistent package sets
    mkPkgs = nixpkgs: system: import nixpkgs {
      config.allowUnfree = true;
      inherit system;
      hostPlatform = system;
    };

    specialArgs = {
      inherit myvars myLib nur-ryan4yin ghostty;
      vars = myvars;  # Alias for modules expecting 'vars'
      
      pkgs = mkPkgs inputs.nixpkgs myvars.system;
      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable myvars.system;
      pkgs-stable = mkPkgs inputs.nixpkgs-stable myvars.system;
    };

  in {
    darwinConfigurations."${myvars.hostname}" = nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      system = "${myvars.system}";
      modules = [
        ./modules/common # NOTE shared by nixos and nix-darwin
        ./modules/darwin
        # ./modules/homebrew-mirror.nix # homebrew mirror, comment it if you do not need it
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${myvars.username} = import ./home;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
    nixosConfigurations = import ./_nixos-hosts { inherit lib specialArgs; };

    # Development shells
    devShells.${myvars.system} = {
      default = specialArgs.pkgs.mkShell {
        buildInputs = with specialArgs.pkgs; [
          nodejs_22  # Latest LTS version
          python3
        ];
        
        shellHook = ''
          echo "🚀 Development environment loaded"
          echo "Node.js: $(node --version)"
          echo "npm: $(npm --version)"
          
          # Setup npm directories and config
          export NPM_CONFIG_PREFIX="$HOME/.npm-global"
          export NPM_CONFIG_CACHE="$HOME/.npm-cache"
          export PATH="$HOME/.npm-global/bin:$PATH"
          
          # Create directories
          mkdir -p "$HOME/.npm-global"
          mkdir -p "$HOME/.npm-cache"
          
          # Install claude-code if not available
          if ! command -v claude-code >/dev/null 2>&1; then
            echo "📦 Installing claude-code..."
            npm install -g @anthropic-ai/claude-code
            echo "✅ claude-code installed successfully"
          else
            echo "✅ claude-code already available"
          fi
          
          echo "💡 Use 'claude-code' to start Claude Code"
          echo "💡 Use 'exit' to leave development environment"
        '';
      };
      
      # Alternative shell for testing without auto-install
      minimal = specialArgs.pkgs.mkShell {
        buildInputs = with specialArgs.pkgs; [
          nodejs_22
        ];
        
        shellHook = ''
          export NPM_CONFIG_PREFIX="$HOME/.npm-global"
          export PATH="$HOME/.npm-global/bin:$PATH"
          echo "Minimal dev shell loaded. Run 'npm install -g @anthropic-ai/claude-code' to install manually."
        '';
      };
    };
  };
}