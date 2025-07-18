{ lib, namespace, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    setAttrByPath
    getAttrFromPath
    mkMerge
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
    {
      options.${namespace}.presets = setAttrByPath presetPath mkEnableOption;
      config = mkIf (config |> hasPresetEnabled presetPath) (mkMerge [
        (mkMerge systemConfig)
        (mkHomeConfigModule (mkMerge homeConfig))
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

  # [ WSL ONLY ]
  # NOTE:   Always set `*.quadletConfig.defaultDependencies = false;`
  # REASON: `network-online.target` is always inactive in WSL
  # SEE:    https://github.com/containers/podman/issues/22197
  #         https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#implicit-network-dependencies
  mkRootlessQuadletModule =
    config: mkConfig:
    let
      homeCfg = config.snowfallorg.users.${namespace}.home.config;
      cfg = homeCfg.virtualisation.quadlet;
    in
    mkHomeConfigModule {
      virtualisation.quadlet = mkConfig cfg;
    };

  getConfigPath = path: (get-file "config") + path;
}
