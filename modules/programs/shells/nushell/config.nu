use std/util "path add"

$env.config.show_banner = false

# Bun
$env.BUN_INSTALL = [ $env.HOME .bun ] | path join
path add ([ $env.BUN_INSTALL bin ] | path join)

# If using vscode, use code as the default editor
if ($env.TERM_PROGRAM? == "vscode") {
	$env.config.buffer_editor = ["code", "--wait"]
	$env.EDITOR = "code --wait"
}

alias c = clear
alias l = ls

alias sw = nh os switch
alias swn = sw -n
alias bt = nh os boot

alias bm = batman

alias ga = git add .
alias gp = git push

alias gcm = bunx -b czg emoji gpg

alias j = just

alias jl = jj log
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
alias jm = jj bookmark move
alias jmm = jj bookmark move main -t @- # move main to last commit
alias jf = jj git fetch
alias jp = jj git push

alias p = podman

# HTTPie
alias h = ^http
alias hs = ^https
