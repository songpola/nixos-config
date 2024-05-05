$env.config = {
  show_banner: false,
}

alias gc = czg emoji gpg
alias nixos-switch = sudo nixos-rebuild switch --flake (readlink $"($env.HOME)/nixos-config")
