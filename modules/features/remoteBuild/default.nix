{
  delib,
  username,
  host,
  const,
  ...
}:
delib.module {
  name = "remoteBuild";

  options =
    with delib;
    enableOptionWith host.remoteBuildFeatured {
      hostName = readOnly (strOption const.prts.hostName);
      sshPublicKey = readOnly (strOption const.prts.sshPublicKey);
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
            inherit (cfg) hostName;
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
      programs.ssh.knownHosts = {
        ${cfg.hostName} = {
          publicKey = cfg.sshPublicKey;
        };
      };
    };
}
