#!/usr/bin/env python3
"""对比报告 md → html：注入步骤4前后对比火焰图链接，浏览器点击跳转查看。

用法:
    python scripts/2_analysis/report_md_to_html.py <报告.md> [-o <报告.html>]

依赖: pip install markdown
"""
import argparse
import os
import re
import sys

try:
    import markdown
except ImportError:
    print("缺少 markdown 库，请安装: python -m pip install markdown", file=sys.stderr)
    sys.exit(1)

CSS = """\
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f0f2f5;color:#1a1a2e;font-size:13px}
.hd{background:#1a1a2e;color:#fff;padding:12px 20px;display:flex;align-items:center;gap:16px;flex-wrap:wrap}
.hd-title{font-size:15px;font-weight:700}
.hd-meta{font-size:11px;color:rgba(255,255,255,.5)}
.hd-subline{font-size:11px;color:rgba(255,255,255,.4);margin-top:2px}
.hd-pills{margin-left:auto;display:flex;gap:6px;flex-wrap:wrap}
.pill{font-size:11px;font-weight:600;padding:2px 10px;border-radius:12px}
.pill-r{background:rgba(231,76,60,.25);color:#ff6b6b}
.pill-y{background:rgba(230,126,34,.25);color:#ffa94d}
.pill-g{background:rgba(39,174,96,.25);color:#69db7c}
.layout{display:flex;align-items:flex-start}
.toc{position:sticky;top:0;width:180px;min-width:180px;height:100vh;overflow-y:auto;background:#fff;border-right:1px solid #eef0f3;padding:16px 12px;font-size:12px}
.toc-title{font-weight:700;color:#2d3436;margin-bottom:10px;font-size:13px}
.toc a{display:block;color:#95a5a6;text-decoration:none;padding:3px 0 3px 8px;border-left:2px solid transparent;line-height:1.4;transition:color .15s,border-color .15s}
.toc a:hover{color:#2d3436;border-left-color:#b2bec3}
.toc a.toc-sub{padding-left:16px;font-size:11px}
.wrap{flex:1;min-width:0;padding:14px 20px 40px}
.spotlight{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap}
.sp-card{flex:1;min-width:200px;background:#fff;border-radius:8px;padding:10px 14px;border-left:3px solid #ccc;box-shadow:0 1px 3px rgba(0,0,0,.06);display:flex;align-items:center;gap:10px}
.sp-card.c-red{border-color:#e74c3c}.sp-card.c-orange{border-color:#e67e22}.sp-card.c-green{border-color:#27ae60}.sp-card.c-gray{border-color:#b2bec3}
.sp-label{font-size:12px;font-weight:700;color:#2d3436}
.sp-sub{font-size:11px;color:#b2bec3}
.sp-nums{margin-left:auto;display:flex;gap:12px}
.sp-num{text-align:right}
.sp-num .v{font-size:18px;font-weight:800;line-height:1}
.sp-num .l{font-size:10px;color:#b2bec3;margin-top:1px}
.v-red{color:#e74c3c}.v-orange{color:#e67e22}.v-green{color:#27ae60}.v-gray{color:#95a5a6}
.sec-hd{font-size:15px;font-weight:700;color:#2d3436;margin:24px 0 10px;padding-bottom:6px;border-bottom:2px solid #e0e0e0}
.card{background:#fff;border-radius:8px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,.06)}
details.card{background:#fff;border-radius:8px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,.06)}
details summary{user-select:none;list-style:none;display:flex;align-items:center;justify-content:space-between;padding:6px 10px 6px 28px;border-radius:6px;background:#f0f3f8;cursor:pointer;transition:background .15s;position:relative}
details summary:hover{background:#e2e8f5}
details summary::before{content:'▸';position:absolute;left:10px;top:50%;transform:translateY(-50%);color:#636e72;font-size:13px;transition:transform .15s}
details[open] summary::before{transform:translateY(-50%) rotate(90deg)}
details.card>summary{margin:-16px -16px 12px -16px;border-radius:8px 8px 0 0;padding:10px 16px}
details.card:not([open])>summary{border-radius:8px;margin-bottom:-16px}
details summary .sum-title{display:flex;align-items:center;gap:6px;flex:1;min-width:0}
details summary .sum-toggle{font-size:11px;color:#636e72;white-space:nowrap;flex-shrink:0;padding:2px 8px;border-radius:4px;border:1px solid #cbd5e1;background:#fff}
details[open] summary .sum-toggle::before{content:'收起 ▲'}
details:not([open]) summary .sum-toggle::before{content:'展开 ▼'}
h1{font-size:18px;margin:0 0 12px;color:#1a1a2e}
h2{font-size:15px;font-weight:700;color:#2d3436;margin:24px 0 10px;padding-bottom:6px;border-bottom:2px solid #e0e0e0}
h3{font-size:14px;margin:16px 0 8px;color:#636e72}
h4{font-size:13px;margin:12px 0 6px;color:#636e72}
table{width:100%;border-collapse:collapse;font-size:13px;margin:8px 0}
th,td{padding:8px 10px;text-align:left;border-bottom:1px solid #eee}
th{background:#f8f9fa;font-weight:600;color:#636e72;white-space:nowrap}
tr:hover{background:#f8f9ff}
.critical{color:#e74c3c;font-weight:700}
.green{color:#27ae60;font-weight:700}
blockquote{color:#555;border-left:4px solid #ddd;margin:8px 0;padding:4px 12px;background:#fafbfc;border-radius:0 4px 4px 0}
code{background:#f4f4f4;padding:1px 4px;border-radius:3px;font-size:0.9em}
pre{background:#f6f6f6;padding:12px;overflow-x:auto;border-radius:4px}
img{max-width:100%;height:auto}
a{color:#2471cc;text-decoration:none}
a:hover{text-decoration:underline}
p{margin:6px 0}
ul,ol{margin:6px 0;padding-left:24px}
li{margin:3px 0}
@media(max-width:960px){.toc{display:none}.spotlight{flex-direction:column}.sp-card{min-width:unset}}
@media(max-width:600px){.wrap{padding:10px 10px 24px}.hd{padding:10px 12px}}
"""


