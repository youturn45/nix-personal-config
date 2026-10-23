#!/usr/bin/env python3
"""Shared locked-input, no-build evaluation and strict regression entry point."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
DARWIN_HOSTS = ("Rorschach", "NightOwl", "SilkSpectre")
LINUX_HOST = "ozymandias"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    scope = parser.add_mutually_exclusive_group()
    scope.add_argument("--host", choices=(*DARWIN_HOSTS, LINUX_HOST))
    scope.add_argument("--platform", choices=("darwin", "linux"))
    parser.add_argument("--offline", action="store_true", help="use only cached locked inputs")
    args = parser.parse_args(argv)
    flags = ["--no-write-lock-file"] + (["--offline"] if args.offline else [])
    hosts = [args.host] if args.host else (list(DARWIN_HOSTS) if args.platform == "darwin" else
            [LINUX_HOST] if args.platform == "linux" else [*DARWIN_HOSTS, LINUX_HOST])

    def run(command, **kwargs):
        print("+ " + " ".join(command[:command.index("--apply")] if "--apply" in command else command), flush=True)
        subprocess.run(command, cwd=ROOT, check=True, **kwargs)

    try:
        run(["nix", "flake", "check", "--no-build", *flags])
        for host in hosts:
            target = (f"darwinConfigurations.{host}.system.drvPath" if host in DARWIN_HOSTS else
                      f"nixosConfigurations.{host}.config.system.build.toplevel.drvPath")
            run(["nix", "eval", "--raw", *flags, f".#{target}"])
            if host == LINUX_HOST:
                run(["nix", "eval", "--raw", *flags, ".#packages.x86_64-linux.ozymandias-iso.drvPath"])
        # CI's NightOwl matrix leg and default local runs use the exact same strict suites.
        if "NightOwl" in hosts:
            with tempfile.TemporaryDirectory(prefix="nix-validation-") as directory:
                path = Path(directory) / "generated.json"
                with open(path, "x", opener=lambda p, f: os.open(p, f, 0o600)) as output:
                    run(["nix", "eval", "--json", *flags, ".#darwinConfigurations.NightOwl.config",
                         "--apply", (ROOT / "_tests/generated-input.nix").read_text()], stdout=output)
                env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", RELIABILITY_GENERATED_JSON=str(path))
                run([sys.executable, "_tests/run.py"], env=env)
    except subprocess.CalledProcessError as exc:
        print(f"Validation failed (exit {exc.returncode})", file=sys.stderr)
        return exc.returncode if exc.returncode > 0 else 1
    except OSError as exc:
        print(f"Validation unavailable: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
