set shell := ["nu", "-c"]

switch:
  nh os switch .

remote host:
  #!/usr/bin/env nu
  (
    nixos-rebuild switch
      --flake .
      --target-host {{host}}
      --build-host {{host}}
      --use-remote-sudo
      --use-substitutes
  )

install host hostname *FLAGS:
  #!/usr/bin/env nu
  (
    nix run nixos-anywhere --
      --flake .#{{host}}
      --generate-hardware-config nixos-generate-config ./systems/x86_64-linux/prts/vm/hardware-configuration.nix
      # --build-on-remote
      --debug
      {{FLAGS}}
      {{hostname}}
  )
