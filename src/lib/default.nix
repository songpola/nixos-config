{
  # # https://snowfall.org/guides/lib/library/
  # # This is the merged library containing your namespaced library as well as all libraries from
  # # your flake's inputs.
  lib,
  # # Your flake inputs are also available.
  # inputs,
  # # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  inherit (lib) haumea;
in {
  mkHaumeaModule = inputs: path: let
    configPath = path + "/config";
    importsPath = path + "/imports";
  in {
    config = haumea.load {
      src = configPath;
      inputs =
        inputs
        // {
          _lib = lib.${namespace};
        };
    };

    imports = lib.optionals (lib.pathExists importsPath) (
      lib.attrValues (
        haumea.load {
          src = importsPath;
          loader = haumea.loaders.path;
        }
      )
    );
  };
}
