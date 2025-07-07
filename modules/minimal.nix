{ pkgs, ... }:
{
  # Setup minimal environment
  environment = {
    systemPackages = with pkgs; [
      git
      micro
    ];
    variables = {
      EDITOR = "micro";
    };
  };

  # https://github.com/nix-community/nh
  programs.nh = {
    enable = true;
    clean.enable = true; # auto clean (default: weekly)
  };
}
