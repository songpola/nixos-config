$env.config = {
  show_banner: false,
}

let configPath = $"($env.HOME)/nixos-config"

alias cls = clear

alias gp = git push
alias gc = czg emoji gpg
alias ga = git add .
alias gca = git commit --amend
alias gcan = gca --no-edit

alias nixos-config = nu -e $"cd ($configPath)"
def nixos-switch [] { sudo nixos-rebuild switch --flake (readlink $configPath) }
