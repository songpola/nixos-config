# { lib, ... }:
{
  # den.schema.user = {
  #   options.authorizedKeys = lib.mkOption {
  #     type = lib.types.listOf lib.types.str;
  #     default = [ ];
  #     description = "SSH public keys allowed to log in as this user (see `programs.ssh-server`).";
  #   };
  # };

  den.aspects.services.openssh = {
    # Allow SSH remote login
    nixos.services.openssh.enable = true;

    # # Authorize each host user's `authorizedKeys`.
    # # The `user` class lands on `users.users.<userName>`.
    # _.to-users =
    #   { user, ... }:
    #   {
    #     user.openssh.authorizedKeys.keys = user.authorizedKeys;
    #   };
  };
}
