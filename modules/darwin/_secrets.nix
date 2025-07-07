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
    ssh-key-rorschach = {
      file = ../../secrets/ssh-key-rorschach.age;
      path = "/Users/${myvars.username}/.ssh/rorschach_agenix";
      owner = myvars.username;
      group = "staff";
      mode = "0600";
    };
  };
}
