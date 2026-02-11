# OpenClaw Integration Guide

> Reference for integrating OpenClaw into this Nix configuration.
> Covers three installation methods — pick the one that fits your needs.

## Overview

OpenClaw is a self-hosted AI assistant that connects to messaging platforms (Telegram, Discord, WhatsApp, iMessage). It runs as a persistent gateway daemon on your machine.

- **Repository**: https://github.com/openclaw/openclaw
- **Nix module**: https://github.com/openclaw/nix-openclaw
- **Docs**: https://docs.openclaw.ai

### Requirements

- Node.js 22.12.0+ (already provided by `home/common/dev-tools/nodejs/`)
- A messaging platform bot token (e.g. Telegram via @BotFather)
- An AI provider API key (OpenAI, Anthropic, etc.)

---

## Option 1: Nix Home Manager Module (Recommended)

The cleanest integration. OpenClaw is fully managed by Nix with declarative config, automatic launchd service, and rollback support.

### Step 1: Add flake input

In `flake.nix`, add to `inputs`:

```nix
nix-openclaw = {
  url = "github:openclaw/nix-openclaw";
  inputs.nixpkgs.follows = "nixpkgs-unstable";
  inputs.home-manager.follows = "home-manager";
};
```

Add `nix-openclaw` to the `outputs` function arguments:

```nix
outputs = inputs @ {
  self,
  nixpkgs-unstable,
  nixpkgs-stable,
  # ...existing args...
  nix-openclaw,
  ...
}:
```

### Step 2: Apply the overlay

Update `mkPkgs` to include the OpenClaw overlay so `pkgs.openclaw` resolves:

```nix
mkPkgs = nixpkgs: system:
  import nixpkgs {
    config.allowUnfree = true;
    inherit system;
    hostPlatform = system;
    overlays = [
      nix-openclaw.overlays.default
    ];
  };
```

### Step 3: Add to sharedModules

In `mkDarwinHost`, add the Home Manager module:

```nix
home-manager.sharedModules = [
  nixvim.homeModules.nixvim
  nix-openclaw.homeManagerModules.openclaw
];
```

### Step 4: Create the configuration module

Create `home/darwin/openclaw.nix` (or `home/common/openclaw.nix` for cross-platform):

```nix
{ pkgs, config, ... }: {
  programs.openclaw = {
    enable = true;

    # Remove bundled tools you already have or don't need
    excludeTools = [
      "bird"        # bird identification
      "sonoscli"    # Sonos control
      "openhue-cli" # Hue lights
      "camsnap"     # camera snapshots
    ];

    config = {
      gateway = {
        mode = "local";
        # Use agenix for this in production — see secrets section below
        auth.token = "CHANGE-ME-long-random-string";
      };

      channels.telegram = {
        # Path to file containing bot token (agenix-managed)
        tokenFile = "${config.age.secrets.openclaw-telegram-token.path or "/run/agenix/openclaw-telegram-token"}";
        allowFrom = [ 123456789 ]; # Your Telegram user ID (@userinfobot)
        groups."*".requireMention = true;
      };
    };
  };
}
```

### Step 5: Binary cache (optional but recommended)

Add the Garnix cache to avoid long builds. In `modules/darwin/nix-core.nix` (or equivalent):

```nix
nix.settings = {
  substituters = [
    "https://cache.garnix.io"
    # ...existing substituters...
  ];
  trusted-public-keys = [
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    # ...existing keys...
  ];
};
```

### Step 6: Build

```bash
just build
```

The gateway starts automatically via launchd after build.

### Nix module key options

| Option | Default | Description |
|---|---|---|
| `programs.openclaw.enable` | `false` | Enable OpenClaw |
| `programs.openclaw.excludeTools` | `[]` | Tool names to remove from bundled toolchain |
| `programs.openclaw.installApp` | `true` | Install OpenClaw.app to ~/Applications |
| `programs.openclaw.stateDir` | `~/.openclaw` | State directory |
| `programs.openclaw.documents` | `null` | Path to dir with AGENTS.md, SOUL.md, TOOLS.md |
| `programs.openclaw.launchd.enable` | `true` | Run gateway via launchd (macOS) |
| `programs.openclaw.systemd.enable` | `true` | Run gateway via systemd (Linux) |
| `programs.openclaw.bundledPlugins.*` | varies | Enable/disable individual plugins |

