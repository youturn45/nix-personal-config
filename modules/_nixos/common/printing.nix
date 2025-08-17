{
  pkgs,
  myvars,
  ...
}: {
  # Enable CUPS printing service
  services.printing = {
    enable = true;
    listenAddresses = ["*:631"]; # Allow access from all network interfaces
    allowFrom = ["all"]; # Allow access from all hosts
    browsing = true;
    defaultShared = true; # Share printers by default
    drivers = with pkgs; [
      gutenprint
      hplip
      cups-filters
      ghostscript
    ];
  };

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
