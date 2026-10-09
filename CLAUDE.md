# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

NixOS configuration for three hosts (`prts` home server, `spla-desktop-wsl`, `spla-laptop-wsl`), built on [den](https://den.denful.dev) (dendritic aspects on flake-parts). `README.md` is leftover template boilerplate and does not describe this repo (no `hosts.nix`, `vm.nix` or `igloo` exist).

The home server's name is **PRTS**: write it that way in prose and in any displayed text (e.g. Kanidm display names). Lowercase `prts` is only for identifiers: the hostname, `den.hosts` / aspect names, paths like `modules/hosts/prts/`, group names like `prts_admins`.

## Commands

```console
nix flake check                      # just check — what CI runs
nix build .#nixosConfigurations.prts.config.system.build.toplevel   # CI also builds prts
nix run .#<host>                     # build a host via nh (apps from modules/nh-helper-script.nix)
nix run .#<host> -- switch           # any other nh action
nh os switch .                       # just switch — switch the current machine
nix run .#write-flake                # just write-flake — regenerate flake.nix
nix repl .                           # just repl
```

Format Nix with `nixfmt`.

## flake.nix is generated

`flake.nix` is written by flake-file — never edit it by hand. Inputs are declared with `flake-file.inputs.<name>` inside the module that uses them (e.g. `nixos-wsl` in `modules/core/wsl.nix`, disko in `modules/programs/disko.nix`), then `nix run .#write-flake` regenerates `flake.nix`. `nixpkgs` follows `stable`; the release is set once by `stableVersion` in `modules/dendritic.nix` and reused by release-pinned inputs (home-manager, nixos-wsl). Unstable packages are available as `pkgs.unstable.<name>` (overlay in `modules/core/unstable-pkgs.nix`).

## Architecture

Every `.nix` file under `modules/` is a flake-parts module auto-loaded by import-tree — there is no import list to update. Files/dirs whose path contains a `_` prefix (e.g. `_settings-type.nix`) are skipped by import-tree and used as plain `import`ed helpers. `.md` files next to modules document design decisions.

Key den concepts as used here:

- **Hosts** are declared with `den.hosts."<system>"."<name>"` (users, host facts like `wsl.enable`, `zfs.enable`, `nvidia.enable`, and `settings`). Each host has a same-named aspect `den.aspects."<name>"` that `includes` what it needs.
- **Aspects** (`den.aspects.<path>`) bundle per-class config: `nixos`, `homeManager`, `user` (→ `users.users.<name>`), `wsl` (→ NixOS-WSL `wsl.*`). Sub-aspects are declared with `_.<name>` and referenced as `den.aspects.foo.<name>` (e.g. `programs.starship.nushell-prompt`, `services.auto-upgrade.allow-reboot`). Opt-in features are sub-aspects that a host/profile includes, not boolean options.
- **Parametric aspects** are functions of `{ host }`, `{ user }` or `{ host, user }` (see `modules/users/primary-user.nix`, `modules/users/songpola/default.nix`).
- **Profiles** (`modules/profiles/`): `base` (shell/CLI tooling, network diagnostics, every host), `server` (hardware hosts: SSH, getty, smartd, `programs.sysadmin-tools.{hardware,performance}`), `interactive` (auto-included on WSL hosts via `den.aspects.wsl`).
- **Host-schema options + policies**: `modules/core/{zfs,nvidia,wsl}.nix` add an `enable` fact to `den.schema.host` and a `den.policies.*` that auto-includes the matching aspect when the host enables it; the aspects' tunables are settings (`settings.zfs.hostId`, `settings.nvidia.driverBranch`). `core/wsl.nix` replaces den's built-in WSL battery (see `core/wsl.md`).
- **Aspect settings** (`modules/aspect-settings/`): an aspect may declare typed options under `settings = { ... }`; hosts set them at `den.hosts...settings.<aspect path>` and the aspect reads `host.settings.<aspect path>` (example: `services/tailscale.nix`, set in `hosts/prts/default.nix`).
- **Quirks** (`den.quirks.<name>`): data many aspects publish and one consumes, read as a class-module argument (`nixos = { caddy-sites, ... }:`). Producers may be functions of `{ host, ... }`. Example: `services.kanidm` emits `caddy-sites`, `services.caddy-reverse-proxy` turns them into labels and network aliases.
- `den.default` applies to all hosts (hostname battery, home-manager `useGlobalPkgs`/`useUserPackages`, unstable overlay). User classes are `homeManager` + `user`, with `host-aspects` forwarding so host-included aspects reach users (`modules/defaults.nix`).

### Choosing a mechanism

Den offers overlapping ways to do the same thing (see den's "Choosing a Mechanism" and "Aspect Settings" docs). Pick by what the value is:

- **A value a host sets for one aspect** → that aspect's `settings`. An aspect reads only its own `host.settings.<own path>`; reading an included aspect's settings is limited to its public interface (e.g. `services.caddy-reverse-proxy.network` for containers that join it). A value two aspects need belongs to a third aspect both include, which exposes it through NixOS config (e.g. `security.acme-cloudflare` → `security.acme.defaults`).
- **A fact about the host** that policies or several aspects branch on → a `den.schema.host` option (`zfs.enable`, `nvidia.enable`, read by `programs.btop`), with a policy if it auto-includes an aspect. Only the fact goes there; the aspect's tunables are settings.
- **Config that depends on the host or user being evaluated** → a class module taking `{ host, ... }` or a parametric aspect (`primary-user`).
- **Data other aspects publish for one aspect to collect** (sites, snippets, ports) → a quirk, not a NixOS option declared inside the aspect.
- **Optional parts of an aspect** → sub-aspects (`_.<name>`) that hosts include, not boolean settings.
- Don't write argument-taking factory aspects (`den.batteries.user-shell "fish"` style): they're untyped and two includes with different arguments both apply. Use settings.
- Declare `settings` on the static aspect attrset, never inside a function-valued aspect, or the generator won't see them.

### prts

`modules/hosts/prts/`, split by concern (`default.nix` host facts and profiles, `hardware.nix`, `disks.nix`, `network.nix`, `containers.nix`, `auth.nix`): ZFS (`tank` pool), NVIDIA legacy 580 driver, systemd-networkd bridge, disko layout, `facter.json` hardware report. Containers run on rootful Podman (overlay storage on the `@containers` btrfs subvolume, named volumes in `/tank/v2/podman-volumes`). Infrastructure containers are Nix-managed `virtualisation.oci-containers` in reusable aspects configured through host settings: `services.caddy-reverse-proxy` (caddy-docker-proxy), `services.oauth2-proxy`, `services.dockhand` and `services.dozzle` (`modules/services/`). Kanidm (`services.kanidm`) runs natively on the host with its own ACME certificate; Caddy proxies to it through `host.containers.internal` (a `caddy-sites` entry). Both get certificates from the `security.acme-cloudflare` account (DNS-01, token from `secrets/cloudflare.secrets.yaml`). Kanidm provisions persons, groups and the oauth2-proxy OIDC client from `auth.nix`; oauth2-proxy is the forward-auth gate, and sites opt in with `caddy.import: auth <group>` (groups as Kanidm sends them, `prts_admins@idm.songpola.dev`); Nix-managed services do it through a `forward-auth` sub-aspect. Application stacks are managed outside Nix by Dockhand (deployed in `/tank/v2/services/dockhand/stacks/<stack>/compose.yaml`); `modules/hosts/prts/stacks/` keeps copies of the stacks written here, in the same layout. Apps are exposed by joining the external `caddy` network and setting `caddy` / `caddy.reverse_proxy` labels. Service data lives under `/tank/v2/...`.

### Secrets

sops-nix with age; recipients in the root `.sops.yaml` (local dev key + each host). Encrypted files are `*.secrets.{yaml,env}`, kept in the host directory that uses them (e.g. `modules/hosts/prts/secrets/`) and passed to reusable aspects through settings. Hosts decrypt with their SSH ed25519 host key; the local dev age key is kept in 1Password, and `just sops-edit <file>` edits a file with it (`op.exe read`, the Windows 1Password CLI via WSL).

## Deployment / CI

`prts` auto-upgrades nightly from `github:songpola/nixos-config#prts` on `main` (`modules/services/auto-upgrade.nix`) — whatever is merged to `main` gets deployed. `flake.lock` is only bumped by the weekly `update-flake-lock` workflow (opens a PR), never on the host; when the new nixpkgs has the next Kanidm release, the same PR bumps `services.kanidm.version` in `modules/hosts/prts/auth.nix` by one (Kanidm only upgrades to the adjacent release). CI (`.github/workflows/ci.yml`) runs `nix flake check` and builds prts.

The repo is a colocated jujutsu (`jj`) + git repo.
