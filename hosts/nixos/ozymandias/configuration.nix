{
  ...
}: {
  youturn.roles = {
    common.enable = true;
    server.enable = true;
    desktop.enable = false;
  };

  networking.hostName = "ozymandias";

  # Keep DHCP as a fallback if interface names change (common on VMs).
  # Static config below still applies to enp0s3 when that device exists.
  networking.useDHCP = true;
  networking.interfaces.enp0s3 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "10.0.0.4";
        prefixLength = 24;
      }
    ];
  };
}
