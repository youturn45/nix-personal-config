{
  lib,
  haumeaLib,
}: {
  /**
  Collect nix module files in a directory recursively.  Rules are as follows:

  - Files and directories starting with `_` are ignored.
  - The `default.nix` file **directly** under that directory is ignored.
  - If one sub directory containing a `default.nix` file, only that `default.nix` file is included and other files are ignore
  # Inputs

  `dir`

  : Directory to search for modules

  # Type

  ```
  collectModulesRecursively :: Path -> [Path]
  ```

  # Example

  ```console
  $ tree /path/to/modules
  ├── default.nix
  ├── _hardening
  │   └── zoom.nix
  ├── network
  │   ├── acme
  │   │   ├── backends
  │   │   │   ├── certbot.nix
  │   │   │   ├── default.nix
  │   │   │   └── lego.nix
  │   │   ├── default.nix
  │   │   ├── foo.sh
  │   │   └── utils.nix
  │   ├── _caddy.nix
  │   └── nginx.nix
  └── sshd.nix
  ```

  ```nix
  collectModulesRecursively /path/to/modules
  =>
  [
    /path/to/modules/network/acme/default.nix
    /path/to/modules/network/nginx.nix
    /path/to/modules/sshd.nix
  ]
  ```
  */
  collectModulesRecursively = dir: let
    isFile = x: !lib.isAttrs x;
    transformer = cursor: value: let
      isRootDir = cursor == [];
      hasDefaultDotNixFile = lib.hasAttr "default" value && isFile value.default;
      transformer' = defaultDotNixFilePolicy:
        if defaultDotNixFilePolicy == "replace"
        then
          if hasDefaultDotNixFile
          then value.default
          else value
        else if defaultDotNixFilePolicy == "exclude"
        then
          if hasDefaultDotNixFile
          then lib.filterAttrs (name: _: name != "default") value
          else value
        else throw "collectModulesRecursively: unknow poilcy for default.nix";
    in
      transformer' (
        if isRootDir
        then "exclude"
        else "replace"
      );
    load = src:
      haumeaLib.load {
        inherit src transformer;
        loader = haumeaLib.loaders.path;
      };
  in
    lib.collect isFile (load dir);
}
