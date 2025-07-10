{ namespace, ... }:
{
  ${namespace} = {
    base = "wsl";
    presets = [
      "nix-settings"
      "env.std"
      "env.dev.nix"
      "env.dev.vscode-remote"
      "env.dev.node"
    ];
  };

  system.stateVersion = "24.11";

  snowfallorg.users.${namespace}.home.config = {
    home.stateVersion = "25.05";
  };
}
