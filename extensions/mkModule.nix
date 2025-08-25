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
        ...
      }@serviceOptions:
      let
        moduleName = "services.${name}";
      in
      prev.module {
        name = moduleName;

        options =
          with delib;
          setAttrByStrPath moduleName {
            enable = boolOption (enable);
          };

        home.ifEnabled = {
          virtualisation.quadlet = serviceOptions.rootlessQuadlet;
        };
      };
  };
}
