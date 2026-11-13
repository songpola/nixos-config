#!/usr/bin/env nu
# Cross-seed BearBIT torrents to SeFree with qui, overriding qui's search query.
#
# qui's release parser reads SeFree-style names (Title.2017.S02E07.Episode.Title.TID...)
# with the episode title as the show title, so qui's own searches (Library Scan, the
# torrent menu) send SeFree the wrong query and find nothing. This script calls qui's API
# for each torrent with the series title as the query instead. Don't rename the torrents
# to work around the parser: qui matches the downloaded .torrent to local torrents by name.
#
# Run from any machine that can `ssh prts` (passwordless sudo there):
#   just cross-seed-sefree "Saga of Tanya the Evil"
#   just cross-seed-sefree "Grand Blue Dreaming" --match S03 --dry-run

# Call qui's API from the caddy network, through the arrs-prowlarr container: qui sits
# behind forward-auth on its public address
def qui [method: string, path: string, body?: record] {
    let cmd = [
        "ip=$(sudo -n podman inspect arrs-qui --format '{{(index .NetworkSettings.Networks \"caddy\").IPAddress}}')"
        $"sudo -n podman exec -i arrs-prowlarr curl -s -m 180 -X ($method) -H 'Host: qui.songpola.dev' -H 'Content-Type: application/json' --data-binary @- \"http://$ip:7476($path)\""
    ] | str join "; "
    $body | default {} | to json --raw | ^ssh -o BatchMode=yes prts $cmd | from json
}

# Paths (as qBittorrent sees them) that don't exist on PRTS: data a Sonarr/Radarr
# import moved away instead of hardlinking
def missing-on-prts [paths: list<string>] {
    let cmd = "while IFS= read -r p; do [ -e \"/tank/v2/arrs-data${p#/mnt/starrs-data}\" ] || printf '%s\\n' \"$p\"; done"
    $paths | str join "\n" | $in + "\n" | ^ssh -o BatchMode=yes prts $cmd | lines
}

def main [
    query: string                 # Series title to search SeFree for, e.g. "Saga of Tanya the Evil"
    --match (-m): string = ''     # Extra regex the torrent names must match, e.g. 'S02' or 'S03E0[1-4]'
    --delay (-d): duration = 20sec  # Pause between searches; SeFree answers 403 to bursts
    --dry-run (-n)                # Only list the torrents that would be searched
] {
    # The names must contain the title, spaces matching a space or a dot
    let title = '(?i)' + ($query | str replace --all ' ' '[ .]')
    let narrow = '(?i)' + $match
    let indexer = qui GET /api/torznab/indexers | where name == SeFree | first | get id
    let torrents = qui GET '/api/instances/1/torrents?limit=10000' | get torrents
    # Already on SeFree: same name and size. qui's reflink cross-seeds of a one-file
    # torrent are named after the file, so compare names without the extension.
    let key = {|t| $"($t.name | str replace --regex '\.(mkv|mp4|avi)$' '')/($t.size)" }
    let on_sefree = $torrents
        | where tracker =~ 'sefree' and progress == 1
        | each $key
    let sources = $torrents
        | where tracker =~ 'bit-sv' and progress == 1 and name =~ $title and name =~ $narrow
        | where {|t| (do $key $t) not-in $on_sefree }
        | sort-by name

    if ($sources | is-empty) {
        print $"No BearBIT torrents of ($query) without a SeFree copy"
        return
    }

    let missing = missing-on-prts $sources.content_path
    if ($missing | is-not-empty) {
        print "Skipping these, their files are gone (moved by an import? hardlink the library file back and recheck):"
        $missing | each {|p| print $"  ($p)" }
    }
    let sources = $sources | where content_path not-in $missing

    if $dry_run {
        return ($sources | select hash name size)
    }

    $sources | enumerate | each {|it|
        if $it.index > 0 { sleep $delay }
        let t = $it.item
        print $"Searching ($t.name)"
        let found = qui POST $"/api/cross-seed/torrents/1/($t.hash)/search" {
            indexer_ids: [$indexer]
            cache_mode: bypass
            query: $query
        }
        let results = $found.results? | default []
        let outcome = if ($results | is-empty) {
            let reasons = $found.decisionTrace?.rejectionCounts? | default {}
            $"not found ($reasons | to json --raw)"
        } else {
            let applied = qui POST $"/api/cross-seed/torrents/1/($t.hash)/apply" {
                selections: ($results | select indexer_id indexer download_url title guid)
                use_tag: true
                tag_name: cross-seed
                start_paused: false
            }
            $applied.results
                | each {|r| $r.instance_results? | default [] | each {|i| $"($r.title): ($i.status)" } }
                | flatten
                | str join "; "
        }
        print $"  ($outcome)"
    } | ignore
}