def _postprocess(html: str) -> str:
    """修复 markdown 生成 HTML 的问题。"""
    html = re.sub(r'<p>\s*</p>', '', html)
    html = re.sub(r'(<br\s*/?>\s*){2,}', '<br>', html)
    # 修复 md_in_html 内未渲染的 markdown 链接: [text](url) → <a href="url">text</a>
    html = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', html)
    return html


def _inject_step4_flames(html: str, flame_dir_abs: str, flame_dir_src: str) -> str:
    """扫 flame_dir_abs 下 *_compare_flame.html, 把火焰图链接注入到各 SO 的详情段落中。

    策略: 对每个 SO，在其名称首次出现的 <h3>/<h4> 标题或 <li>/<p> 段落之后，
    就近插入火焰图链接。不做集中兜底列表。
    """
    so_with_flame = set()
    if flame_dir_abs and os.path.isdir(flame_dir_abs):
        for fn in os.listdir(flame_dir_abs):
            m = re.match(r'(.+)_compare_flame\.html$', fn)
            if m:
                so_with_flame.add(m.group(1))
    if not so_with_flame:
        return html

    injected = set()
    link_html = f'<a href="{flame_dir_src}/{{so}}_compare_flame.html" target="_blank" style="font-size:12px;color:#2471cc;margin-left:8px">📊 火焰图</a>'

    # 按 SO 名长度降序处理，避免短名匹配到长名的子串
    for so in sorted(so_with_flame, key=len, reverse=True):
        so_esc = re.escape(so)
        link = link_html.format(so=so)

        # 策略1: 在 <summary> 中含 SO 名的，在 </summary> 前插入链接
        heading_pat = re.compile(rf'(<summary[^>]*>(?:(?!</summary>).)*?{so_esc}.*?)(</summary>)', re.IGNORECASE | re.DOTALL)
        m = heading_pat.search(html)
        if m:
            insert_pos = m.start(2)
            html = html[:insert_pos] + link + html[insert_pos:]
            injected.add(so)
            continue

    return html


def _make_tag_id(text: str) -> str:
    """Generate HTML-safe ID from heading text (Unicode-aware).

    Keeps Unicode word characters (letters, digits, underscore),
    replaces others with hyphens, collapses runs. Prefixes 'sec-'
    if the result starts with a digit (HTML IDs must not).
    """
    tag_id = re.sub(r'[^\w]', '-', text, flags=re.UNICODE)
    tag_id = re.sub(r'-+', '-', tag_id).strip('-')
    if not tag_id:
        tag_id = 'heading'
    if tag_id[0].isdigit():
        tag_id = 'sec-' + tag_id
    return tag_id[:80]


def _build_toc(body: str) -> str:
    """从 body 的 h1/h2/h3 生成侧边栏 TOC。"""
    toc_items = []
    used_ids: set[str] = set()
    for m in re.finditer(r'<h([123])[^>]*>(.*?)</h\1>', body, re.IGNORECASE):
        level = int(m.group(1))
        text_raw = m.group(2)
        text = re.sub(r'<[^>]+>', '', text_raw).strip()
        if not text:
            continue
        id_match = re.search(r'id="([^"]+)"', m.group(0))
        tag_id = id_match.group(1) if id_match else ""
        if not tag_id:
            tag_id = _make_tag_id(text)
        # De-duplicate: append -2, -3, … if the same id was already used
        if tag_id in used_ids:
            i = 2
            while f'{tag_id}-{i}' in used_ids:
                i += 1
            tag_id = f'{tag_id}-{i}'
        used_ids.add(tag_id)
        cls = "toc-sub" if level == 3 else ""
        toc_items.append(f'<a href="#{tag_id}" class="{cls}">{text}</a>')
    if not toc_items:
        return ""
    return '<div class="toc"><div class="toc-title">目录</div>' + "".join(toc_items) + '</div>'


