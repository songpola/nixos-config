{ den, ... }:
{
  den.aspects.profiles.server = {
    includes = with den.aspects; [
      programs.getty
      services.openssh

      # Hardware hosts
      programs.sysadmin-tools.hardware
      programs.sysadmin-tools.performance
      services.smartd
    ];
  };
}
