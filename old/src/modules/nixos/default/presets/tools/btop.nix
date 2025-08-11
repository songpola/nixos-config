{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) hasPresetEnabled;

  nvidiaEnabled = config |> hasPresetEnabled [ "nvidia" ];
in
lib.${namespace}.mkPresetModule config [ "tools" "btop" ] {
  systemConfig = [
    {
      environment.systemPackages = [
        (if nvidiaEnabled then pkgs.btop-cuda else pkgs.btop)
      ];
    }
  ];
}
