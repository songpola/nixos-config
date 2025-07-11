{ namespace, utils, ... }:
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
      ssh = true;
    };
  };

  home-manager.extraSpecialArgs = {
    inherit utils; # required by homePresets.ssh
  };

  snowfallorg.users.${namespace}.home.config = {
    programs.ssh = {
      matchBlocks = {
        prts = {
          hostname = "prts.tail7623c.ts.net";
          user = namespace;
          # forwardAgent = true;
        };
      };
    };
  };
}
