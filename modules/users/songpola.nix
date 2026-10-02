{ den, lib, ... }:
let
  userName = "Songpol Anannetikul";
  userEmail = "ice.songpola@pm.me";

  # 1Password's SSH signing helper on the Windows host, used by git and jj
  # under WSL.
  opSshSignPath = "/mnt/c/Users/songpola/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe";

  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz songpola";
in
{
  # den.schema.user = {
  #   options.sshPublicKey = lib.mkOption {
  #     type = lib.types.nullOr lib.types.str;
  #     default = null;
  #     description = "The user's SSH public key (commit signing, ...).";
  #   };
  #   options.authorizedKeys = lib.mkOption {
  #     type = lib.types.listOf lib.types.str;
  #     default = [ ];
  #     description = "SSH public keys allowed to log in as this user (see `programs.ssh-server`).";
  #   };
  # };

  den.aspects.songpola = {
    includes = [
      den.aspects.primary-user

      # Per-user, not `den.aspects.wsl`: that hook applies to every
      # user on a WSL host, and this signing setup is specific to songpola.
      den.aspects.songpola.wsl-commit-signing

      # (
      #   { host, user }:
      #   {
      #     name = "dialout-group(${user.name}@${host.name})";

      #     # See https://wiki.nixos.org/wiki/Serial_Console#Unprivileged_access_to_serial_device
      #     user.extraGroups = [ "dialout" ];
      #   }
      # )
    ];

    user.openssh.authorizedKeys.keys = [ sshPublicKey ];

    homeManager.programs.git.settings = {
      user.name = userName;
      user.email = userEmail;
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
    };

    _.wsl-commit-signing =
      { host }:
      {
        includes = lib.optionals (host.wsl.enable or false) [
          den.aspects.songpola.git-commit-signing
          den.aspects.songpola.jj-commit-signing
        ];
      };

    # Commit signing with an SSH key held by 1Password on the Windows host.
    _.git-commit-signing =
      { user, ... }:
      {
        homeManager.programs.git.signing = {
          signByDefault = true;
          format = "ssh";
          signer = opSshSignPath;
          key = sshPublicKey;
        };
      };

    homeManager.programs.jujutsu.settings = {
      user.name = userName;
      user.email = userEmail;

      # Use Git's "diff3" style conflict markers (not zdiff3; not support yet)
      ui.conflict-marker-style = "git";

      ui.editor = "code -w";
      ui.diff-editor = "code";
      ui.merge-editor = "code";

      merge-tools.code = {
        diff-args = [
          "--wait"
          "--diff"
          "$left"
          "$right"
        ];
        diff-invocation-mode = "file-by-file";
        edit-args = [
          "--wait"
          "--diff"
          "$left"
          "$right"
        ];
        edit-invocation-mode = "file-by-file";
      };
    };

    _.jj-commit-signing =
      { user, ... }:
      {
        homeManager.programs.jujutsu.settings = {
          signing = {
            behavior = "own";
            backend = "ssh";
            backends.ssh.program = opSshSignPath;
            key = sshPublicKey;
          };
          git.sign-on-push = true;
        };
      };
  };
}
