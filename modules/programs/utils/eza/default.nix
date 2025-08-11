{
  delib,
  host,
  ...
}:
delib.module {
  # eza - A modern replacement for ls
  # https://github.com/eza-community/eza
  name = "eza";

  options = delib.singleEnableOption host.stdenvFeatured;

  home.ifEnabled = {
    programs.eza = {
      enable = true;
      extraOptions = [
        "-g" # list each file's group
        "--group-directories-first"
      ];
    };
  };
}
