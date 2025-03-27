<div align="center">
<img src=".github/logo.png" alt="Sith Happens" width="256" />

# Youturn's [NixOS], [nix-darwin] & [Home Manager] Configurations
<b>Made with 💝 for <img src=".github/nixos.png" align="center" width="18" alt="NixOS"/> & <img src=".github/apple.png" align="center" width="16" alt="macOS"/></b>
<br />
</div>

This repository contains a [Nix Flake](https://zero-to-nix.com/concepts/flakes) for configuring my computers and/or their home environment.
It is not intended to be a drop in configuration for your computer, but might serve as a reference or starting point for your own configuration.
**If you are looking for a more generic NixOS configuration template, I highly recommend [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs).** 👍️
These computers are managed by this Nix flake ❄️

|    Hostname   |        Board       |         CPU         |  RAM |          Primary GPU         |     Secondary GPU    |   Role  |   OS  |    State    |
|:-------------:|:------------------:|:-------------------:|:----:|:----------------------------:|:--------------------:|:-------:|:-----:|:-----------:|
| `SilkSpectre` | MacBook Pro M1 Pro |     Apple M1 Pro    | 16GB |         Apple M1 Pro         |                      |  laptop | macOS |    Ready    |
|  `Rorschach`  |   MacBook Air M4   |       Apple M4      | 16GB |           Apple M4           |                      |  laptop | macOS |    Ready    |
|   `NightOwl`  |     Mac Mini M4    |       Apple M4      | 16GB |           Apple M4           |                      | desktop | macOS |    Ready    |
| `TheComedian` |   Aoostar WTR PRO  |  AMD Ryzen 5 5825U  | 64GB |     AMD Radeon™ Graphics     |                      |  server | NixOS | In progress |
|  `Ozymandias` |   Aoostar WTR MAX  |  AMD Ryzen 7 8845HS | 16GB |     AMD Radeon™ Graphics     |                      |  server | NixOS | In progress |
| `DrManhattan` |   Gigabyte B650M   | AMD Ryzen 9 7950X3D | 64GB | NVIDIA GeForce RTX 4090 24GB | AMD Radeon™ Graphics | desktop | NixOS | In progress |


Laptops and server host names are Watchmen characters.

## Structure

- [.github]: GitHub CI/CD workflows Nix ❄️ supercharged ⚡️ by [**Determinate Systems**](https://determinate.systems)
  - [Nix Installer Action](https://github.com/marketplace/actions/the-determinate-nix-installer)
  - [FlakeHub Cache Action](https://github.com/marketplace/actions/flakehub-cache)
  - [Flake Checker Action](https://github.com/marketplace/actions/nix-flake-checker)
  - [Update Flake Lock Action](https://github.com/marketplace/actions/update-flake-lock)
- [darwin]: macOS configurations
  - Includes full system configuration for a MacBook Air M2 15" and MacBook Pro (Mid 2015)
- [home-manager]: Home Manager configurations
  - Sane defaults for shell and desktop
- [nixos]: NixOS configurations
  - Includes discrete hardware configurations that leverage the [NixOS Hardware modules](https://github.com/NixOS/nixos-hardware).

The [nixos/_mixins] and [home-manager/_mixins] are a collection of composited configurations based on the arguments defined in [flake.nix].

## Installing 💾

- Boot off an .iso image created by this flake using `build-iso console` or `build-iso <desktop>` (*see below*) 💿
- Put the .iso image on a USB drive, I use [USBImager](https://bztsrc.gitlab.io/usbimager/)
- Boot the target computer from the USB drive
- Two installation options are available:
  1 Run `install-system <hostname> <username>` from a terminal
   - The install script uses [Disko] to automatically partition and format the disks, then uses my flake via `nixos-install` to complete a full-system installation
   - This flake is copied to the target user's home directory as `~/Zero/nix-config`
   - `nixos-enter` is used to automatically chroot into the new system and apply the Home Manager configuration
  2 The desktop iso image includes the graphical Calamares installer if an ad-hoc system installation is required
- Make a cuppa 🫖
- Reboot 🥾

#### Useful commands
```bash 
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
```

### Installing to a remote host 🌍

As [Disko] is used to declare the disk layout for all my NixOS hosts, each NixOS configurations can be deployed to a remote host using [nixos-anywhere].
I've created a simple wrapper around `nixos-anywhere` that makes it a bit simpler to deploy a NixOS configuration to a remote host.
For example, `malak` is a Hetzner dedicated server.
To deploy it, enable the Hetzner Rescue system and then execute the following command from one of my workstations:

```bash
install-anywhere malak <ip-address>
```

When the deployment is complete, the remote host will be automatically rebooted.
I keep my Home Manager configuration separate from my NixOS configuration, so after the NixOS configuration has been deployed, I SSH in to the remote host and activate the Home Manager configuration:

```bash
sudo chown -Rv "$USER":users "$HOME/.config"
git clone https://github.com/wimpysworld/nix-config "$HOME/Zero/nix-config"
home-manager switch -b backup --flake "$HOME/Zero/nix-config"
```

## Applying Changes ✨

I clone this repo to `~/Zero/nix-config`. NixOS and Home Manager changes are applied separately because I tend to iterate on the Home Manager configuration more frequently than the NixOS configuration.

```bash
gh repo clone wimpysworld/nix-config "$HOME/Zero/nix-config"
```

- ❄️ **NixOS & macOS:**  A `build-host` and `switch-host` aliases are provided that build the NixOS or nix-darwin configuration and switch to it respectively.
- 🏠️ **Home Manager:**  A `build-home` and `switch-home` aliases are provided that build the Home Manager configuration and switch to it respectively.
- 🌍️ **All:** There are also `build-all` and `switch-all` aliases that build and switch to both the NixOS/nix-darwin and Home Manager configurations.

### ISO 📀

The `build-iso` script is included that creates .iso images from this flake. The following modes are available:

- `build-iso console` (*terminal environment*): Includes `install-system` for automated installation.
- `build-iso pantheon` (*Pantheon Desktop environment*): Includes `install-system` and [Calamares](https://calamares.io/) installation.
- `build-iso lomiri` (*Lomiri Desktop environment*): Includes `install-system` and [Calamares](https://calamares.io/) installation.

Live images will be left in `$HOME/Zero/nix-config/result/iso/` and are also injected into `~/Quickemu/nixos-console` and `~/Quickemu/nixos-<desktop>` respectively.
The console .iso image is also periodically built and published via [GitHub Actions](./.github/workflows) and is available in [this project's Releases](https://github.com/wimpysworld/nix-config/releases).

## What's in the box? 🎁

Nix is configured with [flake support](https://zero-to-nix.com/concepts/flakes) and the [unified CLI](https://zero-to-nix.com/concepts/nix#unified-cli) enabled.

### Structure

Here's the directory structure I'm using:

```
.
├── darwin
│  ├── _mixins
│  │  ├── desktop
│  │  ├── scripts
│  │  └── users
│  ├── momin
│  ├── krall
│  └── default.nix
├── home-manager
│  ├── _mixins
│  │  ├── configs
│  │  ├── desktop
│  │  ├── features
│  │  ├── scripts
│  │  ├── services
│  │  └── users
│  └── default.nix
├── lib
│  └── default.nix
├── nixos
│  ├── _mixins
│  │  ├── configs
│  │  ├── desktop
│  │  ├── features
│  │  ├── scripts
│  │  ├── services
│  │  └── users
│  ├── iso-console
│  ├── iso-pantheon -> iso-console
│  ├── iso-lomiri -> iso-console
│  ├── crawler -> dagger
│  ├── dagger
│  ├── malak
│  ├── phasma
│  ├── revan
│  ├── sidious
│  ├── tanis
│  ├── vader
│  └── default.nix
├── overlays
│  └── default.nix
├── pkgs
│  └── default.nix
├── secrets
│  └── secrets.yaml
└── flake.nix
```
- The NixOS, macOS (darwin) and Home Manager configurations are in the `nixos`, `darwin` and `home-manager` directories respectively, they are structured in a similar way with `_mixins` directories that contain the configurations applied via mixin pattern that compose the final configuration.
- The `lib` directory contains helper functions for the `nixos`, `nix-darwin` and `home-manager` configurations.
- The `overlays` directory hold my custom overlays.
- The `pkgs` directory contains my custom local packages.
- The `secrets` directory contains secrets managed by [sops-nix].
- The `default.nix` files in the root of each directory are the entry points.

### The Shell 🐚

Fish shell 🐟️ with [Starship](https://starship.rs/) 🚀 and a collection of tools that deliver a *"[Modern Unix]"* experience.
The base system has a firewall enabled and also includes [OpenSSH], [sops-nix] for secret management, [Tailscale], [Distrobox](./nixos/_mixins/features/distrobox/default.nix) and, of course, a delightfully configured [micro]. (*Fight me!* 🥊)
Useful shell scripts I used to keep in muddle of git repos are now migrated to [NixOS scripts](./nixos/_mixins/scripts) and [Home Manager scripts](./home-manager/_mixins/scripts) to provide a declarative, reproducible and `shellcheck` validated toolbox 🧰

![fastfetch on Phasma](.github/screenshots/fastfetch.png)

### The Desktop 🖥️

Hyprland 💧 Pantheon 🏛️ and Lomiri 📱 desktop options are available.
The font configuration is common for all desktops using [Work Sans](https://fonts.google.com/specimen/Work+Sans) and [Fira Code](https://fonts.google.com/specimen/Fira+Code).
The usual creature comforts you'd expect to find in a Linux Desktop are integrated such as Pipewire, Bluetooth, Avahi, CUPS, SANE and NetworkManager.

|   Desktops  |        NixOS       |       Home Manager        |       Theme       |
| :---------: | :----------------: | :-----------------------: | :---------------: |
| 💧 Hyprland | [Hyprland NixOS]   | [Hyprland Home Manager]   | Catppuccin Mocha  |
| 🏛️ Pantheon | [Pantheon NixOS]   | [Pantheon Home Manager]   | Catppuccin Mocha  |
| 📱 Lomiri   | [Lomiri NixOS]     |                           | 🚧                |

## Eye Candy 👀🍬

![Hyprland on Shaa](.github/screenshots/hyprland.png)
<div align="center"><small>Hyprland on Shaa; <i>a work in progress; soon to be daily driver</i></small></div>

![Pantheon on Phasma](.github/screenshots/pantheon.png)
<div align="center"><small>Pantheon on Phasma; <i>daily driver</i></small></div>

## Post-install Checklist

Things I currently need to do manually after installation.

### Secrets

- [ ] Provision `/var/lib/private/sops/age/keys.txt`
- [ ] Provision `~/.config/sops/age/keys.txt`
- [ ] Run `gpg-restore`
- [ ] Run `determinate-nixd login`
- [ ] Keybase - `keybase login`
- [ ] Tailscale - `sudo tailscale up --operator="$USER"`
  - Fast switching - <https://tailscale.com/kb/1225/fast-user-switching>
- [ ] 1Password - authenticate
- [ ] LastPass - authenticate

### Accounts

- [ ] Atuin
  - `atuin login -u <username>`
  - `atuin sync -f`
- [ ] Brave - enroll sync
- [ ] Chatterino - authenticate
- [ ] Discord - authenticate
- [ ] GitKraken - authenticate with GitHub
- [ ] Grammarly - authenticate
- [ ] Maelstral - `maestral_qt`
- [ ] Matrix - authenticate
- [ ] Syncthing - Connect API and introduce host
- [ ] Telegram - authenticate
- [ ] VSCode - authenticate with GitHub enable sync
- [ ] Wavebox - authenticate Google and restore profile

### System

`defender` and `fighter` are Ubuntu virtual machines run under [Lima] for my Ubuntu MATE development and testing environments.

- [ ] On Linux run
  - `incus admin init --minimal`
  - `create-defender`
  - `create-fighter`
- [ ] On macOS run
  - `install-homebrew`
  - Run Podman Desktop to create podman machine

#### Malak

- [ ] Create ntfy user and ACLs
  `sudo ntfy user add --role=admin <username>`
  `sudo ntfy access everyone <topic> rw`

### Themes

Some applications require manual configuration to apply the correct theme.

- [ ] Enable [Stylus](https://github.com/openstyles/stylus) Sync to Dropbox to get [Catppuccin userstyles](https://github.com/catppuccin/userstyles/releases/tag/all-userstyles-export) and **Enable Patch CSP**
  - [ ] Brave
  - [ ] Chrome
  - [ ] Chromium
  - [ ] Firefox
  - [ ] Wavebox
- [ ] Cider
  - Open Cider
  - Menu → Marketplace → Themes
  - Find Catppuccin and your favorite flavor
  - Click Install
- [ ] Discord OpenAsar
  - [ ] Add Catppuccin CSS
```css
/* mocha */
@import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css");
@import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha-blue.theme.css");
```

### Windows Boot Manager on multi-disk systems

One of my laptops (`sidious`) is a multi-disk system with Windows 11 Pro 🪟 installed on a separate disk from NixOS.
The Windows EFI partition is not automatically detected by systemd-boot, because it is on a different disk.
The following steps are required to copy the Windows Boot Manager to the NixOS EFI partition so dual-booting is possible.

Find Windows EFI Partition

```shell
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT
```

Mount Windows EFI Partition

```shell
sudo mkdir /mnt/win-efi
sudo mount /dev/nvme1n1p1 /mnt/win-efi
```

Copy Contents of Windows EFI to NixOS EFI

```shell
sudo rsync -av /mnt/win-efi/EFI/Microsoft/ /boot/EFI/Microsoft/
```

Clean up

```shell
sudo umount /mnt/win-efi
sudo rm -rf /mnt/win-efi
```

Reboot and systemd-boot should now offer the option to boot NixOS and Windows.

## Inspirations 🧑‍🏫

Before preparing my NixOS and Home Manager configurations I looked at what other Nix users were doing.
My colleagues shared their configs and tips which included [nome from Luc Perkins], [nixos-config from Cole Helbling], [flake from Ana Hoverbear] and her [Declarative GNOME configuration with NixOS] blog post.
A couple of friends also shared their configurations and here's [Jon Seager's nixos-config] and [Matthew Croughan's nixcfg].

I liked the directory hierarchy in [Jon Seager's nixos-config] and the mixin pattern used in [Matthew Croughan's nixcfg], so my Nix configuration is influenced by both of those.
Ana's excellent [Declarative GNOME configuration with NixOS] blog post was essential to achieving a fully declaritive desktop configuration 🚀

**After I created my initial flake I found [nix-starter-configs] by [Gabriel Fontes](https://m7.rs) which is an excellent starting point**.
I have since incorporated many of the techniques it demonstrates.
Similarly, some of my nix-darwin configuration is inspired by [nix-darwin-kickstarter].

There's plenty to learn from browsing other people's Nix configurations.
I recommend a search of [GitHub nixos configuration] from time to time to see what interesting techniques you pick up and new tools you might discover ️🕵️

My use of [Disko] and automated installation script were inspired by the these blog posts:
- [Setting up my new laptop: nix style](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)
- [Setting up my machines: nix style](https://aldoborrero.com/posts/2023/01/15/setting-up-my-machines-nix-style/)

[nome from Luc Perkins]: https://github.com/the-nix-way/nome
[nixos-config from Cole Helbling]: https://github.com/cole-h/nixos-config
[flake from Ana Hoverbear]: https://github.com/Hoverbear-Consulting/flake
[Declarative GNOME configuration with NixOS]: https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/
[Jon Seager's nixos-config]: https://github.com/jnsgruk/nixos-config
[Matthew Croughan's nixcfg]: https://github.com/MatthewCroughan/nixcfg
[GitHub nixos configuration]: https://github.com/search?q=nixos+configuration
[nix-starter-configs]: https://github.com/Misterio77/nix-starter-configs
[nix-darwin-kickstarter]: https://github.com/ryan4yin/nix-darwin-kickstarter

[NixOS]: https://nixos.org/
[nix-darwin]: https://github.com/LnL7/nix-darwin
[Home Manager]: https://github.com/nix-community/home-manager
[Disko]: https://github.com/nix-community/disko
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
[sops-nix]: https://github.com/Mic92/sops-nix

[.github]: ./github/workflows
[darwin]: ./darwin
[home-manager]: ./home-manager
[nixos]: ./nixos
[nixos/_mixins]: ./nixos/_mixins
[home-manager/_mixins]: ./home-manager/_mixins
[flake.nix]: ./flake.nix
[Modern Unix]: ./home-manager/default.nix
[OpenSSH]: ./nixos/_mixins/services/ssh/default.nix

[micro]: https://micro-editor.github.io/
[Tailscale]: https://tailscale.com/
[Hyprland NixOS]: ./nixos/_mixins/desktop/hyprland/default.nix
[Pantheon NixOS]: ./nixos/_mixins/desktop/pantheon/default.nix
[Lomiri NixOS]: ./nixos/_mixins/desktop/lomiri/default.nix
[Hyprland Home Manager]: ./home-manager/_mixins/desktop/hyprland/default.nix
[Pantheon Home Manager]: ./home-manager/_mixins/desktop/pantheon/default/.nix
