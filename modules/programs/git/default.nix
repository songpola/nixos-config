{
  delib,
  const,
  ...
}:
delib.module {
  name = "git";

  options = delib.singleEnableOption false;

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
