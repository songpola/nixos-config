{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) getConfigPath nixosConfigPath;
in
lib.${namespace}.mkPresetModule config [ "shells" ] {
  systemConfig = [
    {
      ${namespace}.presets = {
        tools = {
          starship = true;
        };
      };
    }
  ];
}
