# Private executable shared by shell policy and the root daemon; not in PATH.
{pkgs}:
pkgs.writeShellScript "youturn-proxy-private" ''
  exec ${pkgs.python3}/bin/python3 ${./proxy-policy.py} "$@"
''
