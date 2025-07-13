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
  githubUserEmail = "1527535+songpola@users.noreply.github.com";
  githubUserName = "Songpol Anannetikul";
  opSshSignWslPath = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";

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

  mkHomeConfigModule = homeConfig: {
    snowfallorg.users.${namespace}.home.config = homeConfig;
  };

  getConfigPath = path: (get-file "config") + path;
}
