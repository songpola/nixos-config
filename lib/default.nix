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
  inherit (lib) mkEnableOption mapAttrs deploy-rs;
in {
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
}
