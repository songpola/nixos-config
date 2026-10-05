# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

NixOS configuration for three hosts (`prts` home server, `spla-desktop-wsl`, `spla-laptop-wsl`), built on [den](https://den.denful.dev) (dendritic aspects on flake-parts). `README.md` is leftover template boilerplate and does not describe this repo (no `hosts.nix`, `vm.nix` or `igloo` exist).

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

- **Hosts** are declared with `den.hosts."<system>"."<name>"` (users, plus host-schema options like `wsl.enable`, `zfs`, `nvidia`, `settings`). Each host has a same-named aspect `den.aspects."<name>"` that `includes` what it needs.
- **Aspects** (`den.aspects.<path>`) bundle per-class config: `nixos`, `homeManager`, `user` (→ `users.users.<name>`), `wsl` (→ NixOS-WSL `wsl.*`). Sub-aspects are declared with `_.<name>` and referenced as `den.aspects.foo.<name>` (e.g. `programs.starship.nushell-prompt`, `services.auto-upgrade.allow-reboot`). Opt-in features are sub-aspects that a host/profile includes, not boolean options.
- **Parametric aspects** are functions of `{ host }`, `{ user }` or `{ host, user }` (see `modules/users/primary-user.nix`, `modules/users/songpola/default.nix`).
- **Profiles** (`modules/profiles/`): `base` (shell/CLI tooling, every host), `server`, `interactive` (auto-included on WSL hosts via `den.aspects.wsl`).
- **Host-schema options + policies**: `modules/core/{zfs,nvidia,wsl}.nix` add options to `den.schema.host` and a `den.policies.*` that auto-includes the matching aspect when the host enables it. `core/wsl.nix` replaces den's built-in WSL battery (see `core/wsl.md`).
- **Aspect settings** (`modules/aspect-settings/`): an aspect may declare typed options under `settings = { ... }`; hosts set them at `den.hosts...settings.<aspect path>` and the aspect reads `host.settings.<aspect path>` (example: `services/tailscale.nix`, set in `hosts/prts/default.nix`).
- `den.default` applies to all hosts (hostname battery, home-manager `useGlobalPkgs`/`useUserPackages`, unstable overlay). User classes are `homeManager` + `user`, with `host-aspects` forwarding so host-included aspects reach users (`modules/defaults.nix`).

### prts

`modules/hosts/prts/`: ZFS (`tank` pool), NVIDIA legacy 580 driver, systemd-networkd bridge, disko layout, `facter.json` hardware report. Containers run on rootful Podman (overlay storage on the `@containers` btrfs subvolume, named volumes in `/tank/v2/podman-volumes`). Infrastructure containers are Nix-managed `virtualisation.oci-containers` in reusable aspects configured through host settings: `services.caddy-reverse-proxy` (caddy-docker-proxy), `services.dockhand` and `services.dozzle` (`modules/services/`). Application stacks are managed outside Nix by Dockhand (deployed in `/tank/v2/services/dockhand/stacks/<stack>/compose.yaml`); `modules/hosts/prts/stacks/` keeps copies of the stacks written here, in the same layout. Apps are exposed by joining the external `caddy` network and setting `caddy` / `caddy.reverse_proxy` labels. Service data lives under `/tank/v2/...`.

### Secrets

sops-nix with age; recipients in the root `.sops.yaml` (local dev key + each host). Encrypted files are `*.secrets.{yaml,env}`, kept in the host directory that uses them (e.g. `modules/hosts/prts/`) and passed to reusable aspects through settings. Hosts decrypt with their SSH ed25519 host key; the local dev age key is kept in 1Password, and `just sops-edit <file>` edits a file with it (`op.exe read`, the Windows 1Password CLI via WSL).

## Deployment / CI

`prts` auto-upgrades nightly from `github:songpola/nixos-config#prts` on `main` (`modules/services/auto-upgrade.nix`) — whatever is merged to `main` gets deployed. `flake.lock` is only bumped by the weekly `update-flake-lock` workflow (opens a PR), never on the host. CI (`.github/workflows/ci.yml`) runs `nix flake check` and builds prts.

The repo is a colocated jujutsu (`jj`) + git repo.
