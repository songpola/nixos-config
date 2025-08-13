{
  delib,
  username,
  host,
  lib,
  ...
}:
let
  hostName = "prts.tail7623c.ts.net";
in
delib.module {
  name = "remote-build";

  options =
    with delib;
    { myconfig, ... }:
    {
      enable = boolOption host.remoteBuildFeatured;

      integrations = {
        ssh-agent-wsl.enable = boolOption myconfig.ssh.integrations.ssh-agent-wsl.enable;
      };
    };

  nixos.ifEnabled =
    { myconfig, cfg, ... }:
    {
      nix = {
        # Enable distributed builds
        distributedBuilds = true;

        # Allow the remote build machines to use their substituters
        settings.builders-use-substitutes = true;

        buildMachines = [
          {
            protocol = "ssh-ng";
            sshUser = username;
            inherit hostName;
            system = "x86_64-linux";
            maxJobs = 12;
            speedFactor = 9;
            supportedFeatures = [
              "nixos-test"
              "benchmark"
              "big-parallel"
              "kvm"
            ];
          }
        ];
      };

      # For nix-daemon and root to connect to the remote build machine
      programs.ssh = {
        knownHosts = {
          ${hostName} = {
            extraHostNames = [ "prts" ];
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBD1r/jrkJbCXK7p6RNd4+fyCcxYCl7tdPwIGaWLhjzq";
          };
        };
        extraConfig = lib.mkIf cfg.integrations.ssh-agent-wsl.enable ''
          Host ${hostName}
            User ${username}
            IdentityAgent ${myconfig.ssh.integrations.ssh-agent-wsl.sshAuthSock}
        '';
      };
    };
}
