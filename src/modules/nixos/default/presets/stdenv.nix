{
  lib,
  config,
  namespace,
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
        nh = true;

        micro = true;
        ov = true;

        git = true;
        direnv = true;

        zoxide = true;
        # fzf = true; # already enabled by zoxide
        eza = true;

        ssh = true;
        vscode-remote = true;
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

    # Enable polkit for managing system permissions
    security.polkit.enable = true;
  }
  (mkHomeConfigModule {
    # Enable management of XDG base directories
    xdg.enable = true;
  })
])
