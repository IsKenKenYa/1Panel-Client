#!/usr/bin/env python3
"""NAPI register-chain extractor.

Usage:
  python3 extract_register_chain.py FILE [FILE...] [-R ROOT] [--max-body N]

Per input C/C++ file, extracts:
  * __attribute__((constructor)) function bodies
  * register callbacks RESOLVED from registration points:
      - `.nm_register_func = <func>`  (napi_module / napi_module_with_js structs)
      - `NAPI_MODULE(name, <func>)`   (macro form, incl. NAPI_MODULE_xxx variants)
    Callback bodies are located in the same file first, then by searching
    other input files / the ROOT tree (test/example dirs excluded).
    Unresolved callbacks are reported as UNRESOLVED and must be handled
    manually (never silently dropped).
  * nm_modname of each napi_module struct (for module attribution)

Design principle: callback names are resolved from registration-point
fields/macro arguments. NEVER guess by naming conventions (Init / Export /
InitHttpModule / ...) — a callback named InitHttpModule registered via
.nm_register_func must be found even though it does not match "Init(".

Known boundary — header-defined callbacks: this script only searches
implementation files (.cpp/.cc/.cxx/.c); a callback defined in a header is
reported UNRESOLVED. The agent must then follow the #include chain
(include-follow, see references/rulebook.md §4.4 M-17「符号解析」) before
finalizing the 待人工确认 entry.

Output: markdown on stdout. Exit code 0 even with UNRESOLVED items
(the report section marks them for manual follow-up).
"""
import argparse
import os
import re
import sys

EXCLUDE_DIR_SEGMENTS = {"test", "tests", "example", "examples", "sample", "samples"}
SRC_SUFFIXES = (".cpp", ".cc", ".cxx", ".c")

CONSTRUCTOR_RE = re.compile(r'__attribute__\s*\(\(\s*constructor\s*\)\)')
FIELD_RE = re.compile(r'\.nm_register_func\s*=\s*&?\s*([A-Za-z_][\w:]*)')
NM_MODNAME_RE = re.compile(r'\.nm_modname\s*=\s*"([^"]*)"')
MACRO_RE = re.compile(r'\bNAPI_MODULE\w*\s*\(\s*[\w."\']+?\s*,\s*&?\s*([A-Za-z_][\w:]*)')


def mask_source(src):
    """Blank out comments and string/char literals (keep offsets and newlines)."""
    out = list(src)
    n = len(src)
    i = 0
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if c == "/" and nxt == "/":
            while i < n and src[i] != "\n":
                out[i] = " "
                i += 1
        elif c == "/" and nxt == "*":
            out[i] = " "
            out[i + 1] = " "
            i += 2
            while i < n:
                if src[i] == "*" and i + 1 < n and src[i + 1] == "/":
                    out[i] = " "
                    out[i + 1] = " "
                    i += 2
                    break
                if src[i] != "\n":
                    out[i] = " "
                i += 1
        elif c == '"' or c == "'":
            q = c
            out[i] = " "
            i += 1
            while i < n and src[i] != q:
                if src[i] == "\\" and i + 1 < n:
                    out[i] = " "
                    if src[i + 1] != "\n":
                        out[i + 1] = " "
                    i += 2
                else:
                    if src[i] != "\n":
                        out[i] = " "
                    i += 1
            if i < n:
                out[i] = " "
                i += 1
        else:
            i += 1
    return "".join(out)


def match_balanced(masked, open_idx, open_ch="{", close_ch="}"):
    """Return index of the matching closing char, or -1."""
    depth = 0
    for k in range(open_idx, len(masked)):
        if masked[k] == open_ch:
            depth += 1
        elif masked[k] == close_ch:
            depth -= 1
            if depth == 0:
                return k
    return -1


def line_no(masked, idx):
    return masked.count("\n", 0, idx) + 1


def line_start(masked, idx):
    p = masked.rfind("\n", 0, idx)
    return p + 1


