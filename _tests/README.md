# Reliability tests

The strict runner covers generated Mihomo commands/activation, the one-command
management surface, npm activation policy, mutable-config safety, recovery and
validation commands, proxy policy/recovery, and selective iCloud export.
Fixtures use disposable homes/Git repositories and recording
service/export fakes. No live services, real configuration or iCloud files are
changed by these suites.

## Strict run (local and CI)

From the repo root:

```bash
just test                     # all hosts + ISO + strict generated suites
just validate                 # identical entry point
python3 scripts/validate.py --offline  # cached locked inputs only
python3 scripts/validate.py --host NightOwl  # CI's strict regression leg
python3 scripts/validate.py --platform linux # Linux toplevel + ISO
```

The shared runner uses `nix flake check --no-build` plus explicit derivation-path
evaluations for Rorschach, NightOwl, SilkSpectre, the ozymandias toplevel, and the
installer ISO. Flake check alone does not force Darwin `.system`. Host/platform
scopes are deliberately partial; NightOwl (or the default/all-Darwin scope)
always evaluates the projection and runs all three suites below. Every failure
propagates as a nonzero exit; there is no skip-tests switch.

This evaluates configuration; it does not build or activate anything or rewrite
the lockfile. Normal fetching of locked inputs is permitted unless `--offline`
is selected. Formatting is separate (`just fmt-check`, also checked by CI):
`nix fmt` can realize a formatter package and is not in the no-build runner.

The runner creates a private temporary directory and a mode-0600 JSON file,
passes its path through `RELIABILITY_GENERATED_JSON` to `_tests/run.py`, and
removes it on success or failure. Do not upload this private generated data.

`generated-input.nix` projects actual Nix evaluation results. Its expression
is passed as `--apply` text because importing a local absolute path from that
argument is forbidden in pure evaluation. No handwritten Nix renderer or
fabricated configuration is used. The generated data may contain private
configuration: keep it protected, do not print/upload it, and remove it after
use.

The strict runner requires Python 3, Git and `just` (the latter executes recovery
recipes against command spies, never real sudo/rebuild commands). It rejects
missing/malformed input, missing tools, empty suites, failures, errors and **any
skipped tests**. It runs only these suite directories:

- `_tests`
- `scripts/_tests`
- `modules/darwin/mihomo/_tests`

It intentionally does not claim coverage of the separate Claude hook/ShellSpec
suite or recursively discover synthetic/broken hook fixtures. The GitHub
configuration-check workflow runs this same strict entry point in the NightOwl
matrix leg.

## Generated input contract

All fourteen fields are required nonempty strings, synchronized with
`_tests/run.py:REQUIRED_KEYS`:

| Key | Evaluated source |
|---|---|
| `username` | `c.system.primaryUser` |
| `activation` | `c.system.activationScripts.script.text` |
| `autoLoginUser` | `c.system.defaults.loginwindow.autoLoginUser` |
| `mihomo_sync` | installed `mihomo-sync` package's `.text` |
| `management_commands` | matching installed management package names, newline-separated |
| `npm_setup` | `home.home.activation.setupNpm.data` |
| `npm_install_present` | `"yes"` / `"no"` for the `installNpm` activation attribute |
| `git_activation` | `home.home.activation.removeExistingGitconfig.data` |
| `claude_settings_activation` | `home.home.activation.claudeSettings.data` |
| `claude_runtime_activation` | `home.home.activation.claudeRuntimeConfig.data` |
| `codex_activation` | `home.home.activation.codexMergeConfig.data` |
| `shell_init` | `home.programs.zsh.initContent` |
| `shell_proxy_default` | `home.youturn.proxy.default` (`off`, `local`, `network`) |
| `mihomo_daemon` | `builtins.elemAt c.launchd.daemons.mihomo.serviceConfig.ProgramArguments 2` |

Here `c` is the evaluated NightOwl config and `home` its primary user's Home
Manager config. These are real evaluated strings, not source-text substitutes.

## Mutable-state activation contract

- Run app/config writers quiescent during activation. Atomic replacement avoids
  partial files, not concurrent read/modify/write lost updates.
- Git moves an existing `.gitconfig` to a uniquely named sibling
  `.gitconfig.backup-*` before selecting managed XDG configuration. Regular
  backups have owner-only permissions; relative symlinks keep their target
  meaning. No target is deleted. A symlink backup preserves the link, not an
  independent copy or lifetime guarantee of its target. Review backups explicitly;
  activation never prunes them.
- Claude defaults are a recursive live-wins merge (including live arrays);
  runtime config forces only `teammateMode`. Codex managed TOML keys win while
  other runtime keys survive. Existing hook defaults/ownership are preserved.
- Every hook uses HM `run`; helpers also protect direct dry-run invocations.
  JSON/TOML is parsed and serialized before replacement. Mutable config saves
  use private sibling temporary files, fsync and atomic replace. Failures leave
  the original file/symlink intact and clean up temporary files. Dangling mutable
  config symlinks and malformed/non-object JSON fail visibly; empty files seed
  from defaults. Existing symlink targets are never written through.
- `_tests/test_mutable_activation.py` executes real evaluated Git/Claude
  fragments and all four hooks' dry runs with relocated homes and source helper
  paths. It also verifies daemon setup failure prevents engine startup.
- The base Python may lack Codex's pinned `tomli_w`. Filesystem fault tests mock
  only that serializer, while using the real TOML parser and merge code; they
  are not an end-to-end test of the external serializer or full activation.

## Optional source-only checks

`python3 -m unittest discover -s _tests -v` without generated input runs source
and harness checks while explicitly skipping configuration-dependent cases.
That is an incomplete check, not equivalent to the strict run.

## Coverage boundaries

Mihomo validation is mocked in the generated-shell tests to prove ordering and
failure handling. These tests do not demonstrate live launchd behavior, macOS
cloud upload, autologin credential readiness, or package/system builds.

The canonical sync validates after Git updates the checkout and before export
or restart. Validation failure does not reset Git or provide a separate
last-known-good deployment directory. The selective exporter is atomic per
file, not across the whole config set. See the module README for these limits.
