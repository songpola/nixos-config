{ delib, host, ... }:
delib.module {
  name = "podman.nvidia";

  options = delib.singleEnableOption host.nvidiaFeatured;

  nixos.ifEnabled = delib.ifParentEnabled "podman" {
    hardware.nvidia-container-toolkit.enable = true;

    # FIXME: podman: 5.5.1 breaks cdi
    # See:   https://github.com/NixOS/nixpkgs/issues/417312#issuecomment-3024705964
    virtualisation.containers.containersConf.settings = {
      engine.cdi_spec_dirs = [
        "/etc/cdi" # the only default (since v5.5.0)
        "/var/run/cdi" # where the NixOS module places the generated CDI spec
      ];
    };
  };
}
