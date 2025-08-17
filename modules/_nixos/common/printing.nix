{
  pkgs,
  myvars,
  ...
}: {
  # Enable CUPS printing service
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      hplip
      cups-filters
      ghostscript
    ];
  };

  # Enable avahi for network printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Add user to lp group for printer access
  users.users.${myvars.username}.extraGroups = ["lp"];
}
