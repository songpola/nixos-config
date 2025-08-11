{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "nvidia" ] {
  systemConfig = [
    {
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];

      ${namespace}.presets.tools.btop = true;

      # environment.systemPackages = with pkgs; [
      #   nvitop
      #   nvtopPackages.nvidia
      # ];
    }
  ];
}
