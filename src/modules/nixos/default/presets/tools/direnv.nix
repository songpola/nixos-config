{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "direnv" ] {
  systemConfig = [
    {
      # Enable Direnv system-wide
      # nix-direnv is enabled by default
      programs.direnv.enable = true;
    }
  ];
  homeConfig = [
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    }
  ];
}
