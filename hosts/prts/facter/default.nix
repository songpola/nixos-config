{ delib, inputs, ... }:
delib.host {
  name = "prts";

  nixos = {
    imports = [ inputs.nixos-facter-modules.nixosModules.facter ];

    facter.reportPath = ./facter.json;
  };
}
