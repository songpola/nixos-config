{
  delib,
  pkgs,
  host,
  ...
}:
delib.module {
  # nvitop - An interactive NVIDIA-GPU process viewer and beyond, the one-stop solution for GPU process management
  # https://github.com/XuehaiPan/nvitop
  name = "nvitop";

  options = delib.singleEnableOption host.nvidiaFeatured;

  nixos.ifEnabled =
    { cfg, ... }:
    {
      environment.systemPackages = [ pkgs.nvitop ];
    };
}
