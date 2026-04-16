{
  pkgs,
  lib,
  ...
}: let
  servePort = 9080;
  clashPort = 9090;

  backends = [
    {host = "127.0.0.1";}
    {host = "10.0.0.3";}
    {host = "10.0.0.5";}
    {host = "10.0.0.10";}
  ];

  # Build the api-list JSON: each entry needs a stable uuid, protocol, host, port, password.
  # UUIDs are deterministic (name-based v5-ish via builtins.hashString) so rebuilds don't
  # generate new entries in the browser.
  mkEntry = b: let
    hash = builtins.hashString "sha256" b.host;
    # Format as 8-4-4-4-12 UUID from the first 32 hex chars of the hash
    uuid = "${lib.substring 0 8 hash}-${lib.substring 8 4 hash}-${lib.substring 12 4 hash}-${lib.substring 16 4 hash}-${lib.substring 20 12 hash}";
  in {
    inherit uuid;
    protocol = "http";
    host = b.host;
    port = toString clashPort;
    password = "";
  };

  apiList = map mkEntry backends;

  initScript = pkgs.writeText "zashboard-init.js" ''
    (function () {
      var apiListKey = "setup/api-list";
      if (!localStorage.getItem(apiListKey)) {
        localStorage.setItem(apiListKey, JSON.stringify(${builtins.toJSON apiList}));
      }
    })();
  '';

  # Derive a patched copy of zashboard with the init script injected into index.html
  zashboardConfigured = pkgs.runCommand "zashboard-configured" {} ''
    cp -r ${pkgs.zashboard}/. $out
    chmod -R u+w $out
    cp ${initScript} $out/init.js
    sed -i 's|</head>|<script src="/init.js"></script></head>|' $out/index.html
  '';
in {
  # macOS: launchd user agent
  launchd.agents.zashboard = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "-m"
        "http.server"
        (toString servePort)
        "--directory"
        "${zashboardConfigured}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/zashboard.log";
      StandardErrorPath = "/tmp/zashboard-error.log";
    };
  };

  # NixOS: systemd user service
  systemd.user.services.zashboard = lib.mkIf (!pkgs.stdenv.isDarwin) {
    Unit.Description = "Zashboard - Clash Meta Dashboard";
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server ${toString servePort} --directory ${zashboardConfigured}";
      Restart = "on-failure";
    };
    Install.WantedBy = ["default.target"];
  };
}
