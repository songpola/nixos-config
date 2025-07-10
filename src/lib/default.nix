{ lib, namespace, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    setAttrByPath
    getAttrFromPath
    ;
in
rec {
  hasPresetEnabled = presetPath: config: getAttrFromPath presetPath config.${namespace}.presets;
  hasBaseEnabled = name: config: config.${namespace}.base == name;

  mkEnableOption = mkOption {
    type = types.bool;
    default = false;
  };

  mkBaseModule = config: name: baseConfig: {
    config = mkIf (config |> hasBaseEnabled name) baseConfig;
  };

  mkPresetModule = config: presetPath: presetConfig: {
    options.${namespace}.presets = setAttrByPath presetPath mkEnableOption;
    config = mkIf (config |> hasPresetEnabled presetPath) presetConfig;
  };
}
