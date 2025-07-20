{
  lib,
  pkgs,
  nushell,
  writeTextFile,
  ...
}:
let
  name = builtins.baseNameOf ./.;
  packages = [ pkgs.nh ];
in
writeTextFile {
  inherit name;
  executable = true;
  destination = "/bin/${name}";
  allowSubstitutes = true;
  preferLocalBuild = false;
  text =
    ''
      #!${lib.getExe nushell}

      use std/util "path add"
    ''
    + (packages |> map (package: "path add ${package}/bin") |> lib.concatLines)
    + ''

      def --wrapped main [hostname: string, ...rest] {
        (
          nh os boot github:songpola/nixos-config
            --hostname $hostname
            ...$rest
        )
      }
    '';
}
