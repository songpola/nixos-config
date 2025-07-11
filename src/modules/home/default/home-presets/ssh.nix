{
  lib,
  config,
  osConfig,
  pkgs,
  utils, # Need to be supplied by home-manager.extraSpecialArgs from the system config
  ...
}:
let
  namespace = "songpola";

  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) hasBaseEnabled hasHomePresetEnabled;
in
lib.songpola.mkHomePresetModule config [ "ssh" ] (mkMerge [
  {
    # Enable SSH connection multiplexing
    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "10m";
    };
  }
  # Delegate SSH agent to Windows via npiperelay
  (mkIf (osConfig |> hasBaseEnabled "wsl") (mkMerge [
    {
      systemd.user = {
        sockets = {
          ssh-agent-wsl = {
            Unit = {
              Description = "SSH Agent socket relay to Windows via npiperelay";
            };
            Socket = {
              ListenStream = "%t/ssh-agent-wsl.socket";
              SocketMode = 600;
              Accept = true;
            };
            Install = {
              WantedBy = [ "sockets.target" ];
            };
          };
        };
        services = {
          "ssh-agent-wsl@" =
            let
              npiperelayExe = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WinGet/Links/npiperelay.exe";
            in
            {
              Unit = {
                Description = "SSH Agent relay to Windows via npiperelay";
              };
              Service = {
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
    }
    # Integrate with shells if present enabled
    (mkIf (osConfig |> hasHomePresetEnabled [ "shells" ]) {
      programs.nushell = {
        extraConfig = ''
          # Use ssh-agent-wsl.socket if available
          let ssh_agent_wsl_socket = [ $env.XDG_RUNTIME_DIR ssh-agent-wsl.socket ] | path join
          if ($ssh_agent_wsl_socket | path exists) {
              $env.SSH_AUTH_SOCK = $ssh_agent_wsl_socket
          }
        '';
      };
    })
  ]))
])
