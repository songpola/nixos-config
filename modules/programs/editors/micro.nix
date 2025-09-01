{
  delib,
  pkgs,
  ...
}:
delib.module {
  # micro - A modern and intuitive terminal-based text editor
  # https://github.com/zyedidia/micro
  name = "micro";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment = {
      systemPackages = [ pkgs.micro ];
      # sessionVariables.EDITOR = "micro"; # set as default editor
    };
  };

  home.ifEnabled = {
    programs.micro = {
      enable = true;

      # Fix clipboard not working in SSH sessions:
      # Use OSC 52 (terminal clipboard)
      settings.clipboard = "terminal";
    };
  };
}
