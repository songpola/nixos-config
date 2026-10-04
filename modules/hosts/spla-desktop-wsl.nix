{ den, ... }: {
  den.hosts."x86_64-linux"."spla-desktop-wsl" = {
    users."songpola" = { };
    wsl.enable = true;
  };

  den.aspects."spla-desktop-wsl" = {
    nixos.system.stateVersion = "25.11";

    homeManager.home.stateVersion = "25.11";

    includes = with den.aspects; [
      profiles.base

      programs.podman

      wsl.amd-gpu
    ];
  };
}
