{
  lib,
  myvars,
  ...
}: {
  youturn.roles = {
    common.enable = true;
    server.enable = true;
    desktop.enable = false;
  };

  networking.hostName = "ozymandias";

  # Public key for the administrator's existing Youturn SSH identity.
  users.users.${myvars.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzV1VGMASpQBUI1/N9db4k8wyVnO4sb0xOthUPK1g6g youturn45@gmail.com"
  ];

  # Keep DHCP as a fallback if interface names change (common on VMs).
  # Static config below still applies to enp0s3 when that device exists.
  networking.useDHCP = lib.mkDefault true;
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
