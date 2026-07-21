{...}: {
  ##########################################################################
  #
  #  Server-only Homebrew apps (NightOwl).
  #
  #  This module is `_`-prefixed so auto-collection skips it; it is imported
  #  explicitly from hosts/darwin/NightOwl.nix. The lists here merge with the
  #  shared homebrew block in modules/darwin/apps.nix.
  #
  ##########################################################################

  homebrew = {
    # `brew install`
    brews = [
      "steipete/tap/remindctl" # reminders CLI for openclaw (server-side)
    ];

    # `brew install --cask`
    casks = [
      "maa" # MAA — remote gaming automation, runs on the server
      "bluestacks" # Android emulator for remote gaming, runs on the server
    ];
  };
}
