{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "stdenv" ] (mkMerge [
  {
    # Enable standard environment presets
    ${namespace}.presets = {
      shells = true;

      tools = {
        git = true;
        ov = true;
        ssh = true;
        direnv = true;
        vscode-remote = true;
        zoxide = true;
        # fzf = true; # enabled by zoxide
      };
    };

    # Disable Nix channels
    nix.channel.enable = false;

    # Nix settings
    nix.settings.experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];

    # Set timezone to Bangkok
    time.timeZone = "Asia/Bangkok";

    # Use micro as default (and fallback) text editor
    environment = {
      systemPackages = [ pkgs.micro ];
      variables = {
        EDITOR = "micro";
      };
    };

    # nh: "Yet another Nix CLI helper."
    # https://github.com/nix-community/nh
    programs.nh = {
      enable = true;
      clean.enable = true; # auto clean (default: weekly)
    };

    # Enable polkit for managing system permissions
    security.polkit.enable = true;
  }
  (mkHomeConfigModule {
    # Enable management of XDG base directories
    xdg.enable = true;
  })
])
