# prts: home server. Host facts, profiles and system basics; the rest is split by concern:
# hardware.nix (GPU, ZFS, boot), disks.nix (layout), network.nix, containers.nix,
# auth.nix (Kanidm, oauth2-proxy).
{ den, ... }:
{
  den.hosts."x86_64-linux"."prts" = {
    users."songpola" = { };
    zfs.enable = true;
    nvidia.enable = true;

    settings.programs.getty.autologinUser = "songpola";
  };

  den.aspects."prts" = {
    includes = with den.aspects; [
      profiles.base
      profiles.server

      security.passwordless-wheel

      programs.sops

      services.auto-upgrade
      services.auto-upgrade.allow-reboot
    ];

    nixos.system.stateVersion = "24.11";

    homeManager.home.stateVersion = "24.11";
  };
}
