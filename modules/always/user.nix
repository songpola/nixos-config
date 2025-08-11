{ delib, username, ... }:
delib.module {
  name = "user";

  nixos.always = {
    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
