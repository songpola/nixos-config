{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace})
    mkHomeConfigModule
    githubUserEmail
    githubUserName
    hasBaseEnabled
    sshPublicKey
    opSshSignWslPath
    ;
in
lib.${namespace}.mkPresetModule config [ "tools" "jujutsu" ] (mkMerge [
  {
    environment.systemPackages = [ pkgs.jujutsu ];
  }
  (mkHomeConfigModule (mkMerge [
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
  ]))
])
