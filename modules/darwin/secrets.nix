{
  config,
  pkgs,
  agenix,
  myvars,
  ...
}: {
  # Install agenix CLI tool
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.system}.default
  ];

  # Define secrets
  age.secrets = {
    # SSH key for Rorschach
    ssh-key-rorschach = {
      file = ../../secrets/ssh-key-rorschach.age;
      path = "/Users/${myvars.username}/.ssh/rorschach_agenix";
      owner = myvars.username;
      group = "staff";
      mode = "0600";
    };

    # GitHub Personal Access Token
    # After decryption, the token will be available at the specified path
    # You can use it in scripts or environment variables
    github-token = {
      file = ../../secrets/github-token.age;
      path = "/Users/${myvars.username}/.config/github/token";
      owner = myvars.username;
      group = "staff";
      mode = "0400"; # Read-only for user
    };
  };

  # Optional: Set up environment variable for GitHub token
  # This makes the token available as $GITHUB_TOKEN in your shell
  environment.variables = {
    GITHUB_TOKEN_FILE = config.age.secrets.github-token.path;
  };

  # Optional: Create a helper script to read the token
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "github-token" ''
      #!/usr/bin/env bash
      # Read and display the GitHub token (use with caution!)
      if [ -f "${config.age.secrets.github-token.path}" ]; then
        cat "${config.age.secrets.github-token.path}"
      else
        echo "GitHub token file not found at ${config.age.secrets.github-token.path}" >&2
        exit 1
      fi
    '')
  ];
}
