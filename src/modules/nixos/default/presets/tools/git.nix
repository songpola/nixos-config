{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace})
    hasBaseEnabled
    sshPublicKey
    githubUserEmail
    githubUserName
    opSshSignWslPath
    ;
in
lib.${namespace}.mkPresetModule2 config [ "tools" "git" ] {
  systemConfig = [
    {
      programs.git.enable = true;
    }
  ];
  homeConfig = [
    {
      programs.git = {
        enable = true;
        userEmail = githubUserEmail;
        userName = githubUserName;
        extraConfig = {
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
        };
      };
    }
    (mkIf (config |> hasBaseEnabled "wsl") {
      programs.git = {
        extraConfig = {
          # Use the 1Password SSH agent with WSL integration
          core.sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
        };

        # Sign commits with SSH
        signing = {
          signByDefault = true;
          format = "ssh";
          signer = opSshSignWslPath;
          key = sshPublicKey;
        };
      };
    })
  ];
}
