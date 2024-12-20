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
  loadAsList = path:
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

  loadAsAttrs = path: specialArgs:
    if pathExists path
    then
      haumea.load {
        src = path;
        inputs = specialArgs;
      }
    else {};

  mkModuleFrom = path: specialArgs: {
    imports = loadAsList (path + "/imports");
    options = loadAsAttrs (path + "/options") specialArgs;
    config = loadAsAttrs (path + "/config") specialArgs;
  };

  enableOptions = let
    op = acc: option: acc // {"${option}".enable = true;};
    acc0 = {};
  in
    options: lib.foldl' op acc0 options;
}
