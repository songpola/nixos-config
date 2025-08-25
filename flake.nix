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
            (denix.lib.callExtension ./extensions/mkModule.nix)
          ];

          specialArgs = {
            inherit inputs username moduleSystem;
            packagesPath = ./packages;
          };
        };
    in
    {
      nixosConfigurations = mkConfigurations "nixos";
      homeConfigurations = mkConfigurations "home";
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
