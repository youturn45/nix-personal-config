#!/usr/bin/env python3
"""Encrypt a prompted GitHub token, or authenticate a command before activation."""
import argparse
import getpass
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
SECRET = ROOT / "secrets/github-nix.conf.age"


def token_config(token):
    # Reject config injection and catch accidental surrounding text.
    if not re.fullmatch(r"[A-Za-z0-9_]+", token):
        raise ValueError("Token must be a single nonempty value without whitespace.")
    return f"access-tokens = github.com={token}\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("encrypt", "run"))
    parser.add_argument("--identity", type=Path, help="SSH private key for run (defaults to vars)")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="run: -- command [args...]")
    args = parser.parse_args()
    if args.action == "encrypt":
        if args.command:
            parser.error("encrypt takes no command")
        rules = subprocess.check_output(
            ["nix-instantiate", "--eval", "--strict", "--json", str(ROOT / "secrets/secrets.nix")],
            text=True,
        )
        recipients = json.loads(rules)[SECRET.name]["publicKeys"]
        if not recipients:
            raise ValueError("No recipients configured in secrets/secrets.nix")
        plaintext = token_config(getpass.getpass("Dedicated GitHub token (hidden): "))
        command = ["age", "--encrypt"]
        for recipient in recipients:
            command.extend(["--recipient", recipient])
        # Plaintext is passed via stdin, never argv or a temporary file.
        encrypted = subprocess.check_output(command, input=plaintext.encode())
        with tempfile.NamedTemporaryFile(dir=SECRET.parent, delete=False) as output:
            temp_path = Path(output.name)
            output.write(encrypted)
        try:
            os.replace(temp_path, SECRET)
        finally:
            temp_path.unlink(missing_ok=True)
        print("Encrypted secrets/github-nix.conf.age. Stage it with git add before rebuilding.")
        return 0

    command = args.command
    if command[:1] == ["--"]:
        command = command[1:]
    if not command:
        parser.error("run requires -- command [args...]")
    identity = args.identity
    if identity is None:
        name = subprocess.check_output(
            ["nix-instantiate", "--eval", "--strict", "--json", "--expr",
             f'(import {ROOT / "vars"} {{ lib = {{ asserts.assertMsg = p: msg: p; elem = builtins.elem; }}; }}).secretsIdentityName'],
            text=True,
        )
        identity = Path.home() / ".ssh" / json.loads(name)
    plaintext = subprocess.check_output(["age", "--decrypt", "--identity", str(identity), str(SECRET)], text=True)
    prefix = "access-tokens = github.com="
    if not plaintext.startswith(prefix) or token_config(plaintext[len(prefix):].removesuffix("\n")) != plaintext:
        raise ValueError("Encrypted file must contain exactly one GitHub access-tokens setting.")
    env = dict(os.environ)
    env["NIX_CONFIG"] = env.get("NIX_CONFIG", "") + "\n" + plaintext
    # sudo -E in the existing rebuild recipe preserves this for the first switch.
    return subprocess.run(command, env=env).returncode


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        # CalledProcessError includes argv, which never contains the token here.
        print(f"GitHub token setup failed: {error}", file=sys.stderr)
        sys.exit(1)
