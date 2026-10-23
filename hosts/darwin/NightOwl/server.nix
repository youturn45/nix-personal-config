{
  lib,
  myvars,
  ...
}: {
  # NightOwl dedicated-host posture lives here.
  # Keep host-specific server behavior isolated from shared darwin modules.

  # Keep guest account disabled explicitly on this host.
  system.defaults.loginwindow.GuestEnabled = lib.mkForce false;

  # Written to /Library/Preferences/com.apple.loginwindow by nix-darwin's
  # `defaults` activation. This only names the user: macOS still needs the
  # autologin credential state (/etc/kcpassword), configured manually through
  # Automatic Login in System Settings. Nix never handles those credentials.
  system.defaults.loginwindow.autoLoginUser = myvars.username;

  # Optional hardening knobs can be added here later (sleep, firewall profile, etc.)
}
