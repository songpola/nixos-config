{ delib, lib, ... }:
delib.extension {
  name = "mylib";

  libExtension =
    let
      callWith =
        args: maybeLambda:
        if builtins.typeOf maybeLambda == "lambda" then (maybeLambda args) else maybeLambda;
    in
    {
      singleEnableOptionDependency =
        dependencyName:
        { myconfig, ... }@args:
        delib.singleEnableOption (delib.getAttrByStrPath "${dependencyName}.enable" myconfig false) args;

      enableOptionWith =
        default: optionsOrLambda:
        { name, ... }@args:
        delib.setAttrByStrPath name (
          { enable = delib.boolOption default; } // (callWith args optionsOrLambda)
        );

      ifParentEnabled =
        name: configOrLambda:
        { myconfig, ... }@args:
        lib.mkIf (delib.getAttrByStrPath "${name}.enable" myconfig false) (callWith args configOrLambda);

      rootlessQuadletModule =
        homeconfig:
        {
          # NOTE: Always set `*.quadletConfig.defaultDependencies = false;`.
          # For "server": currently, `network-online.target` don't have any dependents, so it is always inactive.
          # For "wsl": `network-online.target` is always inactive.
          #
          # SEE: https://github.com/containers/podman/issues/22197
          #      https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#implicit-network-dependencies
          withDefaultDependencies ? false,
        }:
        configOrLambda:
        let
          quadletConfig = callWith homeconfig.virtualisation.quadlet configOrLambda;

          # Update each toplevel config with `quadletConfig.defaultDependencies = false;`
          # Example: `containers.*.quadletConfig.defaultDependencies = false;`
          #          `volumes.*.quadletConfig.defaultDependencies = false;`
          disableDefaultDependencies =
            cfg:
            lib.recursiveUpdate cfg (
              cfg
              |> lib.filterAttrs (n: builtins.isAttrs) # only keep attrs values
              |> builtins.mapAttrs (
                # n1: containers, volumes, networks, pods, etc.
                n1:
                builtins.mapAttrs (
                  # n2: containers.*, volumes.*, networks.*, pods.*, etc.
                  n2: v2: {
                    quadletConfig.defaultDependencies = false;
                  }
                )
              )
            );
        in
        {
          virtualisation.quadlet =
            if withDefaultDependencies then quadletConfig else disableDefaultDependencies quadletConfig;
        };
    };
}
