{ lib, namespace, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    setAttrByPath
    getAttrFromPath
    mkMerge
    recursiveUpdate
    ;
  inherit (lib.snowfall.fs) get-file;
in
rec {
  nixosConfigPath = "/home/${namespace}/nixos-config";

  githubUserEmail = "1527535+songpola@users.noreply.github.com";
  githubUserName = "Songpol Anannetikul";
  opSshSignWslPath = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";

  sshPublicKeys = {
    podman-desktop-nixos-wsl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJH6u5g1JTV97z44w5UKQNBu7UQsA18AMQ+piNOomuyI";
  };

  hasPresetEnabled = presetPath: config: getAttrFromPath presetPath config.${namespace}.presets;
  hasBaseEnabled = name: config: config.${namespace}.base == name;

  getHomeCfg = config: config.snowfallorg.users.${namespace}.home.config;

  mkEnableOption = mkOption {
    type = types.bool;
    default = false;
  };

  mkBaseModule = config: name: baseConfig: {
    config = mkIf (config |> hasBaseEnabled name) baseConfig;
  };

  mkPresetModule =
    config: presetPath:
    {
      systemConfig ? [ ],
      homeConfig ? [ ],
      extraConfig ? [ ],
    }:
    let
      homeCfg = getHomeCfg config;

      # Supply homeConfig with homeCfg if it is a function
      mkHomeConfig = if builtins.isFunction homeConfig then homeConfig homeCfg else homeConfig;
    in
    {
      options.${namespace}.presets = setAttrByPath presetPath mkEnableOption;
      config = mkIf (config |> hasPresetEnabled presetPath) (mkMerge [
        (mkMerge systemConfig)
        (mkHomeConfigModule (mkMerge mkHomeConfig))
        (mkMerge extraConfig)
      ]);
    };

  mkHomeConfigModule = homeConfig: {
    snowfallorg.users.${namespace}.home.config = homeConfig;
  };

  mkIfPresetEnabled =
    config: presetPath:
    {
      systemConfig ? [ ],
      homeConfig ? [ ],
      extraConfig ? [ ],
    }:
    mkIf (config |> hasPresetEnabled presetPath) (mkMerge [
      (mkMerge systemConfig)
      (mkHomeConfigModule (mkMerge homeConfig))
      (mkMerge extraConfig)
    ]);

  mkIfBaseEnabled =
    config: name:
    {
      systemConfig ? [ ],
      homeConfig ? [ ],
      extraConfig ? [ ],
    }:
    mkIf (config |> hasBaseEnabled name) (mkMerge [
      (mkMerge systemConfig)
      (mkHomeConfigModule (mkMerge homeConfig))
      (mkMerge extraConfig)
    ]);

  mkRootlessQuadletModule =
    config:
    {
      # NOTE: Always set `*.quadletConfig.defaultDependencies = false;`
      # REASONS:
      # - For "server": currently, `network-online.target` don't have any dependents, so it is always inactive
      # - For "wsl":    `network-online.target` is always inactive
      # SEE: https://github.com/containers/podman/issues/22197
      #      https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#implicit-network-dependencies
      withDefaultDependencies ? false,

      autoEscape ? true,
    }:
    mkConfig:
    let
      homeCfg = getHomeCfg config;
      quadletCfg = homeCfg.virtualisation.quadlet;
      quadletConfig = mkConfig quadletCfg;

      # Update each toplevel config with `quadletConfig.defaultDependencies = false;`
      # Example: `containers.*.quadletConfig.defaultDependencies = false;`
      #          `volumes.*.quadletConfig.defaultDependencies = false;`
      disableDefaultDependencies =
        inputConfig:
        recursiveUpdate inputConfig (
          inputConfig
          |> builtins.mapAttrs (
            toplevelName: toplevelConfig:
            toplevelConfig
            |> builtins.mapAttrs (
              subName: subConfig: {
                quadletConfig.defaultDependencies = false;
              }
            )
          )
        );
    in
    mkHomeConfigModule {
      virtualisation.quadlet =
        (if withDefaultDependencies then quadletConfig else disableDefaultDependencies quadletConfig)
        // {
          inherit autoEscape;
        };
    };

  getConfigPath = path: (get-file "config") + path;
  getSecretsPath = path: (get-file "secrets") + path;

  secrets = import (get-file "secrets");
}
