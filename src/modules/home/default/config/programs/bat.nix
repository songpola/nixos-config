{pkgs}: {
  enable = true;
  extraPackages = with pkgs.bat-extras; [
    batman
    batgrep
  ];
  config = {
    wrap = "never";
  };
}
