# Dokploy (self-hosted PaaS, on Docker)
# DISABLED: to enable,
#   1. uncomment the `nix-dokploy` input in ../inputs.nix and regenerate flake.nix
#   2. add `den.aspects."prts".dokploy` to `den.aspects."prts".includes`.
{ den, inputs, ... }:
{
  # Uncomment when enabling dokploy
  # flake-file.inputs.nix-dokploy = {
  #   url = "github:el-kurto/nix-dokploy";
  #   inputs.nixpkgs.follows = "nixpkgs";
  # };

  den.aspects."prts"._.dokploy = {
    includes = [ den.aspects."prts".docker ];

    nixos = {
      imports = [ inputs.nix-dokploy.nixosModules.default ];

      virtualisation.docker.daemon.settings.live-restore = false;

      services.dokploy = {
        enable = true;
        database.useInsecureHardcodedPassword = true;
        # database.passwordFile = "/var/lib/secrets/dokploy-db-password";
      };

      networking.firewall.allowedTCPPorts = [ 3000 ];
    };
  };
}
