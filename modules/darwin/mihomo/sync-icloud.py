#!/usr/bin/env python3
"""One-way local copy of important mihomo config into an iCloud Drive folder.

Selects config.yaml (required) plus ruleset/**/*.yaml and *.yml (optional).
Everything else in the source is ignored. Nothing is ever deleted and the
source is never written. Every selected path is validated before the first
write; files are replaced atomically and written with mode 0600.
"""

import argparse
import os
import stat
import sys
import tempfile
from pathlib import Path

PRIMARY_CONFIG = "config.yaml"
RULESET_DIR = "ruleset"
RULESET_SUFFIXES = (".yaml", ".yml")
FILE_MODE = 0o600
DIR_MODE = 0o700
PROG = "mihomo iCloud export"


class SyncError(Exception):
    """A validation or copy failure; the message never contains file contents."""


def lstat_or_none(path):
    try:
        return os.lstat(path)
    except FileNotFoundError:
        return None


def is_within(path, root):
    return path == root or root in path.parents


def resolve_destination(destination):
    parent = destination.parent
    if not parent.is_dir():
        raise SyncError(f"destination parent does not exist: {parent}")
    return parent.resolve() / destination.name


def validate_roots(source, destination):
    source_st = lstat_or_none(source)
    if source_st is None:
        raise SyncError(f"source does not exist: {source}")
    if stat.S_ISLNK(source_st.st_mode):
        raise SyncError(f"source root is a symlink: {source}")
    if not stat.S_ISDIR(source_st.st_mode):
        raise SyncError(f"source is not a directory: {source}")

    dest_st = lstat_or_none(destination)
    if dest_st is not None:
        if stat.S_ISLNK(dest_st.st_mode):
            raise SyncError(f"destination root is a symlink: {destination}")
        if not stat.S_ISDIR(dest_st.st_mode):
            raise SyncError(f"destination is not a directory: {destination}")

    real_source = source.resolve()
    real_destination = resolve_destination(destination)
    if is_within(real_source, real_destination) or is_within(
        real_destination, real_source
    ):
        raise SyncError("source and destination overlap")


def require_regular_file(path, label):
    st = lstat_or_none(path)
    if st is None:
        raise SyncError(f"{label} is missing: {path}")
    if stat.S_ISLNK(st.st_mode):
        raise SyncError(f"{label} is a symlink: {path}")
    if not stat.S_ISREG(st.st_mode):
        raise SyncError(f"{label} is not a regular file: {path}")
    return st


def select_primary_config(source):
    path = source / PRIMARY_CONFIG
    if require_regular_file(path, "primary config").st_size == 0:
        raise SyncError(f"primary config is empty: {path}")
    return Path(PRIMARY_CONFIG)


def raise_error(err):
    raise err


def select_rulesets(source):
    ruleset_root = source / RULESET_DIR
    st = lstat_or_none(ruleset_root)
    if st is None:
        return []
    if stat.S_ISLNK(st.st_mode):
        raise SyncError(f"ruleset directory is a symlink: {ruleset_root}")
    if not stat.S_ISDIR(st.st_mode):
        return []

    selected = []
    for current, dirnames, filenames in os.walk(ruleset_root, onerror=raise_error):
        current = Path(current)
        for name in dirnames:
            if (current / name).is_symlink():
                raise SyncError(f"ruleset directory is a symlink: {current / name}")
        for name in filenames:
            if not name.endswith(RULESET_SUFFIXES):
                continue
            path = current / name
            require_regular_file(path, "ruleset file")
            selected.append(path.relative_to(source))
    return sorted(selected)


def check_target(destination, relative):
    ancestor = destination
    for part in relative.parent.parts:
        ancestor = ancestor / part
        st = lstat_or_none(ancestor)
        if st is None:
            return
        if stat.S_ISLNK(st.st_mode):
            raise SyncError(f"destination directory is a symlink: {ancestor}")
        if not stat.S_ISDIR(st.st_mode):
            raise SyncError(f"destination path is not a directory: {ancestor}")

    target = destination / relative
    st = lstat_or_none(target)
    if st is None:
        return
    if stat.S_ISLNK(st.st_mode):
        raise SyncError(f"destination file is a symlink: {target}")
    if not stat.S_ISREG(st.st_mode):
        raise SyncError(f"destination path is not a regular file: {target}")


def build_plan(source, destination):
    validate_roots(source, destination)
    plan = [select_primary_config(source)] + select_rulesets(source)
    for relative in plan:
        check_target(destination, relative)
    return plan


def read_source(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(fd, "rb") as handle:
        return handle.read()


def target_matches(target, data):
    st = lstat_or_none(target)
    if st is None or stat.S_IMODE(st.st_mode) != FILE_MODE:
        return False
    with open(target, "rb") as handle:
        return handle.read() == data


def make_directory(path):
    if lstat_or_none(path) is not None:
        return
    os.mkdir(path, DIR_MODE)
    os.chmod(path, DIR_MODE)


def make_parents(destination, relative):
    make_directory(destination)
    current = destination
    for part in relative.parent.parts:
        current = current / part
        make_directory(current)


def write_atomically(target, data):
    fd, temp_name = tempfile.mkstemp(
        dir=target.parent, prefix=f".{target.name}.", suffix=".tmp"
    )
    try:
        with os.fdopen(fd, "wb") as handle:
            os.fchmod(handle.fileno(), FILE_MODE)
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, target)
    except BaseException:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def copy_plan(source, destination, plan):
    copied = 0
    for relative in plan:
        data = read_source(source / relative)
        target = destination / relative
        if target_matches(target, data):
            continue
        make_parents(destination, relative)
        write_atomically(target, data)
        copied += 1
    return copied


def sync(source, destination, dry_run):
    """Copy the selected files; returns (selected, copied) counts."""
    plan = build_plan(source, destination)
    if dry_run:
        return len(plan), 0
    return len(plan), copy_plan(source, destination, plan)


def parse_args(argv):
    parser = argparse.ArgumentParser(prog=PROG, description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    source = Path(os.path.abspath(args.source))
    destination = Path(os.path.abspath(args.destination))
    try:
        selected, copied = sync(source, destination, args.dry_run)
    except (SyncError, OSError) as err:
        print(f"{PROG}: error: {err}", file=sys.stderr)
        return 1

    if args.dry_run:
        print(f"{PROG}: dry run: {selected} file(s) selected, nothing written")
    else:
        print(
            f"{PROG}: {selected} file(s) selected, {copied} copied, "
            f"{selected - copied} unchanged"
        )
    print(
        f"{PROG}: local one-way copy to {destination}; "
        "this tool does not upload, iCloud Drive syncs it separately"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
