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
  inherit (lib) mapAttrsToList haumea;
in rec {
  mkImportsFrom = path:
    mapAttrsToList (name: value: value)
    (
      haumea.load {
        src = path;
        loader = haumea.loaders.path;
      }
    );
  mkConfigFrom = path:
    haumea.load {
      src = path;
    };
  mkSystemFrom = path: {
    imports = mkImportsFrom (path + "/imports");
    config = mkConfigFrom (path + "/config");
  };
}
