#!/usr/bin/env python3
"""Export a DFX analysis report from markdown to a self-contained HTML file.

Usage:
  python export_report.py --type cpp_crash --title "..." < report.md
  python export_report.py --type js_crash --input report.md --output-dir <dir>
  python export_report.py --type batch --input 00-summary.md --input 01-appfreeze.md --input 02-cppcrash.md

Writes <output-dir>/dfx-report-<type>-<YYYYMMDD-HHMMSS>.html (output-dir
defaults to dfx-reports under the current working directory, i.e. the
project directory the tool was started in) and prints the absolute path of the
written file to stdout. Repeated --input files are joined in order with a ---
separator (batch sections).

Style contract: the HTML skeleton and all CSS live in report_template.html
(next to this script) as the single source of truth for report styling — the
same template plus the same markdown always renders the same style. The
template also ships a fixed floating table of contents (right side, anchor
links with active-section highlighting, hidden on narrow screens and in print)
and caps code blocks at 70vh with scrollbars so oversized repair diffs stay
browsable. Every table is wrapped in a horizontal-scroll container so wide
tables (stack frames, batch diagnosis summaries) never overflow the page and
overlap the TOC. This script only renders markdown to HTML body fragments:
  - fenced code blocks with basic syntax highlighting (ts/ets/js/c/cpp/json/py)
  - fenced diff blocks with normalized +/-/@@ line coloring (file headers
    `--- a/x` / `+++ b/x` are tolerated and rendered neutrally so model-side
    format drift does not change the diff look)
  - headings, tables, lists, inline code and emphasis
"""

import argparse
import datetime
import html
import os
import re
import sys

for _stream in (sys.stdin, sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

TEMPLATE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "report_template.html")

KEYWORDS = {
    "ts": r"\b(let|const|var|function|class|extends|implements|interface|enum|type|import|export|from|as|return|if|else|for|while|switch|case|break|continue|new|this|super|typeof|instanceof|in|of|try|catch|finally|throw|async|await|yield|static|public|private|protected|readonly|declare|namespace|abstract|get|set|void|any|unknown|never|string|number|boolean|null|undefined|true|false)\b",
    "js": r"\b(let|const|var|function|class|extends|import|export|from|as|return|if|else|for|while|switch|case|break|continue|new|this|typeof|instanceof|in|of|try|catch|finally|throw|async|await|yield|static|get|set|void|null|undefined|true|false)\b",
    "c": r"\b(void|int|char|long|short|unsigned|signed|float|double|struct|enum|union|typedef|static|const|extern|inline|sizeof|return|if|else|for|while|do|switch|case|break|continue|goto|default|volatile|register|auto)\b",
    "json": r"\b(true|false|null)\b",
    "py": r"\b(def|class|import|from|as|return|if|elif|else|for|while|break|continue|pass|try|except|finally|raise|with|yield|lambda|global|nonlocal|assert|del|in|is|not|and|or|None|True|False|self|async|await)\b",
}
KEYWORDS["ets"] = KEYWORDS["ts"]
KEYWORDS["ts"] = KEYWORDS["ts"]
KEYWORDS["javascript"] = KEYWORDS["js"]
KEYWORDS["typescript"] = KEYWORDS["ts"]
KEYWORDS["arkts"] = KEYWORDS["ts"]
KEYWORDS["cpp"] = KEYWORDS["c"] + r"|\b(class|public|private|protected|virtual|override|template|typename|namespace|using|new|delete|this|nullptr|constexpr|noexcept|auto)\b"
KEYWORDS["c++"] = KEYWORDS["cpp"]
KEYWORDS["python"] = KEYWORDS["py"]
KEYWORDS["bash"] = r"\b(if|then|elif|else|fi|for|while|until|do|done|case|esac|function|return|exit|export|local|readonly|shift|source|echo|cd|set|unset|python3?|pip3?)\b"

LANG_ALIAS = {
    "ets": "ts",
    "typescript": "ts",
    "arkts": "ts",
    "javascript": "js",
    "c++": "cpp",
    "python": "py",
    "sh": "bash",
    "shell": "bash",
    "zsh": "bash",
    "console": "bash",
}


def highlight_code(code, lang):
    """Tokenize source into (kind, text) spans: kw / str / com / num / txt."""
    lang = LANG_ALIAS.get(lang, lang)
    if lang not in KEYWORDS:
        return [("txt", code)]
    kw = KEYWORDS[lang]
    if lang in ("c", "cpp"):
        comment = r"//[^\n]*|/\*.*?\*/"
    elif lang in ("py", "bash"):
        comment = r"#[^\n]*"
    else:
        comment = r"//[^\n]*|/\*.*?\*/"
    pattern = re.compile(
        "(?P<com>%s)|(?P<str>'(?:\\\\.|[^'\\\\])*'|\"(?:\\\\.|[^\"\\\\])*\"|`(?:\\\\.|[^`\\\\])*`)|(?P<kw>%s)|(?P<num>\\b0x[0-9a-fA-F]+\\b|\\b\\d+(?:\\.\\d+)?\\b)"
        % (comment, kw),
        re.DOTALL,
    )
    out = []
    pos = 0
    for m in pattern.finditer(code):
        if m.start() > pos:
            out.append(("txt", code[pos : m.start()]))
        kind = m.lastgroup
        out.append((kind, m.group(0)))
        pos = m.end()
    if pos < len(code):
        out.append(("txt", code[pos:]))
    return out


