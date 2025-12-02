# This file defines who can decrypt which secrets
# It maps public SSH keys to the secrets they can access
#
# To add a new key:
# 1. Generate an SSH key: ssh-keygen -t ed25519 -C "agenix-key-$(hostname)"
# 2. Add the public key path here
# 3. Re-encrypt all secrets: cd secrets && for file in *.age; do agenix -r -i ~/.ssh/id_ed25519 "$file"; done
let
  # System SSH keys - these are the host keys
  # You can find these in /etc/ssh/ on each host
  # For Darwin: /etc/ssh/ssh_host_ed25519_key.pub
  # For NixOS: /etc/ssh/ssh_host_ed25519_key.pub

  # User SSH keys for encryption/decryption
  # These should be your personal SSH keys that you use for managing secrets
  youturn-rorschach = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5i/9yJ7CBDqGYYQvDFXlAPfxvLoVn5YCc1pQCuEDth youturn@Rorschach.local";

  # You can add more user keys here:
  # youturn-nightowl = "ssh-ed25519 AAAA... youturn@NightOwl";
  # youturn-silkspectre = "ssh-ed25519 AAAA... youturn@SilkSpectre";

  # Host system keys (optional but recommended for better security)
  # These are automatically generated when the system is first built
  # rorschach-system = "ssh-ed25519 AAAA... root@Rorschach";

  # Define which keys can access which secrets
  # For simplicity, we'll use the same keys for all hosts
  allKeys = [
    youturn-rorschach
    # Add more keys as needed
  ];
in {
  # GitHub token - accessible by all defined keys
  "secrets/github-token.age".publicKeys = allKeys;

  # SSH key for Rorschach (already defined)
  "secrets/ssh-key-rorschach.age".publicKeys = allKeys;

  # Add more secrets here as needed:
  # "secrets/another-secret.age".publicKeys = allKeys;
  # "secrets/prod-only-secret.age".publicKeys = [ youturn-prod-server ];
}
