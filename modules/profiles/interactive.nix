{ den, ... }:
{
  den.aspects.profiles.interactive = {
    includes = with den.aspects.programs; [
      nix-index
      nix-index.comma
      claude-code
      claude-code.tools
      just.lsp
    ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gh
      ];
    };
  };

  den.aspects.wsl.includes = [ den.aspects.profiles.interactive ];
}
