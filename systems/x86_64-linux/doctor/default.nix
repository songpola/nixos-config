{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  # config,
  utils,
  ...
}:
{
  ${namespace} = {
    stateVersions = {
      system = "24.05";
      home = "24.11";
    };

    profiles.wsl = true;

    secrets = {
      enable = true;
      enableOpnix = true;
    };

    containers = {
      enable = true;
      podman.enable = true;
    };

    git.use1PasswordWSL = true;

    tools.development = true;

    distributedBuilds.enable = true;
  };

  programs.virt-manager.enable = true;
}
// lib.${namespace}.mkHomeConfig {
  systemd.user = {
    sockets = {
      ssh-agent-wsl = {
        Unit = {
          Description = "SSH Agent socket relay to Windows via npiperelay";
        };
        Socket = {
          ListenStream = "%t/ssh-agent.socket";
          SocketMode = 0600;
          Accept = true;
        };
        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };
    services = {
      "ssh-agent-wsl@" = let
        npiperelayExe = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe";
      in {
        Unit = {
          Description = "SSH Agent relay to Windows via npiperelay";
        };
        Service = {
          ExecStart = "${pkgs.nushell}/bin/nu ${utils.escapeSystemdExecArgs [
            "--stdin"
            "-c"
            "${npiperelayExe} -ei -s //./pipe/openssh-ssh-agent"
          ]}";
          StandardInput = "socket";
          StandardOutput = "socket";
          StandardError = "journal";
        };
      };
    };
  };
}
