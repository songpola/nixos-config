{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    haumea.url = "github:nix-community/haumea/v0.2.2";
    haumea.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit self;
          };
          modules = [
            nixos-wsl.nixosModules.default
            home-manager.nixosModules.home-manager

            ./base/wsl.nix

            ./modules/nix-settings.nix

            ./modules/minimal.nix

            ./modules/dev/nix.nix
            ./modules/dev/node.nix
            ./modules/dev/vscode-remote.nix

            ./modules/home-manager.nix
          ];
        };

        doctor = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.default

            # Options
            (
              { lib, ... }:
              let
                inherit (lib) mkOption types;
              in
              {
                options = {
                  core = mkOption {
                    type = types.str;
                  };
                  api = mkOption {
                    type = types.listOf types.str;
                  };
                };
              }
            )

            # Core: WSL
            (
              { lib, config, ... }:
              let
                inherit (lib) mkMerge mkIf;

                useCore = core: config.core == core;
              in
              mkMerge [
                (mkIf (useCore "wsl") {
                  wsl.enable = true;
                })
              ]
            )

            # API: user
            (
              { lib, config, ... }:
              let
                inherit (lib) mkMerge mkIf;

                useApi = api: builtins.elem api config.api;
                useCore = core: config.core == core;
              in
              mkMerge [
                (mkIf (useApi "user") (mkMerge [
                  (mkIf (useCore "wsl") {
                    # If WSL
                    wsl.defaultUser = "songpola";
                  })
                ]))
              ]
            )

            # Client: doctor
            {
              core = "wsl";
              api = [
                "user"
              ];

              system.stateVersion = "24.11";
            }
          ];
        };
      };
    };
}
