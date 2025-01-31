set shell := ["nu", "-c"]

switch:
  nh os switch .

remote hostname host useSubstitutes="true":
  #!/usr/bin/env nu
  (
    nixos-rebuild switch
      --flake .#{{hostname}}
      --target-host {{host}}
      --build-host {{host}}
      --use-remote-sudo
      {{ if useSubstitutes == "true" { "--use-substitutes" } else { "" } }}
  )

install hostname host:
  #!/usr/bin/env nu
  (
    nix run nixos-anywhere --
      --flake .#{{hostname}}
      --build-on-remote
      --debug
      # --generate-hardware-config nixos-generate-config ./systems/x86_64-linux/prts/vm/qemu/hardware-configuration.nix
      {{host}}
  )
