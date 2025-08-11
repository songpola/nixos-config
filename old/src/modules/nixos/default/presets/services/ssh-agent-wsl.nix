{
  lib,
  config,
  namespace,
  pkgs,
  utils,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) hasBaseEnabled mkIfPresetEnabled;

  socketName = "ssh-agent-wsl.socket";
  sshAuthSockPath = "/run/${socketName}";
  systemdSocketPath = "%t/${socketName}";
in
lib.${namespace}.mkPresetModule config [ "services" "ssh-agent-wsl" ] {
  systemConfig = [
    # ssh-agent-wsl: Delegate SSH agent to Windows via npiperelay (WSL only)
    (mkIf (config |> hasBaseEnabled "wsl") (mkMerge [
      {
        systemd = {
          sockets = {
            ssh-agent-wsl = {
              description = "SSH Agent socket relay to Windows via npiperelay";
              listenStreams = [ systemdSocketPath ];
              socketConfig = {
                Accept = true;
              };
              wantedBy = [ "sockets.target" ];
            };
          };
          services = {
            "ssh-agent-wsl@" =
              let
                npiperelayExe = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe";
              in
              {
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
        };

        environment.sessionVariables = {
          SSH_AUTH_SOCK = sshAuthSockPath;
        };
      }
    ]))
  ];
  extraConfig = [
    # For nix-daemon and root to connect to the remote build machine
    (mkIfPresetEnabled config
      [
        "remote-build"
      ]
      {
        systemConfig = [
          {
            programs.ssh = {
              knownHosts = {
                prts = {
                  extraHostNames = [ "prts.tail7623c.ts.net" ];
                  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBD1r/jrkJbCXK7p6RNd4+fyCcxYCl7tdPwIGaWLhjzq";
                };
              };
              extraConfig = ''
                Host prts
                  HostName prts.tail7623c.ts.net
                  User ${namespace}
                  IdentityAgent ${sshAuthSockPath}
              '';
            };
          }
        ];
      }
    )
  ];
  # homeConfig = [
  #   # Integrate with shells if present enabled
  #   (mkIf (config |> hasPresetEnabled [ "shells" ]) {
  #     programs.nushell = {
  #       extraConfig = ''
  #         # Use ssh-agent-wsl.socket if available
  #         let ssh_agent_wsl_socket = "/run/ssh-agent-wsl.socket"
  #         if ($ssh_agent_wsl_socket | path exists) {
  #             $env.SSH_AUTH_SOCK = $ssh_agent_wsl_socket
  #         }
  #       '';
  #     };
  #   })
  # ];
}
