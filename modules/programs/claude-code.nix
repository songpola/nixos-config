{
  den.aspects.programs.claude-code = {
    homeManager = { pkgs, ... }: {
      programs.claude-code = {
        enable = true;
        package = pkgs.unstable.claude-code;
      };
    };

    # CLI tools Claude Code reaches for, beyond what `profiles.base` provides.
    _.tools.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          python3
          file
          unzip
          sqlite
        ];
      };
  };
}
