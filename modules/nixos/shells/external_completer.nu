# zoxide completer fix for Nushell 0.103.0+
# https://www.nushell.sh/blog/2025-03-18-nushell_0_103_0.html#external-completers-are-no-longer-used-for-internal-commands-toc
def "nu-complete zoxide path" [context: string] {
    let parts = $context | split row " " | skip 1
    {
        options: {
        sort: false
        completion_algorithm: prefix
        positional: false
        case_sensitive: false
        }
        completions: (zoxide query --list --exclude $env.PWD -- ...$parts | lines)
    }
}

def --env --wrapped z [...rest: string@"nu-complete zoxide path"] {
    __zoxide_z ...$rest
}

# NOTE: As of carapace v1.3.0,
# they havn't implemented flakeref-supported for `nix shell` yet.
# It sill uses the old channel-based way.
#
# ```
# $ nix shell nixpkgs#<tab>
# "nixpkgs#ERR"  stat /home/songpola/.nix-defexpr/channels/nixpkgs/programs.sqlite: no such fi...
# "nixpkgs#_"
# ```
let _carapace_completer = $env.config.completions.external.completer # from carapace.enableNushellIntegration
let carapace_completer = {|spans: list<string>|
    # return null to fall back to Nushell's built-in file completions
    do $_carapace_completer $spans | if ($in | is-not-empty) { $in } else { null }
}

let expand_alias = {|spans: list<string>|
    # if the current command is an alias, get its expansion
    let expanded_alias = scope aliases | where name == $spans.0 | get -i 0.expansion

    if $expanded_alias != null {
        # Note: no need to pass args of the alias,
        # because we just need the completion from the command itself
        $expanded_alias | split row ' ' | take 1 | append ($spans | skip 1)
    } else {
        $spans # the command is not an alias
    }
}

let external_completer = {|spans: list<string>|
    let spans = do $expand_alias $spans
    match $spans.0 {
        _ => $carapace_completer
    } | do $in $spans
}

$env.config.completions.external.completer = $external_completer
