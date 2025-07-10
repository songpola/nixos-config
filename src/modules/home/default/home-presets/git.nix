{
  lib,
  config,
  osConfig,
  ...
}:
let
  namespace = "songpola";

  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) hasBaseEnabled;
in
lib.${namespace}.mkHomePresetModule config [ "git" ] (mkMerge [
  {
    programs.git = {
      enable = true;
      userEmail = "1527535+songpola@users.noreply.github.com";
      userName = "Songpol Anannetikul";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  }
  (mkIf (osConfig |> hasBaseEnabled "wsl") {
    programs.git = {
      extraConfig = {
        # Use the 1Password SSH agent with WSL integration
        core.sshCommand = "ssh.exe";
        # Sign Git commits with SSH
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.program = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";
      };
    };
  })
])
