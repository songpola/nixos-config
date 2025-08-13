{
  delib,
  ...
}:
delib.module {
  name = "delta.integrations.git";

  options = delib.singleEnableOptionDependency "git";

  home.ifEnabled = delib.ifParentEnabled "delta" {
    # Use delta as the default pager for git
    # TODO: https://noborus.github.io/ov/delta/index.html
    programs.git.delta.enable = true;
  };
}
