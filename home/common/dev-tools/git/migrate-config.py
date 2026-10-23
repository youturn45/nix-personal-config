"""Preserve legacy .gitconfig before using the Nix-managed XDG configuration.

Run with Git/config writers quiescent. Backups share the original parent so
relative symlinks retain their meaning; their targets are never changed.
"""
import os
from pathlib import Path
import stat
import sys
import tempfile


def migrate(path):
    path = Path(path)
    if os.environ.get('DRY_RUN') or os.environ.get('DRY_RUN_CMD'):
        return None
    if not os.path.lexists(path):
        return None
    info = path.lstat()
    if not (stat.S_ISREG(info.st_mode) or stat.S_ISLNK(info.st_mode)):
        raise ValueError('Legacy Git configuration is not a file or symlink')
    fd, name = tempfile.mkstemp(prefix=path.name + '.backup-', dir=path.parent)
    placeholder = os.fstat(fd)
    os.close(fd)
    backup = Path(name)
    try:
        # Restrict regular-file access before moving, so no public backup window.
        # Symlink permissions are deliberately untouched (chmod follows links).
        if stat.S_ISREG(info.st_mode):
            path.chmod(stat.S_IMODE(info.st_mode) & 0o600)
        os.replace(path, backup)
    except BaseException:
        # Only remove the original empty placeholder, never promoted data if
        # interrupted immediately after rename. Recovery may find the backup.
        saved = backup.lstat()
        if (saved.st_dev, saved.st_ino) == (placeholder.st_dev, placeholder.st_ino):
            backup.unlink()
        if stat.S_ISREG(info.st_mode) and path.exists():
            current = path.lstat()
            if (current.st_dev, current.st_ino) == (info.st_dev, info.st_ino):
                path.chmod(stat.S_IMODE(info.st_mode))
        raise
    print(f'Git: preserved legacy configuration at {backup}; review before removing this backup.', file=sys.stderr)
    return backup


def main(argv):
    try:
        if len(argv) != 1:
            raise ValueError('Expected legacy config path')
        migrate(argv[0])
    except (OSError, ValueError) as exc:
        print(f'Git configuration migration failed ({type(exc).__name__}); resolve the legacy path before retrying.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
