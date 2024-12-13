{
  # # This is the merged library containing your namespaced library as well as all libraries from
  # # your flake's inputs.
  lib,
  # # Your flake inputs are also available.
  # inputs,
  # # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  inherit (lib) attrValues haumea pathExists;
in rec {
  mkImportsFrom = path:
    if pathExists path
    then
      attrValues
      (
        haumea.load {
          src = path;
          loader = haumea.loaders.path;
        }
      )
    else [];

  mkConfigFrom = path: specialArgs:
    if pathExists path
    then
      haumea.load {
        src = path;
        inputs = specialArgs;
      }
    else {};

  mkModuleFrom = path: specialArgs: {
    imports = mkImportsFrom (path + "/imports");
    config = mkConfigFrom (path + "/config") specialArgs;
  };
}
