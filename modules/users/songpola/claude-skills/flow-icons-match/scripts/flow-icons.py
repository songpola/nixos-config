#!/usr/bin/env python3
"""Look up Flow Icons (VS Code icon theme) labels for file and folder names.

Reads the installed extension's generated theme (dim.json), which already
includes the user's custom associations once the icons were rebuilt.

  flow-icons.py match [--recheck-ext] NAME...   built-in check + candidates, as JSON
  flow-icons.py labels file|folder   every label with its associations
  flow-icons.py check file|folder LABEL...
"""

import argparse
import difflib
import glob
import json
import os
import re
import sys

SEARCH_DIRS = [
    "~/.vscode-server/extensions",
    "~/.vscode/extensions",
    "/mnt/c/Users/*/.vscode/extensions",
]

# Folder icons that only set a color; never a semantic match.
COLOR_FOLDERS = {
    "blue", "brown", "gray", "green", "lime", "orange", "pink",
    "purple", "red", "root", "sky", "teal", "yellow",
}


def find_theme(override):
    if override:
        return os.path.join(override, "dim.json")
    found = []
    for d in SEARCH_DIRS:
        found += glob.glob(os.path.join(os.path.expanduser(d), "thang-nm.flow-icons-*", "dim.json"))
    if not found:
        sys.exit("flow-icons: extension not found in " + ", ".join(SEARCH_DIRS))

    # Unlicensed installs ship a small subset; take the most complete one.
    def size(path):
        with open(path) as f:
            return len(json.load(f)["iconDefinitions"])

    return max(found, key=size)


def to_label(name):
    if name.startswith("folder_"):
        return "folder", name[len("folder_"):].replace("_", "-")
    return "file", name.lstrip("_").replace("_", "-")


class Theme:
    def __init__(self, path):
        with open(path) as f:
            t = json.load(f)
        self.path = os.path.dirname(path)
        self.file_names = t["fileNames"]
        self.file_exts = t["fileExtensions"]
        self.folder_names = t["folderNames"]

        # label -> associations (names, *.exts, lang:ids) as meaning hints
        self.icons = {"file": {}, "folder": {}}
        for name in t["iconDefinitions"]:
            if name.startswith("__") or name.endswith("_open") or name == "file":
                continue
            kind, label = to_label(name)
            if kind == "folder" and label in COLOR_FOLDERS:
                continue
            self.icons[kind][label] = []
        for mapping, fmt, kind in [
            (self.file_names, "{}", "file"),
            (self.file_exts, "*.{}", "file"),
            (t["languageIds"], "lang:{}", "file"),
            (self.folder_names, "{}", "folder"),
        ]:
            for key, name in mapping.items():
                hints = self.icons[kind].get(to_label(name)[1])
                if hints is not None:
                    hints.append(fmt.format(key))

    def builtin(self, path, kind, names_only=False):
        """Icon the theme already gives this path, or None."""
        parts = path.strip("/").lower().split("/")
        # Path-scoped keys ("wit/deps") first, longest first.
        suffixes = ["/".join(parts[i:]) for i in range(len(parts))]
        names = self.folder_names if kind == "folder" else self.file_names
        for key in suffixes:
            if key in names:
                return to_label(names[key])[1]
        if kind == "file" and not names_only:
            base = parts[-1]
            dots = [i for i, c in enumerate(base) if c == "." and i > 0]
            for i in dots:  # longest extension first
                ext = base[i + 1:]
                if ext in self.file_exts:
                    return to_label(self.file_exts[ext])[1]
        return None


def tokens(text):
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", text)
    return [t for t in re.split(r"[^a-z0-9]+", text.lower()) if t]


def stem(tok):
    for suf in ("ies", "es", "s"):
        if tok.endswith(suf) and len(tok) > len(suf) + 2:
            return tok[: -len(suf)] + ("y" if suf == "ies" else "")
    return tok


