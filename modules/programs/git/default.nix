{
  delib,
  const,
  host,
  ...
}:
delib.module {
  name = "git";

  options = delib.singleEnableOption host.minienvFeatured;

  nixos.ifEnabled = {
    programs.git.enable = true;
  };

  home.ifEnabled = {
    programs.git = {
      enable = true;
      inherit (const.github) userEmail userName;
      extraConfig = {
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
      };
    };
  };
}
