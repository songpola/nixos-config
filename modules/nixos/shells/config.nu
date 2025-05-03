use std/util "path add"

$env.config.show_banner = false

$env.SHELL = ^which nu

# https://github.com/pnpm/pnpm/issues/6476#issuecomment-1859133560
$env.PNPM_HOME = $env.HOME | path join .local share pnpm

path add $env.PNPM_HOME
path add ($env.HOME | path join .pixi bin)


# If using vscode, use code as default editor for nushell
if ($env.TERM_PROGRAM? == "vscode") {
    $env.config.buffer_editor = ["code", "--wait"]
}

# Use ssh-agent.socket if available
let ssh_agent_socket = $env.XDG_RUNTIME_DIR | path join ssh-agent.socket
if ($ssh_agent_socket | path exists) {
    $env.SSH_AUTH_SOCK = $ssh_agent_socket
}

alias l = ls
alias ga = git add .
alias gcm = czg emoji gpg
alias bm = batman
alias j = just
alias c = clear
alias e = exit
