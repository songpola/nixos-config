# let fish_completer = {|spans: list<string>|
#     fish --command $'complete "--do-complete=($spans | str join " ")"'
#     | from tsv --flexible --noheaders --no-infer
#     | rename value description
# }

let zoxide_completer = {|spans: list<string>|
    $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
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
    do $_carapace_completer $spans | if ($in | default [] | where value =~ 'ERR' | is-empty) { $in } else { null }
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
        # use zoxide completions for zoxide commands
        __zoxide_z | __zoxide_zi => $zoxide_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config.completions.external.completer = $external_completer
