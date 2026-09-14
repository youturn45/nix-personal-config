"""Merge Nix-managed Codex settings into the mutable user config.toml.

Nix-managed keys always win; keys Codex writes at runtime (project trust,
TUI state, migration notices) are preserved.

Usage: merge-config.py <config.toml> <managed.toml>
"""

import pathlib
import sys
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


def main() -> None:
    config_path = pathlib.Path(sys.argv[1])
    managed_path = pathlib.Path(sys.argv[2])

    runtime = read_toml(config_path)
    managed = read_toml(managed_path)

    config_path.parent.mkdir(parents=True, exist_ok=True)
    if config_path.is_symlink():
        config_path.unlink()
    config_path.write_text(tomli_w.dumps(merge(runtime, managed)))


if __name__ == "__main__":
    main()
