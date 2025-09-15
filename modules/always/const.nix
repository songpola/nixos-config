{ delib, username, ... }:
delib.module rec {
  name = "const";

  myconfig.always.args.shared.${name} = rec {
    homeDirPath = "/home/${username}";
    nixosConfigPath = "${homeDirPath}/nixos-config";
    timeZone = "Asia/Bangkok";
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz";
    opSshSignWslPath = "/mnt/c/Users/songpola/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
    github = {
      userName = "Songpol Anannetikul";
      userEmail = "ice.songpola@pm.me";
    };
    prts = {
      hostName = "prts.tail7623c.ts.net";
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBD1r/jrkJbCXK7p6RNd4+fyCcxYCl7tdPwIGaWLhjzq";
      binaryCache = {
        publicKey = "prts-1:js8+ltSqLuUR06p1IMycRJtBTINqBlIK7vv5c3ZNnuw=";
        privateKeySecret = "prts/binary-cache-private-key";
      };
    };
  };
}
