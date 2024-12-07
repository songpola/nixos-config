# songpola's NixOS Config

## Setup

### `nixos-anywhere`

> Set password (using `passwd`) for `root` first

```bash
nix run github:nix-community/nixos-anywhere -- --flake github:songpola/nixos-config#<hostname> --build-on-remote root@<host>
```

## Usage

### `nh`

```bash
nh os switch
```

### `nixos-rebuild`

```bash
sudo nixos-rebuild switch --flake github:songpola/nixos-config
```

#### Deploy to Remote Host

- Add `--build-host <user>@<host>` flag to build on remote host
- Add `--use-remote-sudo` flag if use non-root user
- Add `--use-substitutes` flag to speed up if the remote host is faster

```bash
nixos-rebuild --flake github:songpola/nixos-config --target-host <user>@<host> switch
```

## Notes

### pnpm

#### Install the LTS version of Node.js

```bash
pnpm env use --global lts
```

---

## References

- [My SSH Public Key](https://github.com/songpola.keys)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/no-os.md#installing-on-a-machine-with-no-operating-system)
