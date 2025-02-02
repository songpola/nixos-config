set unstable := true
set shell := ["nu", "-c"]
set script-interpreter := ["nu"]

switch:
    nh os switch .

[script]
remote op host hostname useSubstitutes="true":
    let flags =  [
        --flake ".#{{ hostname }}"
        --target-host {{ host }}
        --build-host {{ host }}
        --use-remote-sudo
        (if {{ useSubstitutes }} { --use-substitutes })
    ]
    nixos-rebuild {{ op }} ...$flags

[script]
install host hostname hardwareConfigPath="":
    let flags =  [
        --flake ".#{{ hostname }}"
        --build-on-remote
        --debug
        (if ("{{ hardwareConfigPath }}" | is-not-empty) {
            [--generate-hardware-config nixos-generate-config "{{ hardwareConfigPath }}"]
        })
    ] | flatten | compact
    nix run nixos-anywhere -- ...$flags {{ host }}
