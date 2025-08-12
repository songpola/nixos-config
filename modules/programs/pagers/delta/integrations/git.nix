{
  delib,
  ...
}:
delib.module {
  name = "delta.integrations.git";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.git.enable args;

  home.ifEnabled = {
    # Use delta as the default pager for git
    # TODO: https://noborus.github.io/ov/delta/index.html
    programs.git.delta.enable = true;
  };
}