def candidates(theme, kind, base, limit=10):
    # A known extension (yaml, json) matches hundreds of icons; score on the
    # rest of the name. An unknown one (*.foo) is all there is to go on.
    if kind == "file" and "." in base.lstrip("."):
        head, ext = base.rsplit(".", 1)
        if ext.lower() in theme.file_exts and head.strip("."):
            base = head
    want = {stem(t) for t in tokens(base)}
    scored = []
    for label, hints in theme.icons[kind].items():
        label_toks = {stem(t) for t in tokens(label)}
        hint_toks = {stem(t) for h in hints for t in tokens(h)}
        score = 3 * len(want & label_toks) + 2 * len(want & hint_toks)
        for w in want - label_toks:
            if any(difflib.SequenceMatcher(None, w, l).ratio() >= 0.8 for l in label_toks):
                score += 1
        if score:
            scored.append((score, label, hints[:8]))
    scored.sort(key=lambda s: (-s[0], s[1]))
    return [{"label": l, "score": s, "hints": h} for s, l, h in scored[:limit]]


def parse_input(raw):
    """-> (path, [kinds]) from 'folder:x', 'file:x', 'x/' or a bare name."""
    for kind in ("file", "folder"):
        if raw.startswith(kind + ":"):
            return raw[len(kind) + 1:].strip("/"), [kind]
    if raw.endswith("/"):
        return raw.strip("/"), ["folder"]
    base = raw.rsplit("/", 1)[-1]
    if "." in base.lstrip("."):
        return raw, ["file"]
    return raw, ["file", "folder"]  # Makefile, .github, docs...


def cmd_match(theme, args):
    skipped, todo = {}, []
    for raw in args.names:
        path, kinds = parse_input(raw)
        base = path.rsplit("/", 1)[-1]
        # An ambiguous name (Makefile, .github) that already has an icon as
        # either kind is settled.
        icon = next((i for k in kinds if (i := theme.builtin(path, k, args.recheck_ext))), None)
        if icon:
            skipped[raw] = icon
            continue
        for kind in kinds:
            keys = {"name": path}
            if kind == "file" and "." in base.lstrip("."):
                keys["ext"] = "*." + base.lstrip(".").split(".", 1)[1]
            todo.append({
                "input": raw,
                "kind": kind,
                "keys": keys,
                "candidates": candidates(theme, kind, base),
            })
    # One line per item: compact, still easy to scan.
    counts = {k: len(v) for k, v in theme.icons.items()}
    print('{"theme": ' + json.dumps(theme.path) + ', "icons": ' + json.dumps(counts) + ",")
    print(' "skipped": ' + json.dumps(skipped) + ",")
    print(' "todo": [')
    print(",\n".join("  " + json.dumps(t) for t in todo))
    print(" ]}")


def cmd_labels(theme, args):
    for label, hints in sorted(theme.icons[args.kind].items()):
        print(label + ": " + " ".join(hints[:12]))


def cmd_check(theme, args):
    bad = [l for l in args.labels if l not in theme.icons[args.kind]]
    for l in bad:
        print("unknown " + args.kind + " icon: " + l)
    sys.exit(1 if bad else 0)


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--dir", default=os.environ.get("FLOW_ICONS_DIR"),
                   help="extension directory (default: most complete install found)")
    sub = p.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("match")
    m.add_argument("--recheck-ext", action="store_true",
                   help="treat files that only have an extension icon (yaml, json) as unmatched")
    m.add_argument("names", nargs="+")
    l = sub.add_parser("labels")
    l.add_argument("kind", choices=["file", "folder"])
    c = sub.add_parser("check")
    c.add_argument("kind", choices=["file", "folder"])
    c.add_argument("labels", nargs="+")
    args = p.parse_args()

    theme = Theme(find_theme(args.dir))
    {"match": cmd_match, "labels": cmd_labels, "check": cmd_check}[args.cmd](theme, args)


if __name__ == "__main__":
    main()