def find_function_def(masked, name):
    """Locate a function DEFINITION of `name` in masked source.

    Returns (name_idx, body_open_idx, body_close_idx) or None.
    Handles member definitions (Class::name), free functions, multi-line
    signatures. Declarations (params followed by ';') are skipped.
    """
    last = name.rsplit("::", 1)[-1]  # match on unqualified tail too
    # NOTE: the unqualified-tail fallback can mismatch a same-tail method of a
    # DIFFERENT class (e.g. Other::InitHttpModule vs HttpModuleExports::InitHttpModule).
    # Mitigation: the fully qualified spelling is always tried FIRST; the tail
    # fallback only runs when the qualified name has no definition. Cross-check
    # the surrounding class scope when relying on the fallback.
    for target in {name, last}:
        for m in re.finditer(r"\b%s\s*\(" % re.escape(target), masked):
            open_par = m.end() - 1
            close_par = match_balanced(masked, open_par, "(", ")")
            if close_par < 0:
                continue
            # after params: allow trailing specifiers / trailing return type,
            # then must hit '{' (definition); ';' means declaration -> skip
            k = close_par + 1
            while k < len(masked) and masked[k] in " \t\r\n":
                k += 1
            # skip const / override / noexcept / throw(...) / -> RetType
            while True:
                word = re.match(r"(const|override|noexcept|throw|->)", masked[k:k + 10])
                if not word:
                    break
                if word.group(1) == "throw":
                    p = masked.find("(", k)
                    if p >= 0:
                        cp = match_balanced(masked, p, "(", ")")
                        k = cp + 1 if cp >= 0 else k + 5
                        continue
                    k += 5
                    continue
                if word.group(1) == "->":
                    # trailing return type: scan to next '{' or ';'
                    brace = masked.find("{", k)
                    semi = masked.find(";", k)
                    if brace >= 0 and (semi < 0 or brace < semi):
                        k = brace
                    break
                k += len(word.group(1))
                while k < len(masked) and masked[k] in " \t\r\n":
                    k += 1
            if k < len(masked) and masked[k] == "{":
                close_brace = match_balanced(masked, k)
                if close_brace >= 0:
                    return m.start(), k, close_brace
        # 'name' not found under this spelling; try next spelling
    return None


