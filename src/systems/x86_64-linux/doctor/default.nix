{ namespace, ... }:
{
  ${namespace} = {
    base = "wsl";
    presets = {
      stdenv = true;
      devenv = {
        nix = true;
        vscode-remote = true;
        node = true;
      };
      home = {
        git = true;
      };
    };
  };

  system.stateVersion = "24.11";

  snowfallorg.users.${namespace}.home.config = {
    home.stateVersion = "25.05";
  };
}
