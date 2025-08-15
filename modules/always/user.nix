{ delib, username, ... }:
delib.module {
  name = "user";

  nixos.always = {
    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    # To prevent the `error: cannot ... because it lacks a signature by a trusted key`
    nix.settings.trusted-users = [ username ];
  };
}
