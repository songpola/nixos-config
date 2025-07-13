{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace})
    mkHomeConfigModule
    hasBaseEnabled
    sshPublicKey
    githubUserEmail
    githubUserName
    ;
in
lib.${namespace}.mkPresetModule config [ "tools" "git" ] (mkMerge [
  {
    # Enable Git system-wide
    programs.git.enable = true;
  }
  (mkHomeConfigModule (mkMerge [
    {
      # Mangage Git configs
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
          signer = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
          key = sshPublicKey;
        };
      };
    })
  ]))
])
