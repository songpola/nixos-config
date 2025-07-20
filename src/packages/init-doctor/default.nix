{
  lib,
  # pkgs,
  nushell,
  writeTextFile,
  ...
}:
let
  name = builtins.baseNameOf ./.;

  text =
    ''
      nh os boot github:songpola/nixos-config
        -H doctor
        --
        --extra-experimental-features 'nix-command flakes pipe-operators'
    ''
    |> lib.splitString "\n"
    |> map (line: lib.trim line)
    |> lib.concatStringsSep " "
    |> lib.trim;
in
writeTextFile {
  inherit name;
  executable = true;
  destination = "/bin/${name}";
  allowSubstitutes = true;
  preferLocalBuild = false;
  text = ''
    #!${lib.getExe nushell}

    print "${text}"
  '';
  # + ''
  #   use std/util "path add"
  #   ${(packages |> map (package: "path add ${package}/bin") |> lib.concatLines)}

  # ''
  # + ''
  #   def --wrapped main [hostname: string, ...rest] {
  #     (
  #       nh os boot github:songpola/nixos-config
  #         --hostname $hostname
  #         ...$rest
  #     )
  #   }
  # '';
}
