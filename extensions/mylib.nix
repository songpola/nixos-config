{ delib, lib, ... }:
delib.extension {
  name = "mylib";

  # config = {};
  # config = prev: {};
  # config = final: prev: { };

  # initialConfig = {};
  # initialConfig = final: {}
  # initialConfig = null;

  # configOrder = 0;

  libExtension = {
    singleEnableOptionDependency =
      dependencyName:
      { myconfig, ... }@args:
      delib.singleEnableOption myconfig.${dependencyName}.enable args;

    enableOptionWith =
      default: options:
      { name, ... }:
      delib.setAttrByStrPath name ({ enable = delib.boolOption default; } // options);

    ifParentEnabled =
      name: configOrLambda:
      { myconfig, ... }@args:
      lib.mkIf (delib.getAttrByStrPath "${name}.enable" myconfig false) (
        if builtins.typeOf configOrLambda == "lambda" then (configOrLambda args) else configOrLambda
      );
  };
  # libExtension = config: {};
  # libExtension = config: prev: {};
  # libExtension =
  #   config: final: prev:
  #   { };

  # libExtensionOrder = 0;

  # modules = config: [];
  # modules = [ ];
}
