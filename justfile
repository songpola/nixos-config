repl:
    nix repl .

# Regenerate flake.nix from the `flake-file.inputs` in modules/dendritic.nix
write-flake:
    nix run .#write-flake

check:
    nix flake check

switch:
    nh os switch .

# 1Password reference to the sops age private key (local development key in .sops.yaml)
sops_age_key_ref := env("SOPS_AGE_KEY_REF", "op://nixos-config/SOPS_AGE_KEY/credential")

# Edit a sops file with the age key read from 1Password, e.g. `just sops-edit modules/hosts/prts/caddy-reverse-proxy.secrets.yaml`
sops-edit file:
    SOPS_AGE_KEY="$(op.exe read '{{ sops_age_key_ref }}')" nix shell nixpkgs#sops -c sops edit '{{ file }}'

# Run an nh os action on prts remotely, e.g. `just prts switch` or `just prts boot`
prts action="switch":
    nh os {{ action }} . --hostname=prts --target-host=prts --build-host=prts --elevation-strategy=passwordless --show-activation-logs --ask
