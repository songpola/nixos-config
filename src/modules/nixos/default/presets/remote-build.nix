{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "remote-build" ] {
  systemConfig = [
    {
      nix = {
        # Enable distributed builds
        distributedBuilds = true;

        # Allow the remote build machines to use their substituters
        settings.builders-use-substitutes = true;

        # Use prts as the build machine
        buildMachines = [
          {
            protocol = "ssh-ng";
            sshUser = namespace;
            hostName = "prts"; # prts.tail7623c.ts.net
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
    }
  ];
}
