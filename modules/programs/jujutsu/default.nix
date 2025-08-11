{
  delib,
  pkgs,
  const,
  host,
  ...
}:
delib.module {
  name = "jujutsu";

  options = delib.singleEnableOption host.minienvFeatured;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.jujutsu ];
  };

  home.ifEnabled = {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          email = const.github.userEmail;
          name = const.github.userName;
        };

        # Use Git's "diff3" style conflict markers
        ui.conflict-marker-style = "git";
      };
    };
  };
}
