{
  pkgs,
  _lib,
}: {
  builders-use-substitutes = true;
  substituters = ["http://prts.tail7623c.ts.net:5000/"];
  trusted-public-keys = [_lib.public.harmonia];
}
