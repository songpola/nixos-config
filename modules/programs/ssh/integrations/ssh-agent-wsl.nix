{
  delib,
  host,
  pkgs,
  utils,
  ...
}:
let
  socketName = "ssh-agent-wsl.socket";
  systemdSocketPath = "%t/${socketName}";
  sshAuthSockPath = "/run/${socketName}";
  npiperelayExe = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe";
in
delib.module {
  name = "ssh.integrations.ssh-agent-wsl";

  options =
    with delib;
    enableOptionWith host.isWsl {
      sshAuthSock = strOption sshAuthSockPath;
    };

  # ssh-agent-wsl: Delegate SSH agent to Windows via npiperelay (WSL only)
  nixos.ifEnabled = delib.ifParentEnabled "ssh" (
    { cfg, ... }:
    {
      systemd = {
        sockets."ssh-agent-wsl" = {
          description = "SSH Agent socket relay to Windows via npiperelay";
          listenStreams = [ systemdSocketPath ];
          socketConfig = {
            Accept = true;
          };
          wantedBy = [ "sockets.target" ];
        };

        services."ssh-agent-wsl@" = {
          description = "SSH Agent relay to Windows via npiperelay";
          serviceConfig = {
            ExecStart = "${pkgs.nushell}/bin/nu ${
              utils.escapeSystemdExecArgs [
                "--stdin"
                "-c"
                "${npiperelayExe} -v -p -ei -s //./pipe/openssh-ssh-agent"
              ]
            }";
            StandardInput = "socket";
            StandardOutput = "socket";
            StandardError = "journal";
          };
        };
      };

      environment.sessionVariables = {
        SSH_AUTH_SOCK = cfg.sshAuthSock;
      };
    }
  );
}
