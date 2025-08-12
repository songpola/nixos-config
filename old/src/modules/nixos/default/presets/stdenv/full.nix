{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "stdenv" "full" ] {
  systemConfig = [
    {
      ${namespace}.presets = {
        tools = {
          ssh = true;
        };

        devenv = {
          nix = true;
        };
      };
    }
  ];
}
