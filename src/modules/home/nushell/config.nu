$env.config.show_banner = false

$env.SHELL = ^which nu

# https://github.com/pnpm/pnpm/issues/6476#issuecomment-1859133560
$env.PNPM_HOME = $"($env.HOME)/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME)

alias l = ls
alias gcm = czg emoji gpg
alias nos = nh os switch
alias bm = batman
alias j = just
alias c = clear
alias e = exit
