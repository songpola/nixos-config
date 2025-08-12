{ delib, ... }:
delib.module {
  name = "polkit";

  nixos.always = {
    security.polkit = {
      # Used to authenticate when managing system services
      enable = true;

      # Allow members of the "wheel" group to manage system services without password
      # Credit: https://wiki.nixos.org/wiki/Polkit#No_password_for_wheel
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel"))
            return polkit.Result.YES;
        });
      '';
    };
  };

}
