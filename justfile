set unstable := true
set shell := ["nu", "-c"]
set script-interpreter := ["nu"]

buildOnRemote := "true"
useSubstitutes := "true"
generateHardwareConfig := ""

repl:
    nix repl .

alias c := check
check:
    nix flake check

alias s := switch
switch host="." flags="":
    nh os switch {{ host }} {{ flags }}

alias r := remote
[script]
remote op hostname host="":
    let host = "{{ if host != "" { host } else { hostname } }}"
    let flags =  [
        --flake ".#{{ hostname }}"
        --use-remote-sudo
        --target-host $host
        (if {{ buildOnRemote }} { [--build-host $host ] })
        (if {{ useSubstitutes }} { --use-substitutes })
    ] | flatten | compact
    nixos-rebuild {{ op }} ...$flags

alias i := install
[script]
install hostname host="":
    let host = "{{ if host != "" { host } else { hostname } }}"
    let flags =  [
        --flake ".#{{ hostname }}"
        --debug
        (if "{{ generateHardwareConfig }}" == "nixos-generate-config" {
            [
                --generate-hardware-config
                nixos-generate-config
                "src/systems/x86_64-linux/{{ hostname }}/imports/hardware-configuration.nix"
            ]
        })
        (if "{{ generateHardwareConfig }}" == "nixos-facter" {
            [
                --generate-hardware-config
                nixos-facter
                "src/systems/x86_64-linux/{{ hostname }}/config/facter/facter.json"
            ]
        })
        (if {{ buildOnRemote }} { --build-on-remote })
    ] | flatten | compact
    nix run nixos-anywhere -- ...$flags $host

[script]
disko diskConfig run="false" mode="destroy,format,mount":
    let flags =  [
        --mode "{{ mode }}"
        --debug
        (if not {{ run }} { --dry-run })
    ] | flatten | compact
    sudo nix run disko -- ...$flags {{ diskConfig }}

secrets := "src/lib/secrets/sops-nix.yaml"

sops:
    sops {{ secrets }}

sops-updatekeys:
    sops updatekeys {{ secrets }}
