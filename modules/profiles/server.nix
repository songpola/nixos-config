{ den, ... }:
{
  den.aspects.profiles.server = {
    includes = with den.aspects; [
      programs.getty
      services.openssh
    ];
  };
}
