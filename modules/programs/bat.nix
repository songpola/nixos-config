{
  den.aspects.programs.bat = {
    nixos.programs.bat.enable = true;

    homeManager.programs.bat.enable = true;

    # `batman` used to be a cascading sub-option of bat, so it was on whenever
    # bat was. Included from `my.programs.bat` to keep that coupling.
    # includes = [ den.programs.bat.batman ];

    # NOTE: Need to add batman using Home Manager options
    # to avoid shells integration in NixOS options.
    # _.batman.homeManager =
    #   { pkgs, ... }:
    #   {
    #     programs.bat.extraPackages = [ pkgs.bat-extras.batman ];
    #   };
  };
}
