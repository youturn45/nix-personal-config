let
  # Add each host's public key here and re-encrypt before deploying to it.
  youturn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzV1VGMASpQBUI1/N9db4k8wyVnO4sb0xOthUPK1g6g";
in {
  "github-nix.conf.age".publicKeys = [youturn];
}
