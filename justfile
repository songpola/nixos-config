repl:
    nix repl .

# Regenerate flake.nix from the `flake-file.inputs` in modules/dendritic.nix
write-flake:
    nix run .#write-flake

check:
    nix flake check

switch:
    nh os switch .

# Run an nh os action on prts remotely, e.g. `just prts switch` or `just prts boot`
prts action="switch":
    nh os {{ action }} . --hostname=prts --target-host=prts --build-host=prts --elevation-strategy=passwordless --show-activation-logs --ask
