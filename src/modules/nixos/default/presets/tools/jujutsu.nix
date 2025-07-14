{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace})
    githubUserEmail
    githubUserName
    hasBaseEnabled
    sshPublicKey
    opSshSignWslPath
    ;
in
lib.${namespace}.mkPresetModule config [ "tools" "jujutsu" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.jujutsu ];
    }
  ];
  homeConfig = [
    {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            email = githubUserEmail;
            name = githubUserName;
          };

          # Use Git's "diff3" style conflict markers
          ui.conflict-marker-style = "git";
        };
      };
    }
    (mkIf (config |> hasBaseEnabled "wsl") {
      programs.jujutsu = {
        enable = true;
        settings = {
          signing = {
            behavior = "own";
            backend = "ssh";
            backends.ssh.program = opSshSignWslPath;
            key = sshPublicKey;
          };
        };
      };
    })
  ];
}
