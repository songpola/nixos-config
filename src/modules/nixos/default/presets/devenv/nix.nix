{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "devenv" "nix" ] {
  # Packages for Nix IDE VSCode extension
  environment.systemPackages = with pkgs; [
    nil # LSP
    nixfmt-rfc-style # NixOS/nixfmt: The official Nix formatter
  ];
}
