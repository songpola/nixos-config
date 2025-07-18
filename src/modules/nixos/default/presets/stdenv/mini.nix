{
  lib,
  config,
  namespace,
  ...
}:
# Minimal standard environment preset.
#
# This preset should always be the first one to be enabled.
# This should be comfortable for enough for any further customization.
lib.${namespace}.mkPresetModule config [ "stdenv" "mini" ] {
  systemConfig = [
    {
      ${namespace}.presets = {
        tools = {
          nh = true;
          micro = true;
          ov = true;
          git = true;
          jujutsu = true;
          vscode-remote = true;
        };
      };

      # Disable Nix channels
      nix.channel.enable = false;

      # Nix experimental features
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
  ];
}
