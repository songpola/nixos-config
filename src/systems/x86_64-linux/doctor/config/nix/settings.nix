{
  pkgs,
  _lib,
}: {
  builders-use-substitutes = true;
  substituters = ["http://prts:5000/"];
  trusted-public-keys = [_lib.public.harmonia];
}
