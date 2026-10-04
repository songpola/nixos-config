{ inputs, ... }:
{
  # Needs a new release to support Nushell (Latest check: 2026-09-30)
  # https://github.com/nix-community/nix-index/issues/287
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database/";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.programs.nix-index = {
    nixos = {
      imports = [ inputs.nix-index-database.nixosModules.default ];

      programs.nix-index.enable = true;
    };

    homeManager = {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index.enable = true;
    };

    # comma (with the prebuilt index), using nom for builds/shells.
    # comma hardcodes `nix --extra-experimental-features ... <sub>`, so a `nix`
    # shim on its PATH moves the flag after the subcommand and hands
    # build/shell to nom. nom itself gets the real nix first on PATH, or it
    # would call back into the shim.
    _.comma.nixos =
      { config, pkgs, ... }:
      let
        nix = config.nix.package;
        nixShim = pkgs.writeShellScriptBin "nix" ''
          flags=()
          if [ "$1" = "--extra-experimental-features" ]; then
            flags=("$1" "$2")
            shift 2
          fi
          case "$1" in
            build | shell)
              sub=$1
              shift
              PATH=${nix}/bin:$PATH exec ${pkgs.nix-output-monitor}/bin/nom "$sub" "''${flags[@]}" "$@"
              ;;
            *) exec ${nix}/bin/nix "''${flags[@]}" "$@" ;;
          esac
        '';
        comma = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.comma-with-db;
      in
      {
        environment.systemPackages = [
          (pkgs.symlinkJoin {
            name = "comma-nom";
            paths = [ comma ];
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            postBuild = ''
              for cmd in "," "comma"; do
                wrapProgram "$out/bin/$cmd" --prefix PATH : ${nixShim}/bin
              done
            '';
            meta.mainProgram = "comma";
          })
        ];
      };
  };
}
