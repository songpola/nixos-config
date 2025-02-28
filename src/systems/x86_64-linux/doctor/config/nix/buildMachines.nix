[
  {
    hostName = "prts";
    system = "x86_64-linux";
    sshUser = "songpola";
    protocol = "ssh-ng";
    maxJobs = 3;
    speedFactor = 2;
    supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
  }
]
