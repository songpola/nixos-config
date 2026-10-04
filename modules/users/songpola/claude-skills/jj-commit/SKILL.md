---
name: jj-commit
description: Create commits with jujutsu (jj) instead of git. Use whenever the user asks to commit, describe, split or save changes, or to write a commit message, in a jj repo (a `.jj` directory exists, including colocated jj + git repos).
---

# Committing with jj

jj has no staging area: the working copy is itself a commit (`@`), and every
file change, including new files, is already part of it. "Committing" means
giving `@` a description and starting a new empty change on top.

Never use `git add`, `git commit`, `git checkout` or git branches in a jj repo.
Never pass `-i`/`--interactive` or run anything that opens an editor; there is
no TTY.

## 1. Inspect

Run these together:

- `jj status`: what changed in `@`, and whether `@` already has a description
- `jj diff --git`: the full diff of `@`
- `jj log -r 'ancestors(@, 10)'`: recent messages, to match their style

Check before committing:

- New files are tracked automatically. Look for files that shouldn't be
  committed (build outputs, `result` symlinks, scratch files, local
  credentials). Add them to `.gitignore`, then `jj file untrack <path>`.
- Secrets must only be committed encrypted (e.g. sops files containing
  `ENC[...]`). Stop and tell the user if a plaintext secret is in the diff.
- If `@` is empty but `@-` holds the work with no description, describe `@-`
  instead (`jj describe -r @- ...`); don't create an empty commit.

## 2. Write the message

- Subject: imperative, about 50-72 characters, no trailing period, saying what
  changed and where (e.g. `Add claude-code aspect to interactive profile`).
  Follow the conventions you see in `jj log` (prefixes, casing).
- Conventional Commits: only if the recent `jj log` already uses them
  (subjects like `feat: ...`, `fix(scope): ...`). Then write
  `type(scope): subject`, with the type one of `feat`, `fix`, `refactor`,
  `docs`, `style`, `test`, `perf`, `build`, `ci`, `chore`, the scope optional
  (a module, aspect or host name), a lowercase subject, and `!` after the
  type/scope or a `BREAKING CHANGE:` footer for breaking changes. If the log
  doesn't use them, don't introduce them.
- Body (optional, after a blank line): why the change was made and anything
  non-obvious, wrapped at 72 characters. Skip it for self-explanatory changes.
- Append any commit attribution lines the session instructions ask for.

## 3. Commit

Before committing, group the changed files by purpose and list the groups.
Each group is one single-purpose commit with its own message. Split by file;
don't use `-i`. If one file mixes purposes, commit it with the group it mostly
belongs to and tell the user, or ask them to run `jj split -i` themselves.

A single group (all changes in `@` are one logical change):

```bash
jj commit -m "$(cat <<'EOF'
Subject line

Optional body.
EOF
)"
```

With several groups, commit them one at a time by passing paths (filesets).
The listed paths stay in the described commit; everything else moves to the
new `@` on top:

```bash
jj commit -m "First change" path/a.nix path/b.nix
jj commit -m "Second change" path/c.nix
```

To set or fix a message without starting a new change, use `jj describe -m ...`
(or `-r <rev>` for an earlier one). Use `jj describe --stdin` when the message
comes from a pipe.

## 4. Verify

Run `jj log -r 'ancestors(@, 5)'` and confirm that the descriptions are right
and `@` is empty (or holds only what was intentionally left out).

Don't move bookmarks or push unless the user asks. When they do:
`jj bookmark set <name> -r @-`, then `jj git push`.
