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

    drivers = with pkgs; [
      hplip
      gutenprint
    ];
  };

  # Create the cups backend directory structure
  environment.etc."cups/backend" = {
    source = "${pkgs.cups}/lib/cups/backend";
    mode = "0755";
  };

  # Alternatively, create symlinks to the specific backends
  environment.etc."cups/backend/usb" = {
    source = "${pkgs.cups}/lib/cups/backend/usb";
    mode = "0755";
  };

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
}
