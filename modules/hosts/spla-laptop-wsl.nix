{ den, ... }:
{
  den.hosts."x86_64-linux"."spla-laptop-wsl" = {
    users."songpola" = { };
    wsl.enable = true;
  };

  den.aspects."spla-laptop-wsl" = {
    nixos.system.stateVersion = "25.11";

    homeManager.home.stateVersion = "25.11";

    includes = with den.aspects; [
      profiles.base
    ];
  };
}
