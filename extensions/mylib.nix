{ delib, lib, ... }:
delib.extension {
  name = "mylib";

  libExtension =
    let
      tryWith =
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
          { enable = delib.boolOption default; } // (tryWith args optionsOrLambda)
        );

      ifParentEnabled =
        name: configOrLambda:
        { myconfig, ... }@args:
        lib.mkIf (delib.getAttrByStrPath "${name}.enable" myconfig false) (tryWith args configOrLambda);
    };
}
