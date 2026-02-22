{
  ...
}: {
  networking.hostName = "ozymandias";

  # Host-specific static network configuration
  networking.useDHCP = false;
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
