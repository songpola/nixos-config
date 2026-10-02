{
  den.aspects.programs.btop.nixos =
    { host, pkgs, ... }:
    {
      # The CUDA build shows NVIDIA GPU stats
      environment.systemPackages = [ (if host.nvidia.enable then pkgs.btop-cuda else pkgs.btop) ];
    };
}
