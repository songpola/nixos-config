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
