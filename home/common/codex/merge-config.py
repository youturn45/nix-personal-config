"""Merge Nix-managed Codex settings into the mutable user config.toml.

Nix-managed keys always win; keys Codex writes at runtime (project trust,
TUI state, migration notices) are preserved.

Usage: merge-config.py <config.toml> <managed.toml>
"""

import os
import pathlib
import stat
import sys
import tempfile
import tomllib

import tomli_w


def read_toml(path: pathlib.Path) -> dict:
    if not path.exists():
        return {}
    content = path.read_text()
    if not content.strip():
        return {}
    return tomllib.loads(content)


def merge(runtime: dict, managed: dict) -> dict:
    result = dict(runtime)
    for key, value in managed.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def atomic_write(path, content):
    """Replace a sibling temp file; run with application writers quiescent."""
    mode = 0o600
    if path.exists() and not path.is_symlink():
        mode = stat.S_IMODE(path.stat().st_mode) & 0o600
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f'.{path.name}.', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as output:
            os.fchmod(output.fileno(), mode)
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.replace(name, path)
    finally:
        if os.path.lexists(name):
            os.unlink(name)


def main() -> None:
    if os.environ.get('DRY_RUN') or os.environ.get('DRY_RUN_CMD'):
        return
    config_path = pathlib.Path(sys.argv[1])
    managed_path = pathlib.Path(sys.argv[2])
    if config_path.is_symlink() and not config_path.exists():
        raise ValueError('Refusing a dangling config symlink')
    runtime = read_toml(config_path)
    managed = read_toml(managed_path)
    # Serialize first: failure must not unlink an existing config or symlink.
    content = tomli_w.dumps(merge(runtime, managed))
    atomic_write(config_path, content)


if __name__ == "__main__":
    main()
