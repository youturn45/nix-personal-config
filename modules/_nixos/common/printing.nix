{
  pkgs,
  myvars,
  ...
}: {
  # Enable CUPS printing service
  services.printing = {
    enable = true;
    listenAddresses = ["*:631"];
    allowFrom = ["all"];
    browsing = true;
    defaultShared = true;

    # Add HP drivers
    drivers = with pkgs; [
      hplip # HP Linux Imaging and Printing
      gutenprint # Additional drivers
      cups-filters
      ghostscript
    ];
  };

  # HP printer specific services
  services.hplip.enable = true;

  # Add user to additional printer-related groups
  users.users.${myvars.username}.extraGroups = ["lp" "scanner"];

  # Open firewall for CUPS
  networking.firewall = {
    allowedTCPPorts = [631]; # CUPS web interface and IPP
    allowedUDPPorts = [631]; # CUPS browsing
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
