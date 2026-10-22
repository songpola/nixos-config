---
name: flow-icons-match
description: Find the Flow Icons (VS Code icon theme) icon that best matches the meaning of file or folder names, and produce `flow-icons.files.associations` / `flow-icons.folders.associations` settings for them. Use when the user asks which Flow icon fits a name, wants icons for files or folders that show a generic icon, or gives a list of names, a directory or a tree to "iconify".
---

# Matching names to Flow Icons

The user's licensed Flow Icons install has about 1277 icons (917 file, 360
folder). Many have no built-in association (`go-alt`, `controller`, ...) and
are only reachable through custom associations. The job: for each name that
doesn't already get an icon, pick the icon whose picture means the same thing,
or say there is none.

`scripts/flow-icons.py` (next to this file) reads the installed extension's
generated theme. That theme already includes the user's custom associations,
so "already has an icon" reflects their current setup (after they last
rebuilt the icons).

## 1. Collect the names

- Names as given: a trailing `/` means a folder; `file:x` / `folder:x` force
  the kind. A bare name with an extension is a file; one without (`Makefile`,
  `.github`, `docs`) is tried as both.
- Paths (`src/store`) are fine: they're matched by their last segment, and the
  path can become a path-scoped association.
- For a directory, list it yourself, e.g.
  `fd --max-depth 2 --type d --format '{}/' . <dir>` plus files, and pass the
  unique names. Skip build outputs, `.git`, `node_modules`, `result`.

## 2. Built-in check and candidates

```bash
python3 ~/.claude/skills/flow-icons-match/scripts/flow-icons.py match <names...>
```

Output:

- `skipped`: names that already show a specific icon (name, path or
  extension association). Drop them: don't report or reconsider them, unless
  the user asks. Files that only get a generic extension icon (`.sops.yaml` →
  yaml) count as skipped; with `--recheck-ext` they're treated as unmatched
  instead, for when the user wants more specific icons.
- `todo`: one item per name and kind still to match, with `keys` (the
  association key to use) and `candidates`: labels that share words with the
  name or its known associations, scored, each with `hints` (what the icon is
  already assigned to, which says what it depicts).

## 3. Choose

Candidates come from word overlap only. They miss synonyms (`workers` →
`job`) and include false friends (`claude-skills` → `claude` is right,
`wit/deps` → `snowpack` is not). For any item without a clearly right
candidate, read the full label list for that kind once and search it by
meaning:

```bash
python3 ~/.claude/skills/flow-icons-match/scripts/flow-icons.py labels folder   # ~350 lines
python3 ~/.claude/skills/flow-icons-match/scripts/flow-icons.py labels file     # ~920 lines, grep it
```

Each line is `label: hints...`.

Rules:

- The icon must depict what the name means: the same concept, a synonym, or
  the tool or brand the name refers to (`notes/` → a docs icon fits; a plain
  text icon doesn't). Loosely related isn't enough; then the answer is null.
- File names get file icons, folder names get folder icons.
- Prefer the most specific icon: a tool's own icon over a generic category,
  a category over nothing.
- Judge labels with their hints; a label alone can mislead.
- Variants (`-alt`, `-alt-2`) are the same concept in another style: pick the
  base icon unless the user asked for a variant.

Validate every chosen label before reporting:

```bash
python3 ~/.claude/skills/flow-icons-match/scripts/flow-icons.py check folder <labels...>
```

## 4. Association keys

- Folder: the bare name (`"workers"`), or the given path (`"src/store"`) when
  the meaning only holds in that place.
- File: the name (`"Taskfile.yml"`) when the meaning comes from the name; the
  extension (`"*.foo"`, from `keys.ext`) when it comes from the extension and
  every file with it should get the icon.
- `**` is treated as `*`; a value of `""` removes an icon.

## 5. Report

A table of matches (input, icon, one-line reason), a line listing names with
no match, and the settings ready to paste into the user's VS Code
`settings.json`. Only include the non-empty blocks:

```jsonc
"flow-icons.folders.associations": {
  "workers": "job"
},
"flow-icons.files.associations": {
  "*.foo": "..."
}
```

Don't edit the settings yourself unless asked. They're the Windows VS Code
user settings (`/mnt/c/Users/<user>/AppData/Roaming/Code/User/settings.json`,
JSONC, already holding some associations to merge with). After a change, the
extension needs "Flow Icons: Rebuild Icons" before the theme, and this
script, see it.

`match` prints the icon count it loaded. If the script finds no install, or
only an unlicensed one (a few hundred icons instead of ~1277), say so instead
of matching against an incomplete set.
