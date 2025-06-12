{ lib }: 
let
  vars = {
    # User Information
    username = "youturn";
    userfullname = "David Liu";
    useremail = "youturn45@gmail.com";
    
    # System Configuration
    system = "aarch64-darwin";
    hostname = "Rorschach";
    timeZone = "Asia/Shanghai";  # Centralized timezone configuration
    
    # Darwin System Settings (centralized)
    darwinStateVersion = 6;  # nix-darwin state version
    primaryUser = "youturn"; # Required for homebrew and user-specific settings
    
    # Home Manager Settings
    homeStateVersion = "25.05";
  };
in
# Input validation assertions
assert lib.asserts.assertMsg (vars.username != "") "username cannot be empty";
assert lib.asserts.assertMsg (vars.hostname != "") "hostname cannot be empty";
assert lib.asserts.assertMsg (lib.elem vars.system ["aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"]) 
  "unsupported system architecture: ${vars.system}";
assert lib.asserts.assertMsg (vars.primaryUser == vars.username) 
  "primaryUser must match username for consistency";

vars
