{ lib, namespace, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    setAttrByPath
    getAttrFromPath
    ;
  inherit (lib.snowfall.fs) get-file;
in
rec {
  hasPresetEnabled = presetPath: config: getAttrFromPath presetPath config.${namespace}.presets;
  hasHomePresetEnabled =
    presetPath: osConfig: getAttrFromPath presetPath osConfig.${namespace}.homePresets;
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

  # Use the same implementation as mkPresetModule
  mkHomePresetModule = config: presetPath: presetConfig: {
    options.${namespace}.homePresets = setAttrByPath presetPath mkEnableOption;
    config = mkIf (config |> hasHomePresetEnabled presetPath) presetConfig;
  };
}
