{
  enable = true;
  initExtra = ''
    # Use nushell in place of bash if it exists
    # command -v nu &> /dev/null && exec nu
  '';
}
