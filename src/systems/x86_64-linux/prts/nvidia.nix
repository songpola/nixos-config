{
  services.xserver.videoDrivers = [ "nvidia" ];

  # Will be auto-enabled by nvidia-container-toolkit if needed
  # https://github.com/NixOS/nixpkgs/blob/5115ec98d541f12b7b14eb0b91626cddaf3ae5b7/nixos/modules/services/hardware/nvidia-container-toolkit/default.nix#L123
  #
  # hardware.graphics.enable = true;

  # 1050Ti (Pascal) doesn't support open-source kernel module
  hardware.nvidia.open = false;
}
