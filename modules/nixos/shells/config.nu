use std/util "path add"

$env.config.show_banner = false
$env.SHELL = ^which nu

# Bun
$env.BUN_INSTALL = [ $env.HOME .bun ] | path join
path add ([$env.BUN_INSTALL bin ] | path join)

# pnpm
# https://github.com/pnpm/pnpm/issues/6476#issuecomment-1859133560
$env.PNPM_HOME = [ $env.HOME .local share pnpm ] | path join
path add $env.PNPM_HOME

# Pixi
path add ([$env.HOME .pixi bin] | path join)

# If using vscode, use code as default editor for nushell
if ($env.TERM_PROGRAM? == "vscode") {
    $env.config.buffer_editor = ["code", "--wait"]
    $env.EDITOR = "code --wait"
}

# Use ssh-agent.socket if available
let ssh_agent_socket = $env.XDG_RUNTIME_DIR | path join ssh-agent.socket
if ($ssh_agent_socket | path exists) {
    $env.SSH_AUTH_SOCK = $ssh_agent_socket
}

# https://github.com/antfu-collective/ni
$env.NI_GLOBAL_AGENT = "bun"

alias l = ls
alias ga = git add .
alias gcm = bunx --bun czg emoji gpg
alias bm = batman
alias j = just
alias c = clear
alias e = exit
