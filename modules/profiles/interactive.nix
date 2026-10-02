{ den, ... }:
{
  den.aspects.profiles.interactive = {
    includes = with den.aspects.programs; [
      nix-index
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gh
        python3
      ];
    };
  };

  den.aspects.wsl.includes = [ den.aspects.profiles.interactive ];
}
