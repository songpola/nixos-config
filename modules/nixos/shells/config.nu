use std/util "path add"

$env.config.show_banner = false

$env.SHELL = ^which nu

# https://github.com/pnpm/pnpm/issues/6476#issuecomment-1859133560
$env.PNPM_HOME = $env.HOME | path join .local share pnpm

path add $env.PNPM_HOME
path add ($env.HOME | path join .pixi bin )

if ($env.VISUAL? | is-not-empty) {
    $env.VISUAL = $env.VISUAL | split row (char space)
}

alias l = ls
alias ga = git add .
alias gcm = czg emoji gpg
alias bm = batman
alias j = just
alias c = clear
alias e = exit
