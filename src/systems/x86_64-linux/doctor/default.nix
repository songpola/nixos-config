{ lib, namespace, ... }:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
mkMerge [
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
          devbox = true;
        };

        ssh = true;

        tools = {
          jujutsu = true;
        };
      };
    };
  }
  (mkHomeConfigModule {
    programs.ssh = {
      matchBlocks = {
        prts = {
          hostname = "prts.tail7623c.ts.net";
          user = namespace;
          forwardAgent = true;
        };
      };
    };
  })
]
