{ den, lib, ... }:
{
  # Hosts opt in with `nvidia.enable = true;` (a host fact other aspects read, e.g. programs.btop)
  # and tune the aspect through `settings.nvidia`.
  den.schema.host.imports = [
    {
      options.nvidia.enable = lib.mkEnableOption "NVIDIA GPU support (includes the nvidia aspect)";
    }
  ];

  den.policies.nvidia-on-host =
    { host, ... }:
    lib.optional (host.class == "nixos" && host.nvidia.enable) (
      den.lib.policy.include den.aspects.nvidia
    );
  den.schema.host.includes = [ den.policies.nvidia-on-host ];

  den.aspects.nvidia = {
    settings = {
      open = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use the open-source kernel module (hardware.nvidia.open); older GPUs such as the GTX 10 series need false";
      };
      driverBranch = lib.mkOption {
        type = lib.types.str;
        default = "stable";
        example = "legacy_580";
        description = "Driver branch from `boot.kernelPackages.nvidiaPackages` (hardware.nvidia.package); Maxwell/Pascal/Volta GPUs such as the GTX 10 series need legacy_580";
      };
      containerToolkit = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CDI devices (`nvidia.com/gpu=all`) for containers";
      };
    };

    nixos =
      {
        config,
        host,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.nvidia;
      in
      {
        # Required by the NVIDIA driver
        nixpkgs.config.allowUnfree = true;

        # NOTE: This option should be enabled by default by the corresponding modules,
        # so you do not usually have to set it yourself.
        # hardware.graphics.enable = true;

        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia.open = cfg.open;

        hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.${cfg.driverBranch};

        hardware.nvidia-container-toolkit.enable = cfg.containerToolkit;

        environment.systemPackages = with pkgs; [
          nvitop
          nvtopPackages.nvidia
        ];
      };
  };
}
