# songpola's NixOS Config

## nh

```bash
nh os switch
```

## nixos-rebuild

```bash
sudo nixos-rebuild switch --flake github:songpola/nixos-config
```

### Deploy to Remote Host

```bash
nixos-rebuild --flake github:songpola/nixos-config --build-host songpola@<host> --target-host songpola@<host> --use-remote-sudo switch
```

## nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- --flake github:songpola/nixos-config#<hostname> root@<host>
```

---

## References

### [My SSH Public Key](https://github.com/songpola.keys)

### [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/no-os.md#installing-on-a-machine-with-no-operating-system)
