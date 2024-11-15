$env.config = { show_banner: false }

$env.PNPM_HOME = $"($env.HOME)/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )

$env.PAGER = "ov"
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"

alias _ls = ls
alias gcm = czg emoji gpg
alias nos = nh os switch
alias f = fuck
