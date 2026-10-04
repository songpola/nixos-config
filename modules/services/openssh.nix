{ lib, ... }:
{
  # den.schema.user = {
  #   options.authorizedKeys = lib.mkOption {
  #     type = lib.types.listOf lib.types.str;
  #     default = [ ];
  #     description = "SSH public keys allowed to log in as this user (see `programs.ssh-server`).";
  #   };
  # };

  den.aspects.services.openssh = {
    # Allow SSH remote login (public key only)
    nixos.services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };

    # Opt-in: also allow password login
    _.password-login = {
      nixos.services.openssh.settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = true;
      };
    };

    # # Authorize each host user's `authorizedKeys`.
    # # The `user` class lands on `users.users.<userName>`.
    # _.to-users =
    #   { user, ... }:
    #   {
    #     user.openssh.authorizedKeys.keys = user.authorizedKeys;
    #   };
  };
}
