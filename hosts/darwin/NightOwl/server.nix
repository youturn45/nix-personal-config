{lib, myvars, ...}: {
  # NightOwl dedicated-host posture lives here.
  # Keep host-specific server behavior isolated from shared darwin modules.

  # Keep guest account disabled explicitly on this host.
  system.defaults.loginwindow.GuestEnabled = lib.mkForce false;

  # Ensure loginwindow autologin user is set at the system domain.
  # Note: macOS still requires proper autologin credential state (kcpassword),
  # which is typically created when enabling Automatic Login in System Settings.
  system.activationScripts.nightowlAutoLogin.text = ''
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "${myvars.username}" || true
  '';

  # Optional hardening knobs can be added here later (sleep, firewall profile, etc.)
}
