{ namespace, ... }:
{
  ${namespace} = {
    stateVersions = {
      system = "24.11";
      home = "25.05";
    };
    base = "wsl";
    presets = {
      stdenv = true;
      devenv = {
        nix = true;
        vscode-remote = true;
        node = true;
      };
    };
    homePresets = {
      git = true;
      shells = true;
    };
  };
}
