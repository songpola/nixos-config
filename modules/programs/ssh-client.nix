{
  den.aspects.programs.ssh = {
    homeManager.programs.ssh = {
      enable = true;

      # TODO: Remove this line in the future when deprecated
      enableDefaultConfig = false;

      settings."*" = {
        # Enable SSH connection multiplexing
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "10m";

        # # These used to be the defaults from the `enableDefaultConfig` option
        # # Enable as needed.
        # ForwardAgent = false;
        # AddKeysToAgent = "no";
        # Compression = false;
        # ServerAliveInterval = 0;
        # ServerAliveCountMax = 3;
        # HashKnownHosts = false;
        # UserKnownHostsFile = "~/.ssh/known_hosts";
      };
    };

    # This will only work on WSL.
    wsl.ssh-agent.enable = true;
  };
}
