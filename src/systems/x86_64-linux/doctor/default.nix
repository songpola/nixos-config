{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule mkRootlessQuadletModule;
in
mkMerge [
  {
    ${namespace} = {
      stateVersions = {
        system = "25.05";
        home = "25.05";
      };
      base = "wsl";
      presets = {
        stdenv = true;

        devenv = {
          nix = true;
          node = true;
        };

        tools = {
          jujutsu = true;
          gh = true;
        };

        services = {
          sshd = true;
        };

        podman = true;
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
  (mkRootlessQuadletModule config (cfg: {
    containers = {
      trilium = {
        quadletConfig.defaultDependencies = false; # WSL only
        containerConfig = {
          image = "docker.io/triliumnext/trilium:v0.96.0";
          publishPorts = [ "8080:8080" ];
          volumes = [
            "${cfg.volumes.trilium-data.ref}:/home/node/trilium-data"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };
    };
    volumes = {
      trilium-data = {
        quadletConfig.defaultDependencies = false; # WSL only
      };
    };
  }))
]
