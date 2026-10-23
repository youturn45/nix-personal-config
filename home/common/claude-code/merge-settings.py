"""Private mutable JSON activation helper. Run with app writers quiescent.

Defaults are live-wins; runtime forces only teammateMode. Atomic replacement
prevents partial files, not concurrent read/modify/write lost updates.
"""
import json
import os
from pathlib import Path
import stat
import sys
import tempfile


def atomic_write(path, content):
    path = Path(path)
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


def read_json(path):
    if path.is_symlink() and not path.exists():
        raise ValueError('Refusing a dangling config symlink')
    if not path.exists():
        return {}
    content = path.read_text(encoding='utf-8')
    data = json.loads(content) if content.strip() else {}
    if not isinstance(data, dict):
        raise ValueError('Config must be a JSON object')
    return data


def live_wins(defaults, live):
    result = dict(defaults)
    for key, value in live.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = live_wins(result[key], value)
        else:
            result[key] = value
    return result


def apply(mode, path, defaults=None):
    # Also protect direct invocations; HM's `run` normally suppresses execution.
    if os.environ.get('DRY_RUN') or os.environ.get('DRY_RUN_CMD'):
        return
    path = Path(path)
    live = read_json(path)
    if mode == 'defaults':
        if not isinstance(defaults, dict):
            raise ValueError('Defaults must be a JSON object')
        merged = live_wins(defaults, live)
    elif mode == 'runtime':
        merged = dict(live, teammateMode='tmux')
    else:
        raise ValueError('Unknown config ownership policy')
    # Serialize before creating directories or temporary files.
    content = json.dumps(merged, indent=2, ensure_ascii=False) + '\n'
    atomic_write(path, content)


def main(argv):
    try:
        if len(argv) not in (2, 3):
            raise ValueError('Expected mode, destination, and optional defaults JSON')
        defaults = json.loads(argv[2]) if len(argv) == 3 else None
        apply(argv[0], argv[1], defaults)
    except (OSError, ValueError) as exc:
        # Never print file contents, decoder excerpts or runtime credentials.
        print(f'Claude config activation failed ({type(exc).__name__}); original data was not replaced. Check file type, syntax and permissions.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
