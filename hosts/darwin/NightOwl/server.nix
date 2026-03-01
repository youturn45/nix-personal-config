{lib, ...}: {
  # NightOwl dedicated-host posture lives here.
  # Keep host-specific server behavior isolated from shared darwin modules.

  # Keep guest account disabled explicitly on this host.
  system.defaults.loginwindow.GuestEnabled = lib.mkForce false;

  # Optional hardening knobs can be added here later (sleep, firewall profile, etc.)
}
