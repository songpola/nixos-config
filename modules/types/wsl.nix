{
  delib,
  inputs,
  username,
  pkgs,
  host,
  ...
}:
delib.module {
  name = "wsl";

  options = delib.singleEnableOption host.isWsl;

  nixos.always.imports = [ inputs.nixos-wsl.nixosModules.default ];

  nixos.ifEnabled = {
    wsl = {
      enable = true;
      defaultUser = username;
    };

    # Enable xdg-open for opening files and URLs in WSL
    environment.systemPackages = [ pkgs.xdg-utils ];
  };
}
