{
  delib,
  pkgs,
  ...
}:
delib.module {
  # HTTPie CLI - modern, user-friendly command-line HTTP client for the API era
  # https://github.com/httpie/cli
  name = "httpie";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.httpie ];
  };
}
