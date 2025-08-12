{
  delib,
  ...
}:
delib.module {
  # eza - A modern replacement for ls
  # https://github.com/eza-community/eza
  name = "eza";

  options = delib.singleEnableOption false;

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
