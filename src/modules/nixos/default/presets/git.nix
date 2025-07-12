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
lib.${namespace}.mkPresetModule config [ "git" ] (mkMerge [
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
        };
      };
    }
    (mkIf (config |> hasBaseEnabled "wsl") {
      programs.git = {
        extraConfig = {
          # Use the 1Password SSH agent with WSL integration
          core.sshCommand = "ssh.exe";
          # Sign Git commits with SSH
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.program = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
          user.signingkey = sshPublicKey;
        };
      };
    })
  ]))
])
