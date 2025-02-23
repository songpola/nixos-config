{
  enable = true;
  initExtra = ''
    # Use nushell in place of bash
    SHELL=$(which nu) && [ -x "$SHELL" ] && exec "$SHELL"
  '';
}
