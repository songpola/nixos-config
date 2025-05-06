{
  # This is the merged library containing your namespaced library as well as all libraries from
  # your flake's inputs.
  lib,
  # Your flake inputs are also available.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  inherit (lib) mkEnableOption mapAttrs deploy-rs remove splitString mkIf recursiveUpdate;
in rec {
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz songpola";

  mkDefaultEnableOption = x: mkEnableOption x // {default = true;};

  mkHomeConfig = homeConfig: {
    snowfallorg.users.${namespace}.home.config = homeConfig;
  };

  getHomeConfig = nixosConfig: nixosConfig.snowfallorg.users.${namespace}.home.config;
  getHomeConfigQuadlet = nixosConfig: (getHomeConfig nixosConfig).virtualisation.quadlet;

  mkDeployNodes = self:
    mapAttrs (
      node: cfg:
        {
          user = "root";
          profiles.system.path =
            deploy-rs.x86_64-linux.activate.nixos
            self.nixosConfigurations.${node};
        }
        // cfg
    );

  mkLabels = labels: remove "" (splitString "\n" labels);

  mkContainer = {
    name,
    image,
    noAutoStart ? false,
    socketActivated ? false,
    mountPodmanSocket ? false,
  }: cfg: {
    virtualisation.quadlet.containers.${name} =
      recursiveUpdate {
        autoStart = mkIf (noAutoStart || socketActivated) false;

        # No need to restart once finished for socket activated services
        serviceConfig.Restart = mkIf socketActivated "no";

        containerConfig = {
          inherit image;

          environments.TZ = "Asia/Bangkok";

          volumes = [
            (mkIf mountPodmanSocket "%t/podman/podman.sock:/var/run/docker.sock")
          ];
        };
      }
      cfg;
  };

  mkContainerWithCaddyNet = nixosConfig: settings: cfg: let
    quadletCfg = getHomeConfigQuadlet nixosConfig;
  in
    mkContainer settings (
      recursiveUpdate {
        containerConfig.networks = [quadletCfg.networks.caddy-net.ref];
      }
      cfg
    );
}