def extract_span(src, masked, name_idx, body_close, max_body):
    sig_start = line_start(masked, name_idx)
    end = min(body_close + 1, sig_start + max_body)
    text = src[sig_start:end]
    # cap very long bodies by lines
    lines = text.split("\n")
    if len(lines) > max_body // 20:
        lines = lines[: max_body // 20] + ["... (body truncated)"]
    return "\n".join(lines), sig_start, min(body_close + 1, len(src))


def find_constructors(masked):
    """Return list of (func_name, body_open, body_close) for constructor attrs."""
    results = []
    for m in CONSTRUCTOR_RE.finditer(masked):
        # first identifier followed by '(' after the attribute
        fm = re.search(r"([A-Za-z_]\w*)\s*\(", masked[m.end():m.end() + 300])
        if not fm:
            continue
        open_par = m.end() + fm.end() - 1
        close_par = match_balanced(masked, open_par, "(", ")")
        if close_par < 0:
            continue
        k = close_par + 1
        while k < len(masked) and masked[k] in " \t\r\n":
            k += 1
        if k < len(masked) and masked[k] == "{":
            close_brace = match_balanced(masked, k)
            if close_brace >= 0:
                results.append((fm.group(1), m.start(), close_brace))
    return results


def iter_root_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d.lower() not in EXCLUDE_DIR_SEGMENTS and not d.startswith(".")]
        for fn in filenames:
            if fn.endswith(SRC_SUFFIXES):
                yield os.path.join(dirpath, fn)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("-R", "--root", default=None, help="extra tree for cross-file callback resolution")
    ap.add_argument("--max-body", type=int, default=4000, help="max chars of body to print")
    args = ap.parse_args()

    sources = {}  # path -> (src, masked)
    for f in args.files:
        if not os.path.isfile(f):
            print("WARN: not a file: %s" % f, file=sys.stderr)
            continue
        with open(f, "r", encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        sources[f] = (src, mask_source(src))

    # Upfront: all callback names (for the lazy cross-file index below).
    all_cb = set()
    for p in sources:
        for m in FIELD_RE.finditer(sources[p][1]):
            if m.group(1) != "nullptr":
                all_cb.add(m.group(1))
        for m in MACRO_RE.finditer(sources[p][1]):
            if m.group(1) != "nullptr":
                all_cb.add(m.group(1))

    # Cross-file resolution index, built lazily on the first callback that
    # fails same-file resolution. One linear raw-source pass with a combined
    # regex maps each callback-tail -> candidate files; only files containing
    # a hit are masked. (The previous per-callback scan over every pool file
    # was quadratic: callbacks x files x regex-over-filesize.)
    pool_cache = {}
    tail_index = None

    def _ensure_index():
        nonlocal tail_index
        if tail_index is not None:
            return tail_index
        tail_index = {}
        tails = {n.rsplit("::", 1)[-1] for n in all_cb}
        if tails:
            combined = re.compile(
                r'\b(%s)\s*\(' % "|".join(sorted(map(re.escape, tails))))
            for p in sources:
                for t in set(combined.findall(sources[p][0])):
                    tail_index.setdefault(t, []).append(p)
            if args.root:
                for p in iter_root_files(args.root):
                    if p in sources:
                        continue
                    with open(p, "r", encoding="utf-8", errors="replace") as fh:
                        s = fh.read()
                    hits = set(combined.findall(s))
                    if hits:
                        pool_cache[p] = (mask_source(s), s)
                        for t in hits:
                            tail_index.setdefault(t, []).append(p)
        return tail_index

    unresolved = []
    for path, (src, masked) in sources.items():
        constructors = find_constructors(masked)
        modnames = [m.group(1) for m in NM_MODNAME_RE.finditer(masked)]
        # callbacks from struct fields + macros (dedup, keep order)
        cbs = []
        for m in FIELD_RE.finditer(masked):
            cbs.append((m.group(1), "nm_register_func"))
        for m in MACRO_RE.finditer(masked):
            cbs.append((m.group(1), "NAPI_MODULE macro"))
        seen = set()
        cbs = [(n, src_) for n, src_ in cbs if not (n in seen or seen.add(n))]

        print("## %s" % path)
        if modnames:
            print("nm_modname: %s" % ", ".join(modnames))
        for cname, cattr, _cb in constructors:
            body, _, _ = extract_span(src, masked, cattr, _cb, args.max_body)
            print("- constructor `%s` @ L%d-L%d" % (cname, line_no(masked, cattr), line_no(masked, _cb)))
            print("```cpp\n%s\n```" % body)
        if not constructors:
            print("- (no constructor)")
        if not cbs:
            print("- (no nm_register_func / NAPI_MODULE callback)")
        for name, how in cbs:
            d = find_function_def(masked, name)
            where = "same file"
            if d is None:
                idx = _ensure_index()
                for rp in idx.get(name.rsplit("::", 1)[-1], []):
                    if rp == path:
                        continue
                    if rp in sources:
                        rmask, rsrc = sources[rp][1], sources[rp][0]
                    else:
                        rmask, rsrc = pool_cache[rp]
                    d = find_function_def(rmask, name)
                    if d is not None:
                        body, _, _ = extract_span(rsrc, rmask, d[0], d[2], args.max_body)
                        print("- callback `%s` (from %s) resolved in %s @ L%d-L%d"
                              % (name, how, rp, line_no(rmask, d[0]), line_no(rmask, d[2])))
                        print("```cpp\n%s\n```" % body)
                        where = None
                        break
            if d is None:
                unresolved.append((path, name))
                print("- callback `%s` (from %s): **UNRESOLVED** — not defined in input/root（头文件定义场景先按 include-follow 处理，见 rulebook.md §4.4 M-17「符号解析」）; 人工处理，禁止静默跳过" % (name, how))
                continue
            if where == "same file":
                body, _, _ = extract_span(src, masked, d[0], d[2], args.max_body)
                print("- callback `%s` (from %s) @ L%d-L%d"
                      % (name, how, line_no(masked, d[0]), line_no(masked, d[2])))
                print("```cpp\n%s\n```" % body)
        print()

    if unresolved:
        print("## UNRESOLVED CALLBACKS (manual follow-up required)")
        for p, n in unresolved:
            print("- %s: %s" % (p, n))


if __name__ == "__main__":
    main()
