use std/util "path add"

$env.config.show_banner = false

path add "~/.cargo/bin"

$env.SHELL = ^which nu

# The list of completers is cached to not impact shell startup time.
# Clear the cache with `carapace --clear-cache` if your system changes.
$env.CARAPACE_BRIDGES = [
    zsh fish bash inshellisense
    cobra
    jj
] | str join ","

# If the terminal is VS Code terminal, use code as the default editor
if ($env.TERM_PROGRAM? == "vscode") {
    $env.config.buffer_editor = ["code", "--wait"]
    $env.VISUAL = $env.config.buffer_editor | str join ' '
    $env.EDITOR = $env.VISUAL
}

# Shortcut for nom/nix shell
def shell [
    ...pkgs
    --flake (-f) = "nixpkgs"
    --dry (-n)
    --unfree (-u)
] {
    let pkgs = ($pkgs | default -e [ "default" ]) | each { |pkg| $flake + "#" + $pkg }
    let impure = if $unfree { [ "--impure" ] } else { [] }
    # If `nom` (nix-output-monitor) is available, use it instead of `nix shell`
    let bin = if (which nom | is-not-empty) { "nom" } else { "nix" }
    let cmd = [ $bin shell ...$impure ...$pkgs ]
    if $dry {
        print $cmd
    } else {
        if $unfree {
            with-env { NIXPKGS_ALLOW_UNFREE: "1" } {
                run-external $cmd
            }
        } else {
            run-external $cmd
        }
    }
}

alias c = clear

alias eza = eza --group --group-directories-first --time-style=relative
alias l = eza
alias ll = eza -l
alias la = eza -aa
alias lla = eza -l -aa
alias lt = eza --tree
alias llt = eza -l --tree

alias sw = nh os switch
alias swn = nh os switch -n
alias bt = nh os boot

alias bm = batman

alias gs = git status
alias ga = git add .

alias gcm = bunx -b czg emoji gpg

alias j = just

alias jl = jj log
alias jlr = jj log -r
alias jla = jj log -r ::
alias je = jj edit
alias jc = jj commit
alias jd = jj desc
alias jdf = jj diff
alias js = jj split
alias jsh = jj show
alias jsq = jj squash
alias jst = jj status
alias jr = jj rebase
alias jn = jj new
alias jnm = jj new main
alias jb = jj bookmark
alias jbs = jj bookmark set
alias jsm = jj bookmark set main -r @- # set main bookmark to last revision
alias jab = jj abandon
alias jun = jj undo
alias jfa = jj file annotate
alias jfu = jj file untrack
alias ji = jj git init
alias jf = jj git fetch
alias jp = jj git push
alias jrl = jj git remote list
alias jra = jj git remote add
alias jrs = jj git remote set-url
alias jgc = jj git clone

alias p = podman

alias h = ^http # HTTPie http
alias hs = ^https # HTTPie https

alias ze = zellij

alias da = direnv allow

alias skr = ssh-keygen -R

# Check open ports with ss command
#
# OPTIONS:
# -n, --numeric     do not try to resolve service names.
# -l, --listening   display only listening sockets (these are omitted by default).
# -t, --tcp         display TCP sockets.
# -u, --udp         display UDP sockets.
# -p, --processes   show process using socket.
alias check-open-ports = sudo ss -tunlp
