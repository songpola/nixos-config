{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "minienv";

  options = delib.singleEnableOption host.minienvFeatured;

  myconfig.ifEnabled =
    [
      # VCS
      "git"
      "jujutsu"

      # Editors / Pagers
      "micro"
      "ov"
      "vscode-remote"

      # Shells
      "bash"
      "nushell"

      # Tools
      "bat"
      "eza"
      "fastfetch"
      "nh"
      "ripgrep"
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
