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
                    ];
                    default = [
                      "minienv"
                    ];
                    defaultByHostType = {
                      "wsl" = [
                        "remoteBuild"
                      ];
                    };
                  };
                };
              }
            ))
            (denix.lib.callExtension ./extensions/mylib.nix)
          ];

          specialArgs = { inherit inputs username; };
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
  };
}
