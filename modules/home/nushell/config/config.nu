$env.config = {
  show_banner: false,
}

let configPath = $"($env.HOME)/nixos-config"

alias cls = clear
alias gc = czg emoji gpg
alias nixos-config = nu -e $"cd ($configPath)"
def nixos-switch [] { sudo nixos-rebuild switch --flake (readlink $configPath) }
