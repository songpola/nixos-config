{ namespace, ... }:
rec {
  usePreset = preset: config: builtins.elem preset config.${namespace}.presets;
  useAnyPresets = presets: config: builtins.any (preset: usePreset preset config) presets;
  useBase = base: config: config.${namespace}.base == base;
}
