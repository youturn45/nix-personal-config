# Python Setup

uv manages projects; Nix manages ambient tools. pip is not used anywhere.

## Overview

| Layer | Managed by | Contents | Config location |
|---|---|---|---|
| Package manager | Nix | `uv` | `home/common/python/default.nix` |
| Ambient CLI tools | Nix | `ruff` (ad-hoc lint/format, editor format-on-save) | `home/common/python/default.nix` |
| Jupyter server | Nix | `python312.withPackages`: `jupyterlab`, `jupyter-client`, `ipykernel`, `ipython` | `home/common/python/default.nix` |
| Project runtime deps | uv | whatever the code imports | each repo's `pyproject.toml` `[project] dependencies` |
| Project dev tools | uv | `pytest`, `mypy`, pinned `ruff`, `ipykernel`, … | each repo's `[dependency-groups] dev` |
| One-off tools | uv | anything not worth installing | `uvx <tool>` (no install) |
| Interpreters (macOS) | uv | managed CPython in `~/.local/share/uv/python/` | uv default, no config |
| Interpreters (NixOS) | Nix | the Nix Python | `~/.config/uv/uv.toml` (`python-preference = "system"`, Linux-only) |

## Where does a package go?

Ask these questions in order:

1. **Does my code `import` it at runtime?** → `uv add <pkg>` (runtime dependency).
2. **Does it need to see the project's code/deps to work** (test runner, type checker, kernel)? → `uv add --dev <pkg>`. A global install of these is useless by construction.
3. **Is it a self-contained tool I use across all projects on scratch files** (formatter, linter)? → Nix, as a **top-level package** (`pkgs.ruff`) in `home/common/python/default.nix`. *Additionally* pin it per-project with `uv add --dev` in any repo where CI enforces its output — tool versions change what "clean" means.
4. **Is it infrastructure serving all projects** (Jupyter server)? → Nix, inside `python312.withPackages`. This is the only legitimate use of `withPackages` — things that must share one Python environment.
5. **Do I need it once, right now?** → `uvx <tool>`, install nothing.

Rule of thumb for 1 vs 2: if you deleted every `import` of it and the app still runs, it's `--dev`.

## Daily workflows

**New project:**

```bash
uv init myproject && cd myproject
uv add httpx polars                  # runtime deps
uv add --dev pytest ruff mypy        # workbench tools, pinned in uv.lock
uv run pytest                        # runs in .venv — no activation, ever
```

**Notebooks:** the JupyterLab server is global (Nix); each project registers its own kernel so notebooks see that project's packages:

```bash
uv add --dev ipykernel
uv run python -m ipykernel install --user --name myproject
```

**Upgrading a pinned tool** (deliberate, per-repo, churn in one commit):

```bash
uv lock --upgrade-package ruff
uv run ruff format . && uv run ruff check --fix .
```

**Scratch venv** (pip-style escape hatch, throwaway experiments):

```bash
uv venv && uv pip install whatever   # uv pip targets .venv by default
```

**Reproduce an env exactly:** `uv sync` (add `--no-dev` for a production-shaped env).

## Interpreters

- **macOS:** uv downloads managed CPython builds into `~/.local/share/uv/python/`. These survive `nix flake update` and garbage collection. Venvs built on the Nix Python would break on GC (the `/nix/store` path they reference disappears) — that's why `python-preference` is *not* set on Darwin.
- **NixOS:** uv-managed interpreters are dynamically linked against paths that don't exist on NixOS, so `uv.toml` forces `python-preference = "system"` (the Nix Python). Binary wheels additionally need the system libraries put on `LD_LIBRARY_PATH` by the Linux block of the module.
- Pin a project's Python with `requires-python` in `pyproject.toml` or a `.python-version` file; fetch new versions with `uv python install 3.13`.

Networking note: uv talks to the default PyPI index and honors shell `HTTP(S)_PROXY` vars (see [proxy.md](proxy.md)).

## Deliberately absent — do not reintroduce

| Removed | Why |
|---|---|
| `pip` | uv replaces it entirely |
| `black` | `ruff format` is a drop-in replacement; neovim uses `ruff_format` |
| `UV_SYSTEM_PYTHON=1` | made `uv pip` target the read-only Nix store Python **and** ignore active venvs |
| aliases shadowing tools (`pip = "uv pip"`, `python = "uv run python"`, `ruff = "uv run ruff"`, …) | forced every invocation through a project env that may not declare the tool; shadowed the Nix copies |
| zsh `chpwd` auto-activate hook | `uv venv` recreates (wipes) an existing `.venv`; `uv run` makes activation unnecessary |
| `UV_CONFIG_DIR`, `UV_CACHE_DIR` | not a real uv variable / restates the default |
