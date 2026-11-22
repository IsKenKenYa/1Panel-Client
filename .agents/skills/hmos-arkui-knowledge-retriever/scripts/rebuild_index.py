"""
Rebuild the `documents` / `categories` / `total_documents` sections of INDEX.json
by scanning the knowledge base directory.

Lossless: existing doc ids are preserved (matched by path); semantic maps
(`component_map`, `keyword_map`, `synonym_groups`, `keywords`) and `version`
are left untouched. The filesystem is the source of truth — a .md file must
exist on disk to have an index entry.

Usage:
    python rebuild_index.py            # rebuild and write back
    python rebuild_index.py --dry-run  # report only, no write
"""

import os
import re
import json
import argparse

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(SCRIPTS_DIR)
DEFAULT_KB_DIR = os.path.join(SKILL_DIR, "references", "knowledges")
INDEX_REL = os.path.join(".system", "INDEX.json")


def extract_title(file_path: str) -> str:
    """Title = first '# ' heading in the markdown; fall back to filename."""
    try:
        with open(file_path, "r", encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("# "):
                    return line[2:].strip()
    except OSError:
        pass
    return os.path.splitext(os.path.basename(file_path))[0]


def scan_markdown(kb_dir: str):
    """Return sorted [(rel_path, abs_path)] for every .md under kb_dir, excluding .system."""
    found = []
    for root, _dirs, files in os.walk(kb_dir):
        rel_root = os.path.relpath(root, kb_dir)
        if rel_root == ".system" or rel_root.startswith(".system" + os.sep) or rel_root.startswith(".system/"):
            continue
        for fn in files:
            if fn.endswith(".md"):
                abs_path = os.path.join(root, fn)
                rel_path = os.path.relpath(abs_path, kb_dir).replace("\\", "/")
                found.append((rel_path, abs_path))
    found.sort(key=lambda x: x[0])
    return found


def next_id_counter(existing_docs):
    nums = []
    for d in existing_docs:
        m = re.match(r"doc_(\d+)", d.get("id", ""))
        if m:
            nums.append(int(m.group(1)))
    return (max(nums) + 1) if nums else 0


def main():
    ap = argparse.ArgumentParser(description="Rebuild INDEX.json documents from the filesystem.")
    ap.add_argument("--kb", default=DEFAULT_KB_DIR, help="Knowledge base directory")
    ap.add_argument("--dry-run", action="store_true", help="Report only, do not write")
    args = ap.parse_args()

    kb_dir = os.path.abspath(args.kb)
    index_path = os.path.join(kb_dir, INDEX_REL)

    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    else:
        data = {
            "version": "1.0",
            "total_documents": 0,
            "categories": {},
            "documents": [],
            "component_map": {},
            "keyword_map": {},
            "synonym_groups": [],
            "keywords": [],
        }
        print(f"INDEX.json not found at {index_path}, initializing empty structure.")

    old_docs = data.get("documents", [])
    path_to_id = {d["path"]: d.get("id") for d in old_docs}
    next_n = next_id_counter(old_docs)

    found = scan_markdown(kb_dir)

    new_docs = []
    assigned_new = 0
    for rel_path, abs_path in found:
        if rel_path in path_to_id:
            doc_id = path_to_id[rel_path]
        else:
            doc_id = f"doc_{next_n:04d}"
            next_n += 1
            assigned_new += 1
        category = rel_path.split("/")[0]
        new_docs.append({
            "id": doc_id,
            "path": rel_path,
            "filename": os.path.basename(rel_path),
            "title": extract_title(abs_path),
            "category": category,
        })

    old_paths = set(path_to_id.keys())
    new_paths = {rel for rel, _ in found}
    orphans = sorted(old_paths - new_paths)

    cats = {}
    for d in new_docs:
        cats[d["category"]] = cats.get(d["category"], 0) + 1

    print(f"Knowledge base : {kb_dir}")
    print(f"Scanned .md    : {len(found)}")
    print(f"New entries    : {assigned_new} (assigned doc_{next_n - assigned_new:04d}..doc_{next_n - 1:04d})")
    print(f"Orphans        : {len(orphans)} (in index but file missing)")
    for o in orphans:
        print(f"  - {o}")
    print(f"Total documents: {len(new_docs)}")
    print("Categories:")
    for c in sorted(cats):
        print(f"  {c:24} {cats[c]}")

    data["documents"] = new_docs
    data["categories"] = {c: cats[c] for c in sorted(cats)}
    data["total_documents"] = len(new_docs)

    if args.dry_run:
        print("\n[dry-run] INDEX.json NOT written.")
        return

    os.makedirs(os.path.dirname(index_path), exist_ok=True)
    with open(index_path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
    print(f"\nWritten: {index_path}")


if __name__ == "__main__":
    main()
