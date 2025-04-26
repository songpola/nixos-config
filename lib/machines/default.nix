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
      # system = "x86_64-linux";

      mkBuildMachineConfig = {
        hostName = hostname;
        sshUser = namespace;
        system = "-"; # omitted, will defaults to the local platform type.
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        protocol = "ssh-ng";
        maxJobs = 12; # 12 cpu cores
        speedFactor = 2;
        # Get the publicHostKey from: base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJEMXIvanJrSmJDWEs3cDZSTmQ0K2Z5Q2N4WUNsN3RkUHdJR2FXTGhqenEgcm9vdEBwcnRzCg==";
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