### Bundled plugins

| Plugin | Default | Description |
|---|---|---|
| `summarize` | off | Summarize URLs, PDFs, YouTube |
| `peekaboo` | off | Screenshots |
| `oracle` | off | Web search |
| `poltergeist` | off | macOS UI automation |
| `sag` | off | Text-to-speech |
| `imsg` | off | iMessage integration |
| `goplaces` | **on** | Location services |

Enable a plugin:

```nix
programs.openclaw.bundledPlugins.oracle = {
  enable = true;
  config = {};
};
```

---

## Option 2: npm Global Install (Quick Setup)

Uses the existing npm global setup in `home/common/dev-tools/nodejs/`. Fast to get started, but lives outside Nix's control.

### Install

```bash
npm install -g openclaw@latest
```

### Onboard

```bash
openclaw onboard --install-daemon
```

The onboard wizard will:
1. Create `~/.openclaw/` state directory
2. Walk you through channel setup (Telegram, Discord, etc.)
3. Install a launchd agent to keep the gateway running

### Update

```bash
npm install -g openclaw@latest
```

### Managed via activation script

To make this reproducible, add an activation script similar to the existing claude-code pattern.
Create `home/common/openclaw/default.nix`:

```nix
{ pkgs, lib, ... }: {
  home.activation.installOpenClaw = lib.hm.dag.entryAfter ["setupNpm"] ''
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$HOME/.npm-global/bin:$PATH"

    if command -v openclaw &>/dev/null; then
      CURRENT=$(openclaw --version 2>/dev/null || echo "unknown")
      echo "OpenClaw current version: $CURRENT — updating..."
    fi

    npm install -g openclaw@latest
  '';
}
```

### Troubleshooting

If `sharp` fails to build on macOS:

```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
```

If `openclaw` command not found after install, verify `~/.npm-global/bin` is on your PATH (should be, via `home/common/dev-tools/nodejs/default.nix`).

---

## Option 3: From Source

For development or contributing to OpenClaw.

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

For development mode with auto-reload:

```bash
pnpm gateway:watch
```

---

## Secrets Management

Regardless of install method, sensitive values should be managed through agenix (already configured in this repo).

### Secrets to create

| Secret | File | Permission | Description |
|---|---|---|---|
| Telegram bot token | `secrets/openclaw-telegram-token.age` | 0400 | From @BotFather |
| Gateway auth token | `secrets/openclaw-gateway-token.age` | 0400 | Random string for app-gateway auth |
| AI provider API key | `secrets/openclaw-provider-key.age` | 0400 | OpenAI/Anthropic key |

### Adding a secret

1. Add to `secrets/secrets.nix`:

```nix
{
  "openclaw-telegram-token.age".publicKeys = [ rorschach ];
  "openclaw-gateway-token.age".publicKeys = [ rorschach ];
}
```

2. Encrypt:

```bash
RULES=secrets/secrets.nix agenix -e secrets/openclaw-telegram-token.age -i ~/.ssh/id_ed25519
```

3. Add to `modules/common/secrets.nix`:

```nix
age.secrets."openclaw-telegram-token" = {
  file = ../../secrets/openclaw-telegram-token.age;
  path = "${homeDir}/.config/openclaw/telegram-token";
  owner = myvars.username;
  group = userGroup;
  mode = "0400";
};
```

---

## Post-Install Verification

After installing via any method:

```bash
# Check gateway health
openclaw doctor

# View logs
openclaw logs --follow

# Update channel (stable, beta, dev)
openclaw update --channel stable
```

---

## Comparison

| | Nix Module | npm Global | From Source |
|---|---|---|---|
| **Reproducibility** | Full — declarative, rollback | Partial — activation script | Manual |
| **Updates** | `nix flake update` | `npm install -g openclaw@latest` | `git pull && pnpm build` |
| **Service management** | Automatic (launchd/systemd) | Onboard wizard sets up launchd | Manual |
| **Plugin management** | Declarative in Nix | Manual | Manual |
| **Bundled tools** | ~30 packages (trimmable) | None — just the gateway | Dev dependencies |
| **Setup effort** | Medium (flake changes) | Low | High |
| **Best for** | Long-term production use | Quick trial / evaluation | Contributing to OpenClaw |
