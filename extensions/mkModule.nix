{ delib, lib, ... }:
delib.extension {
  name = "mkModule";

  config = {
    username = null;
  };

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
        defaultEnable ? false,
        # A list of secret names
        rootlessSecrets ? [ ],
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

        options = delib.setAttrByStrPath moduleName ({ enable = delib.boolOption (defaultEnable); });

        myconfig.ifEnabled.secrets.enable = rootlessSecrets != [ ];

        nixos.ifEnabled = {
          sops.secrets =
            rootlessSecrets
            |> map (secretName: {
              name = secretName;
              value = ({ owner = config.username; });
            })
            |> builtins.listToAttrs;
        };

        home.ifEnabled = {
          virtualisation.quadlet = finalRootlessQuadletConfig;
        };
      };
  };
}
