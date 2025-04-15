{
  # This is the merged library containing your namespaced library as well as all libraries from
  # your flake's inputs.
  lib,
  # Your flake inputs are also available.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: let
  this = builtins.baseNameOf ./.;
in {
  ${this} = {
    prts = rec {
      hostname = "prts.tail7623c.ts.net";
      system = "x86_64-linux";

      mkBuildMachineConfig = system: {
        hostName = hostname;
        sshUser = namespace;
        inherit system;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        protocol = "ssh-ng";
        maxJobs = 12; # 12 cpu cores
        speedFactor = 2;
      };

      mkDeployNodeConfig = self: {
        prts = {
          inherit hostname;
          user = "root";
          profiles.system.path =
            lib.deploy-rs.x86_64-linux.activate.nixos
            self.nixosConfigurations.prts;
          remoteBuild = true;
        };
      };
    };
  };
}
