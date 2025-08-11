{ delib, username, ... }:
delib.module rec {
  name = "const";

  myconfig.always.args.shared.${name} = rec {
    configPath = ./.;
    homeDirPath = "/home/${username}";
    nixosConfigPath = "${homeDirPath}/nixos-config";
    timeZone = "Asia/Bangkok";
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";
    opSshSignWslPath = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
    github = {
      userName = "Songpol Anannetikul";
      userEmail = "1527535+songpola@users.noreply.github.com";
    };
  };
}
