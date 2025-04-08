{
  # This is the merged library containing your namespaced library as well as all libraries from
  # your flake's inputs.
  lib,
  # Your flake inputs are also available.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  inherit (lib) mkEnableOption;
in {
  getHomePath = config: config.snowfallorg.users.${namespace}.home.path;
  mkDefaultEnableOption = x: mkEnableOption x // {default = true;};
  mkHomeConfig = homeConfig: {
    snowfallorg.users.${namespace}.home.config = homeConfig;
  };
}
