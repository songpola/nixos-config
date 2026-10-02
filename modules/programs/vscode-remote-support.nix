{ den, ... }:
{
  den.aspects.programs.vscode-remote-support = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.wget ];
      };

    # For VS Code extensions
    includes = [ den.aspects.programs.nix-ld ];
  };
}
