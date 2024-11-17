$env.config = { show_banner: false }

$env.PNPM_HOME = $"($env.HOME)/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )

$env.PAGER = "ov"
$env.BAT_PAGER = "ov -F -H3"
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

alias l = ls
alias gcm = czg emoji gpg
alias nos = nh os switch
