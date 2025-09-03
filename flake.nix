{
  description = "Modular configuration of NixOS, Home Manager, and Nix-Darwin with Denix";

  outputs =
    { denix, ... }@inputs:
    let
      username = "songpola";

      mkConfigurations =
        moduleSystem:
        denix.lib.configurations {
          inherit moduleSystem;
          homeManagerUser = username; # for "home" moduleSystem

          paths = [
            ./hosts
            ./modules
            ./containers
          ];

          extensions = with denix.lib.extensions; [
            args
            (base.withConfig (
              final: prev: {
                args.enable = true;
                rices.enable = false;
                hosts = {
                  type.types = prev.hosts.type.types ++ [
                    "wsl"
                  ];
                  features = {
                    features = [
                      "minienv"
                      "stdenv"
                      "remoteBuild"
                      "cacheClient"
                      "cacheServer"
                      "bootable"
                      "zfs"
                      "nvidia"
                      "containers"
                    ];
                    default = [
                      "minienv"
                    ];
                    defaultByHostType = {
                      "wsl" = [
                        "cacheClient"
                        "remoteBuild"
                      ];
                      "server" = [
                        "bootable"
                        "cacheServer"
                      ];
                    };
                  };
                };
              }
            ))
            (denix.lib.callExtension ./extensions/mylib.nix)
            ((denix.lib.callExtension ./extensions/mkModule.nix).withConfig { inherit username; })
          ];

          specialArgs = {
            inherit inputs username moduleSystem;
            packagesPath = ./packages;
          };
        };
    in
    {
      nixosConfigurations = mkConfigurations "nixos";
      templates = rec {
        default = devshell;
        devshell = {
          path = ./templates/devshell;
          description = "A template for per-project development environments using hercules-ci/flake-parts and numtide/devshell.";
        };
        just = {
          path = ./templates/just;
          description = "A justfile with nushell as default shell";
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    denix.url = "github:yunfachi/denix";
    denix.inputs.nixpkgs.follows = "nixpkgs";
    denix.inputs.home-manager.follows = "home-manager";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nixowos.url = "github:yunfachi/nixowos";
    nixowos.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };
}
