set unstable := true
set shell := ["nu", "-c"]
set script-interpreter := ["nu"]

buildOnRemote := "true"
useSubstitutes := "true"
generateHardwareConfig := ""

repl:
    nix repl .

alias l := lock
lock:
    nix flake lock

alias c := check
check:
    nix flake check

alias s := switch
switch host="." *FLAGS="":
    nh os switch {{ host }} {{ FLAGS }}

alias r := remote
[script]
remote op hostname host="" *FLAGS="":
    let op = match "{{ op }}" {
        "s" => "switch",
        "b" => "boot",
        _ => "{{ op }}"
    }
    let host = "{{ if host != "" { host } else { hostname } }}"
    let flags =  [
        --flake ".#{{ hostname }}"
        --use-remote-sudo
        --target-host $host
        (if {{ buildOnRemote }} { [ --build-host $host ] })
        (if {{ useSubstitutes }} { --use-substitutes })
    ] | flatten | compact
    nixos-rebuild $op ...$flags {{ FLAGS }}

alias i := install
[script]
install hostname host="" *FLAGS="":
    let host = "{{ if host != "" { host } else { hostname } }}"
    let flags =  [
        --flake ".#{{ hostname }}"
        --target-host $host
        (if "{{ generateHardwareConfig }}" == "nixos-generate-config" {
            [
                --generate-hardware-config
                nixos-generate-config
                "systems/x86_64-linux/{{ hostname }}/hardware-configuration.nix"
            ]
        })
        (if "{{ generateHardwareConfig }}" == "nixos-facter" {
            [
                --generate-hardware-config
                nixos-facter
                "systems/x86_64-linux/{{ hostname }}/facter.json"
            ]
        })
        (if {{ buildOnRemote }} { [ --build-on remote ] })
        (if ("SSHPASS" in $env) and ($env.SSHPASS != "") { --env-password })
    ] | flatten | compact
    nix run nixos-anywhere -- ...$flags {{ FLAGS }}

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
