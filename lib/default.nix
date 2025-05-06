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

  getHomeConfig = config: config.snowfallorg.users.${namespace}.home.config;

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

  # i.e. Sepecify `y` only if `x` is false
  mkElse = x: y: mkIf (!x) y;

  # i.e. Don't sepecify `x` unless `x` is false
  mkUnless = x: mkIf (!x) x;

  mkContainer = cfg: {
    name,
    image,
    useCaddyNet ? false,
    mountPodmanSocket ? false,
    autoStartOnBoot ? true,
    socketActivated ? false,
  }: config: {
    virtualisation.quadlet.containers.${name} =
      recursiveUpdate {
        # Default to auto start on boot; unless specified otherwise
        autoStart = mkUnless autoStartOnBoot;

        # No need to restart once finished for socket activated services
        serviceConfig.Restart = mkIf socketActivated "no";

        containerConfig = {
          inherit image;

          environments.TZ = "Asia/Bangkok";

          networks = mkIf useCaddyNet [cfg.networks.caddy-net.ref];

          volumes = [
            (mkIf mountPodmanSocket "%t/podman/podman.sock:/var/run/docker.sock")
          ];
        };
      }
      config;
  };
}
