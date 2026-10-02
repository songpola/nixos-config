repl:
    nix repl .

# Regenerate flake.nix from the `flake-file.inputs` in modules/dendritic.nix
write-flake:
    nix run .#write-flake

check:
    nix flake check

switch:
    nh os switch .
