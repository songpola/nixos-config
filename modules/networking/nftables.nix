{ den, lib, ... }:
{
  den.default = {
    nixos.networking.nftables.enable = true;
  };

  den.aspects.wsl-force-disable-nftables = {
    nixos.networking.nftables.enable = lib.warn ''
      nftables is force disabled, as it does not work well under WSL.
    '' lib.mkForce false;
  };

  den.aspects.wsl.includes = [ den.aspects.wsl-force-disable-nftables ];
}
