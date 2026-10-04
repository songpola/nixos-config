{ den, ... }:
{
  den.aspects.profiles.interactive = {
    includes = with den.aspects.programs; [
      nix-index
      claude-code
      claude-code.tools
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gh
      ];
    };
  };

  den.aspects.wsl.includes = [ den.aspects.profiles.interactive ];
}