def render_code_block(code, lang):
    if lang == "diff":
        rows = []
        for line in code.split("\n"):
            if re.match(r"^(---|\+\+\+)( |$)", line):
                cls = "diff-file"
            elif line.startswith("+"):
                cls = "diff-ins"
            elif line.startswith("-"):
                cls = "diff-del"
            elif line.startswith("@"):
                cls = "diff-hunk"
            else:
                cls = "diff-txt"
            rows.append('<span class="%s">%s</span>' % (cls, html.escape(line) or "&nbsp;"))
        return "<pre><code>" + "\n".join(rows) + "</code></pre>"
    spans = []
    for kind, text in highlight_code(code, lang):
        esc = html.escape(text)
        spans.append(('<span class="tok-%s">%s</span>' % (kind, esc)) if kind != "txt" else esc)
    return "<pre><code>" + "".join(spans) + "</code></pre>"


TASK_ITEM = re.compile(r"^\[([ xX])\]\s+")

ESCAPED_PIPE = re.compile(r"(?<!\\)\|")


def split_table_row(row):
    """Split a markdown table row on unescaped pipes (GFM-style).

    Cells legitimately containing ``|`` — stack frames like
    ``at makeContent (entry\\|@bundle\\|1.0.0\\|src/...)`` — escape it as
    ``\\|``; splitting on the raw pipe tore those frames into extra columns
    and blew up the table width. Split first, then drop empty edge cells.
    """
    cells = ESCAPED_PIPE.split(row.strip())
    if not cells[0].strip():
        cells = cells[1:]
    if cells and not cells[-1].strip():
        cells = cells[:-1]
    return [cell.strip().replace("\\|", "|") for cell in cells]


def task_list_text(content):
    m = TASK_ITEM.match(content)
    if m:
        return "%s %s" % ("\u2611" if m.group(1) in "xX" else "\u2610", content[m.end() :])
    return content


INLINE_CODE = re.compile(r"`([^`\n]+)`")
BOLD = re.compile(r"\*\*([^*\n]+)\*\*")
ITALIC = re.compile(r"(?<!\*)\*([^*\n]+)\*(?!\*)")


def render_inline(text):
    out = html.escape(text)
    out = INLINE_CODE.sub(r"<code>\1</code>", out)
    out = BOLD.sub(r"<strong>\1</strong>", out)
    out = ITALIC.sub(r"<em>\1</em>", out)
    return out


def render_markdown(md):
    lines = md.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    out = []
    headings = []
    heading_seq = 0
    i = 0
    para = []
    list_items = []
    list_ordered = False

    def flush_para():
        if para:
            out.append("<p>%s</p>" % render_inline(" ".join(para)))
            para.clear()

    def flush_list():
        if list_items:
            tag = "ol" if list_ordered else "ul"
            out.append("<%s>%s</%s>" % (tag, "".join("<li>%s</li>" % item for item in list_items), tag))
            list_items.clear()

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("```"):
            flush_para()
            flush_list()
            lang = stripped[3:].strip().lower()
            body = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                body.append(lines[i])
                i += 1
            out.append(render_code_block("\n".join(body), lang))
        elif stripped.startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|[\s:|-]+\|\s*$", lines[i + 1]):
            flush_para()
            flush_list()
            header = split_table_row(stripped)
            i += 2
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(split_table_row(lines[i]))
                i += 1
            out.append(
                '<div class="table-wrap"><table><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>'
                % (
                    "".join("<th>%s</th>" % render_inline(c) for c in header),
                    "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % render_inline(c) for c in row) for row in rows),
                )
            )
            continue
        elif re.match(r"^#{1,6}\s", stripped):
            flush_para()
            flush_list()
            level = len(stripped) - len(stripped.lstrip("#"))
            level = min(level, 6)
            heading_seq += 1
            heading_id = "s-%d" % heading_seq
            out.append('<h%d id="%s">%s</h%d>' % (level, heading_id, render_inline(stripped[level:].strip()), level))
            headings.append((level, re.sub(r"[`*]", "", stripped[level:].strip()), heading_id))
        elif re.match(r"^[-*]\s+", stripped):
            flush_para()
            if list_ordered:
                flush_list()
            list_ordered = False
            list_items.append(render_inline(task_list_text(re.sub(r"^[-*]\s+", "", stripped))))
        elif re.match(r"^\d+[.)]\s+", stripped):
            flush_para()
            if not list_ordered:
                flush_list()
            list_ordered = True
            list_items.append(render_inline(task_list_text(re.sub(r"^\d+[.)]\s+", "", stripped))))
        elif stripped == "":
            flush_para()
            flush_list()
        elif stripped.startswith(">"):
            flush_para()
            flush_list()
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                quote_lines.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            inner = "\n".join(quote_lines).strip()
            paragraphs = re.split(r"\n\s*\n", inner)
            body = "".join(
                "<p>%s</p>" % render_inline(" ".join(p.split("\n")))
                for p in paragraphs
                if p.strip()
            )
            out.append("<blockquote>%s</blockquote>" % body)
            continue
        elif re.match(r"^-{3,}$|^\*{3,}$", stripped):
            flush_para()
            flush_list()
            out.append("<hr>")
        else:
            flush_list()
            para.append(stripped)
        i += 1
    flush_para()
    flush_list()
    return "\n".join(out), headings


