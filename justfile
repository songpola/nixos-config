set unstable := true
set shell := ["nu", "-c"]
set script-interpreter := ["nu"]

alias c := check
check:
    nix flake check

alias s := switch
switch host="." flags="":
    nh os switch {{ host }} {{ flags }}

alias r := remote
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

alias i := install
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

[script]
disko diskConfig run="false" mode="destroy,format,mount":
    let flags =  [
        --mode "{{ mode }}"
        --debug
        (if not {{ run }} { --dry-run })
    ] | flatten | compact
    sudo nix run disko -- ...$flags {{ diskConfig }}
