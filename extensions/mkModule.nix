{ delib, lib, ... }:
delib.extension {
  name = "mkModule";

  libExtension = config: prev: {
    mkProgramModule =
      {
        # Name of the program
        name,
        # Whether to enable by default
        enable ? true,
        # Package of the program
        package ? null,
        ...
      }:
      let
        moduleName = "programs.${name}";
      in
      prev.module {
        name = moduleName;

        options =
          with delib;
          setAttrByStrPath moduleName {
            enable = boolOption (enable);
            package = packageOption (package) |> allowNull;
          };

        nixos.ifEnabled =
          { cfg, ... }:
          {
            environment.systemPackages = lib.optionals (cfg.package != null) [ cfg.package ];
          };
      };

    mkServiceModule =
      {
        # Name of the service
        name,
        # Whether to enable by default
        enable ? true,
        # An attrset for secrets
        rootlessSecrets,
        # An attrset for rootless quadlet config
        rootlessQuadletConfig,
        ...
      }:
      let
        moduleName = "services.${name}";

        finalRootlessQuadletConfig =
          rootlessQuadletConfig
          |> lib.recursiveUpdate (
            rootlessQuadletConfig
            |> builtins.mapAttrs (
              n1: # pods, containers, ...
              builtins.mapAttrs (
                n2: v2: # pods.<n2>, containers.<n2>, ...
                {
                  quadletConfig.defaultDependencies = false;
                  serviceConfig.Restart = "on-abnormal";
                }
              )
            )
          );
      in
      prev.module {
        name = moduleName;

        options =
          with delib;
          setAttrByStrPath moduleName {
            enable = boolOption (enable);
          };

        nixos.ifEnabled = {
          sops.secrets = rootlessSecrets;
        };

        home.ifEnabled = {
          virtualisation.quadlet = finalRootlessQuadletConfig;
        };
      };
  };
}