TYPE_LABELS = {
    "cpp_crash": "Native 崩溃（CppCrash）",
    "js_crash": "ArkTS/JS 崩溃（JSCrash）",
    "app_freeze": "应用冻屏（AppFreeze）",
    "sample_stack": "采样栈（增强日志）",
    "white_screen": "非崩溃型白屏（WhiteScreen）",
    "batch": "批量合并报告",
    "unknown": "无法判定",
}


def build_toc(headings):
    """目录按相对层级收录：文档中最浅的两级标题（标题级 + 章节级）。

    各 Analyzer 模板的标题层级习惯不同（appfreeze/cppcrash 为 h1 标题 + h2 章节 +
    h3 小节；jscrash 为 h2 标题 + h3 章节）。按绝对层级（如固定 h1/h2）会使 jscrash
    的 h3 章节整章无法进入目录；按"最浅两级"则对两种层级习惯都成立，更深层级
    （证据链步骤、修复建议简明标题等）保留锚点但不进目录。

    批量合并报告例外（h1 + h2 类型组 + h3 日志分节 + h4 章节，共四级）：最浅两级
    只会收录标题与类型组，逐份日志条目全部丢失——此时改收 h2/h3（类型组 + 日志），
    h4 章节仍不进目录。
    """
    if not headings:
        return ""
    levels = sorted({level for level, _, _ in headings})
    if levels[-1] >= 4:
        kept_levels = [2, 3]
    else:
        kept_levels = levels[:2]
    depth_of = {level: index + 1 for index, level in enumerate(kept_levels)}
    items = ['<div class="toc-title">目录</div>']
    for level, text, heading_id in headings:
        if level not in depth_of:
            continue
        items.append('<a href="#%s" class="toc-%d">%s</a>' % (heading_id, depth_of[level], html.escape(text)))
    return "\n".join(items)


def build_html(title, fault_type, body_html, generated_at, template, toc_html=""):
    label = TYPE_LABELS.get(fault_type, fault_type)
    out = template
    for key, value in (
        ("{{TITLE}}", html.escape(title)),
        ("{{TYPE_LABEL}}", html.escape(label)),
        ("{{GENERATED_AT}}", generated_at),
        ("{{BODY}}", body_html),
        ("{{TOC}}", toc_html),
    ):
        out = out.replace(key, value)
    return out


def unique_path(directory, name):
    candidate = os.path.join(directory, name)
    stem, ext = os.path.splitext(name)
    n = 1
    while os.path.exists(candidate):
        candidate = os.path.join(directory, "%s-%d%s" % (stem, n, ext))
        n += 1
    return candidate


def main():
    parser = argparse.ArgumentParser(description="Export DFX analysis report markdown to a self-contained HTML file.")
    parser.add_argument("--type", required=True, help="fault type from the triage verdict (e.g. cpp_crash)")
    parser.add_argument("--title", default="", help="report title; defaults to 'DFX 故障分析报告 - <type>'")
    parser.add_argument("--input", action="append", help="markdown report file; repeat for batch sections, joined in order with --- separators; reads stdin when omitted")
    parser.add_argument("--output-dir", help="output directory; defaults to <cwd>/dfx-reports")
    args = parser.parse_args()

    if args.input:
        parts = []
        for input_path in args.input:
            with open(input_path, "r", encoding="utf-8") as f:
                parts.append(f.read())
        md = "\n\n---\n\n".join(parts)
    else:
        md = sys.stdin.read()

    output_dir = args.output_dir or os.path.join(os.getcwd(), "dfx-reports")
    os.makedirs(output_dir, exist_ok=True)

    try:
        with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
            template = f.read()
    except OSError as error:
        print("Error: report template not found or unreadable: %s (%s)" % (TEMPLATE_PATH, error), file=sys.stderr)
        return 1

    now = datetime.datetime.now()
    name = "dfx-report-%s-%s.html" % (re.sub(r"[^a-z0-9_-]", "-", args.type.lower()), now.strftime("%Y%m%d-%H%M%S"))
    path = unique_path(output_dir, name)

    title = args.title or ("DFX 故障分析报告 - %s" % TYPE_LABELS.get(args.type, args.type))
    body_html, headings = render_markdown(md)
    document = build_html(
        title, args.type, body_html, now.strftime("%Y-%m-%d %H:%M:%S"), template, build_toc(headings)
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(document)
    print(os.path.abspath(path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
