{
  delib,
  pkgs,
  host,
  ...
}:
delib.module {
  # NVTOP - GPU & Accelerator process monitoring for AMD, Apple, Huawei, Intel, NVIDIA and Qualcomm
  # https://github.com/Syllo/nvtop
  name = "nvtop";

  options = delib.singleEnableOption host.nvidiaFeatured;

  nixos.ifEnabled =
    { cfg, ... }:
    {
      environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
    };
}
