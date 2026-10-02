# Internal WSL battery, replacing den's built-in one. See modules/core/wsl.md.
{
  config,
  den,
  lib,
  ...
}:
let
  inherit (den.lib) policy;

  isWsl = host: host.class == "nixos" && (host.wsl.enable or false);

  # `wsl` class keys land in NixOS-WSL's `wsl.*` options.
  wsl-class-route = policy.route {
    fromClass = "wsl";
    intoClass = "nixos";
    path = [ "wsl" ];
  };
in
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/NixOS-WSL/release-${config.stableVersion}";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Turn off den's built-in WSL battery; this module replaces it.
  den.schema.host.excludes = [ den.policies.host-to-wsl-host ];
  den.default.excludes = [ den.policies.wsl-to-host ];

  den.policies.wsl-on-host =
    { host, ... }:
    lib.optionals (isWsl host) [
      (policy.include den.aspects.nixos-wsl-module)
      wsl-class-route
      (policy.include den.aspects.wsl)
    ];
  den.schema.host.includes = [ den.policies.wsl-on-host ];

  # The route is needed at user scope too, or user-scope `wsl.*` content
  # (e.g. primary-user's wsl.defaultUser) is lost.
  den.policies.wsl-on-user =
    { host, user, ... }:
    lib.optionals (isWsl host) [
      wsl-class-route
      (policy.include den.aspects.wsl)
    ];
  den.schema.user.includes = [ den.policies.wsl-on-user ];

  den.aspects.nixos-wsl-module =
    { host }:
    {
      nixos.imports = [
        {
          # Keyed so NixOS-WSL is imported once no matter how many scopes include it.
          key = "nixos-config:nixos-wsl";
          imports = [ host.wsl.module ];
          wsl.enable = true;
        }
      ];
    };

  den.aspects.wsl = {
    description = ''
      Included on WSL hosts (host.wsl.enable) and for each of their users.
      Every class key works here, homeManager included.
    '';

    includes = [
      # I don't want to enter a password every time I use sudo in WSL.
      den.aspects.security.passwordless-wheel
    ];

    nixos =
      { pkgs, ... }:
      {
        wsl = {
          # Enable OpenGL driver from the Windows host
          # See https://github.com/nix-community/NixOS-WSL/blob/main/modules/wsl-distro.nix
          useWindowsDriver = true;

          # Enable USB/IP support for accessing USB devices from WSL
          usbip.enable = true;
        };

        # Enable xdg-open for opening files and URLs in WSL
        environment.systemPackages = [ pkgs.xdg-utils ];
      };
  };
}