def _build_header(title: str, body: str) -> str:
    """构建顶部深色标题栏。"""
    # 提取总内存差值用于 pills
    total_match = re.search(r'差值\s*\**\s*\+?([\d.]+)\s*MB', body)
    total_delta = total_match.group(1) if total_match else "—"
    # 判断劣化/改善
    delta_val = float(total_delta) if total_delta != "—" else 0
    if delta_val > 100:
        pill = '<span class="pill pill-r">严重劣化</span>'
    elif delta_val > 0:
        pill = '<span class="pill pill-y">内存增长</span>'
    else:
        pill = '<span class="pill pill-g">改善</span>'
    header = (
        f'<div class="hd">'
        f'<div><div class="hd-title">内存防劣化对比报告</div>'
        f'<div class="hd-subline">{title}</div></div>'
        f'<div class="hd-meta">总内存差值: +{total_delta} MB</div>'
        f'<div class="hd-pills">{pill}</div>'
        f'</div>'
    )
    return header


def _wrap_content(body: str, title: str) -> str:
    """将 body 包装到 layout 结构中（header + TOC + wrap）。"""
    header = _build_header(title, body)
    # Assign IDs to all h1/h2/h3 first (Unicode-aware, de-duplicated),
    # then build the TOC so it can read the already-assigned IDs.
    used_ids: set[str] = set()
    def _add_id(m):
        tag = m.group(1)
        attrs = m.group(2)
        text_raw = m.group(3)
        if 'id=' in attrs:
            existing = re.search(r'id="([^"]+)"', attrs)
            if existing:
                used_ids.add(existing.group(1))
            return m.group(0)
        text = re.sub(r'<[^>]+>', '', text_raw).strip()
        tag_id = _make_tag_id(text)
        if tag_id in used_ids:
            i = 2
            while f'{tag_id}-{i}' in used_ids:
                i += 1
            tag_id = f'{tag_id}-{i}'
        used_ids.add(tag_id)
        return f'<{tag}{attrs} id="{tag_id}">{text_raw}</{tag}>'
    body = re.sub(r'<(h[123])([^>]*)>(.*?)</\1>', _add_id, body, flags=re.IGNORECASE)
    toc = _build_toc(body)
    layout = f'<div class="layout">{toc}<div class="wrap">{body}</div></div>'
    return header + layout


def convert(md_path: str, out_path: str | None = None,
            flame_dir: str = "flame_compare") -> str:
    """md → html，保留 raw HTML。返回输出路径。

    扫 flame_dir 下 *_compare_flame.html, 把步骤4前后对比火焰图链接
    注入到各 SO 的 <summary> 中（md 源文件不含链接, 仅 html 含）。
    """
    md_text = open(md_path, encoding="utf-8").read()
    body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "md_in_html", "sane_lists", "attr_list"],
    )
    body = _postprocess(body)

    md_dir = os.path.dirname(os.path.abspath(md_path))
    flame_dir_abs = flame_dir if os.path.isabs(flame_dir) else os.path.join(md_dir, flame_dir)
    body = _inject_step4_flames(body, flame_dir_abs, flame_dir)

    title = os.path.basename(md_path)
    body = _wrap_content(body, title)
    html = (
        "<!DOCTYPE html><html lang='zh-CN'><head><meta charset='utf-8'>"
        f"<title>{title}</title><style>{CSS}</style></head>"
        f"<body>{body}"
        "<script>(function(){"
        "function openDetailsForHash(hash){"
        "if(!hash)return;"
        "var t=document.getElementById(hash);"
        "if(!t)t=document.querySelector('a[id=\"'+hash+'\"]');"
        "if(t){var d=t.closest('details');if(d&&!d.open){d.open=true;}"
        "var p=t.closest('details');while(p){if(!p.open){p.open=true;}p=p.parentElement.closest('details');}"
        "setTimeout(function(){t.scrollIntoView({behavior:'smooth',block:'start'});},50);}"
        "}"
        "if(location.hash){openDetailsForHash(location.hash.slice(1));}"
        "window.addEventListener('hashchange',function(){openDetailsForHash(location.hash.slice(1));});"
        "document.addEventListener('click',function(e){"
        "var a=e.target.closest('a[href^=\"#\"]');"
        "if(a&&a.getAttribute('href').length>1){"
        "var id=a.getAttribute('href').slice(1);"
        "setTimeout(function(){openDetailsForHash(id);},10);"
        "}"
        "},true);"
        "})();</script>"
        "</body></html>"
    )
    if out_path is None:
        out_path = os.path.splitext(md_path)[0] + ".html"
    open(out_path, "w", encoding="utf-8").write(html)
    print(f"{md_path} -> {out_path} ({len(html)} bytes)")
    return out_path


def main():
    ap = argparse.ArgumentParser(description="对比报告 md→html (扫 flame_dir 注入步骤4火焰图链接)")
    ap.add_argument("md", help="报告 .md 路径")
    ap.add_argument("-o", "--output", help="输出 .html 路径 (默认同名 .html)")
    ap.add_argument("--flame-dir", default="flame_compare", help="火焰图 HTML 目录 (相对报告, 默认 flame_compare)")
    args = ap.parse_args()
    convert(args.md, args.output, args.flame_dir)


if __name__ == "__main__":
    main()