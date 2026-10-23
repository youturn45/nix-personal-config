# Mihomo sync

`mihomo-sync` is the only public management command. It updates the config,
copies the important mihomo config from
`~/.config/clash.meta` into `~/Library/Mobile Documents/com~apple~CloudDocs/Mihomo`
(the personal iCloud Drive folder `Mihomo`). Both paths are fixed by the Nix
command in `default.nix`; the internal helper is `sync-icloud.py` (Python standard library only).

## What is copied

- `config.yaml` — required; the run aborts if it is missing or empty.
- `ruleset/**/*.yaml` and `ruleset/**/*.yml` — optional.

Nothing else is copied. Caches, `proxies/`, `rules/`, geodata, `.git`, logs and
Tailscale state are all left out because only the files above are selected.

## Guarantees

- **One-way.** The source is never written. Nothing in the destination is
  deleted: files removed upstream and unrelated files you put in `Mihomo/` stay.
- **Local copy only.** The tool writes to the local iCloud Drive folder and
  does not upload anything. macOS uploads the folder separately.
- **Manual, not a watcher.** Files are copied only when the command runs; edits
  made later are not picked up until the next run.
- **Validated before writing.** Every selected path is checked before the first
  write. A missing `Mihomo/` folder is created. The run is refused if the source
  is missing; if an existing destination is not a plain directory; if the
  iCloud parent folder is missing (the tool never creates it); if the source and
  destination overlap; or if any symlink is found (the source root, `ruleset/`
  or a directory under it, a selected file, the destination root, or a
  destination directory or file).
- Each file is written to a temp file in its target directory and then renamed
  into place. Files get mode `0600`; new directories get `0700`. File contents
  are never printed.
- **Limits.** The checks run before copying, not at every step, so a path
  swapped for a symlink mid-run is not reliably caught. A failure part-way
  leaves the files already copied in place; rerun after fixing the cause.

**`config.yaml` may contain secrets** (subscription URLs, tokens, the controller
secret). The destination is your personal iCloud Drive, so those secrets are
stored in iCloud too. Do not share the `Mihomo` folder.

## Usage

```bash
mihomo-sync   # safe config update, engine validation, iCloud export, then restart
```

On first use it clones the config repository. For an existing checkout it
refuses uncommitted/untracked changes, requires the current branch's upstream,
and updates with `git pull --ff-only`. It never discards local work or guesses
a branch. A Git failure means no export or restart.

After Git succeeds, the same Mihomo engine used by the daemon checks the
configuration with `-t -d`. A validation failure stops the command before any
export or launchd action. Parser output is suppressed because errors can
contain secrets; inspect details privately with `mihomo -t -d ~/.config/clash.meta`.

**This is preflight, not transactional deployment.** The checkout has already
advanced when validation fails; it is not automatically reset, and there is
no separate last-known-good deployment directory. Fix the upstream config or
explicitly revert it before retrying. Engine testing can also access providers
or initialize files in the checkout; it is not guaranteed offline/read-only.

If the iCloud copy fails, the restart still runs, then
`mihomo-sync` prints a warning and exits with a nonzero status.

The obsolete `sync_clash` and `mihomo-reload` commands are no longer installed
by this configuration; there are no compatibility aliases. Restart logic and
the export helper remain internal to `mihomo-sync`. The required `mihomo`
engine is retained. No files are copied into old Clash application folders,
and existing application/configuration/cloud folders are not deleted.

Changes to the helper or the wrapper take effect after a Nix rebuild
(`darwin-rebuild switch`).

## Activation bootstrap

`darwin-rebuild switch` prepares Mihomo inside nix-darwin's `launchd`
activation step (`lib.mkBefore`), before the system daemon is loaded. A custom
`system.activationScripts.<name>` would never run: nix-darwin only executes its
own fixed list of activation scripts. The step:

1. boots out the obsolete per-user `gui/<uid>/io.github.metacubex.mihomo` job;
2. creates `~/Library/Logs/mihomo` and its log files, owned by the user;
3. clones the config repo once, as the user, if `~/.config/clash.meta/.git`
   is missing. Existing checkouts are never updated here; use `mihomo-sync`.

A missing SSH key (`~/.ssh/Youturn`), a failed clone, or a failed log setup
aborts activation with a `mihomo: FATAL:` message instead of loading the daemon
against a missing config.

## Proxy startup ownership

The daemon and `proxy macos-on/off` share the private helper under
`home/common/terminal/shells/`. It uses `/usr/sbin/networksetup`, skips disabled
and virtual/VPN services, and counts/reports failures by service and action.
The daemon starts its engine only after system proxy setup succeeds. There is
no TCP precheck in this path: the engine has not started yet. Setup failure
exits visibly (KeepAlive may retry), never launching a falsely healthy engine.
No additional public management command is installed, and the sync/export,
preflight, and activation workflows above are unchanged.

See [`docs/proxy.md`](../../../docs/proxy.md) for shell platform defaults,
explicit direct-mode opt-in, bypass policy, and the separate nix-daemon owner.
These source/test changes do not constitute live deployment or a restart.

## Tests

```bash
python3 -m unittest discover -s modules/darwin/mihomo/_tests
python3 -m unittest discover -s _tests   # activation + mihomo-sync wrapper
```

The tests use synthetic fixtures in temporary directories only.

For the generated-command and activation regression tests, first export real
Nix evaluation output as described in [`../../../_tests/README.md`](../../../_tests/README.md).
Without that input, those integration tests are explicitly skipped; only source
invariants run. Proxy helper tests run with:

```bash
python3 -m unittest discover -s scripts/_tests -v
```

The integration suite runs the generated commands and activation fragment in a
sandbox with fake `sudo`, `launchctl`, ownership changes and iCloud export; it
never executes the full activation script or touches real services.
