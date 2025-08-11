{ delib, ... }:
let
  name = "mylib";

  args = {
    ${name} = {
      baseNameWith = p: n: "${baseNameOf p}.${n}";
    };
  };
in
delib.module {
  inherit name;

  # FIXME: `error: infinite recursion encountered`
  # myconfig.always = {
  #   args.shared = args;
  # };

  nixos.always._module.args = args;
  home.always._module.args = args;
}
