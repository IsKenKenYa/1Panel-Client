#!/usr/bin/env python3
"""
build_flame_summary.py — 按版本构建火焰图 HTML (链接跳转汇总)

pipeline:
  1. 对每个 *_tree.json: 用 statics/flame.template 生成 <so_name>_flame.html
     (FlameGraph.build_flame_graph(so_name) -> html_file_name)
  2. 用 statics/example.template 生成 <version>_flamegraphs.html 汇总页
     {1} 占位符填链接串

FlameGraph 类接口 (兼容已有调用模式):
  flame = FlameGraph(field_data, html_dir)   # field_data: {so_name: tree_json_path}
  html_file_name = flame.build_flame_graph(so_name)   # 生成单 SO HTML, 返回文件名
"""
import argparse
import glob
import json
import os
import re
import shutil
import sys
import time
from functools import wraps
from pathlib import Path

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

try:
    import orjson
    def _dumps(obj):
        return orjson.dumps(obj, option=orjson.OPT_SERIALIZE_NUMPY).decode()
except ImportError:
    def _dumps(obj):
        return json.dumps(obj, separators=(",", ":"), ensure_ascii=False)


def bundle(flame_graph_dir, flame_graph_name):
    """bs4 解析 HTML，把 <link rel=stylesheet> 与 <script src> 资源内联进单文件。

    资源文件须先存在于 flame_graph_dir（href/src 相对该目录解析）。
    返回 True=内联成功；False=bs4 未安装，跳过（调用方应保留拷贝的资源作回退）。
    """
    try:
        from bs4 import BeautifulSoup
    except ImportError:
        print("未安装 BeautifulSoup， 跳过火焰图内联")
        return False
    with open(os.path.join(flame_graph_dir, flame_graph_name), encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")
    for link in soup.find_all("link", rel="stylesheet"):
        href = link["href"]
        href_abs_path = os.path.normpath(os.path.join(flame_graph_dir,href))
        with open(href_abs_path, encoding="utf-8") as f_css:
            style_tag = soup.new_tag("style")
            style_tag.string = f_css.read()
            link.replace_with(style_tag)
    for script in soup.find_all("script", src=True):
        src = script["src"]
        js_abs_path = os.path.normpath(os.path.join(flame_graph_dir, src))
        with open(js_abs_path, encoding="utf-8") as f_js:
            script.string = f_js.read()
            del script["src"]
    with open(os.path.join(flame_graph_dir, flame_graph_name), "w", encoding="utf-8") as f:
        f.write(str(soup))
    return True


# ---------- 辅助 (兼容 data_to_text 调用) ----------

CIRCLE_NUMBERS = [
    "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
    "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
]


def timing_decorator(description=None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            result = func(*args, **kwargs)
            elapsed = time.time() - start
            desc = description if description else func.__name__
            print(f"功能: {desc} | 执行时间: {elapsed:.6f} 秒")
            return result
        return wrapper
    return decorator


def safe_divide(a, b):
    if not b:
        return 0
    return a / b


class StringTable:
    """字符串去重表: string -> int 索引"""
    def __init__(self):
        self._map = {}
        self._list = []
        self.intern("N/A")  # 预留 index 0

    def intern(self, s):
        if s not in self._map:
            self._map[s] = len(self._list)
            self._list.append(s)
        return self._map[s]

    def to_json(self):
        return json.dumps(dict(enumerate(self._list)),
                          separators=(",", ":"), ensure_ascii=False)

    def to_dict(self):
        return {str(k): v for k, v in enumerate(self._list)}


def split_name(name):
    """从 tree.json 的 name 拆出 (symbol_str, lib_str)"""
    if name.startswith("/") and ".so" in name:
        lib = name.rsplit("+0x", 1)[0] if "+0x" in name else name
        return name, lib
    return name, "N/A"


def shorten(name):
    """缩短用于 d3-flamegraph 标签"""
    if name.startswith("/"):
        return name.rsplit("/", 1)[-1]
    return name


def convert_node(node, st):
    """递归转 tree.json 节点 -> 短键格式 {name,value,s,l,si,ac,rc,children?}"""
    name = node.get("name", "?")
    value = int(node.get("value", 0))
    value_mb = float(node.get("value_mb", 0))
    apply_count = int(node.get("apply_count", 0))
    sym, lib = split_name(name)
    result = {
        "name": shorten(name),
        "value": value,
        "s": st.intern(sym),
        "l": st.intern(lib),
        "si": round(value_mb, 2),
        "ac": apply_count,
        "rc": 0,
    }
    children = node.get("children", [])
    if children:
        result["children"] = [convert_node(c, st) for c in children]
    return result


def count_nodes(node):
    n = 1
    for c in node.get("children", []):
        n += count_nodes(c)
    return n


class FlameGraph:
    """生成单个 SO 的火焰图 HTML (用 flame.template + .format())

    兼容调用: flame = FlameGraph(field_data, html_dir)
              html_file_name = flame.build_flame_graph(so_name)
    """

    def __init__(self, field_data, html_dir):
        """
        field_data: dict {so_name: tree_json_path}
        html_dir:   单 SO HTML 输出目录 (一般 = version_dir)
        """
        self.field_data = field_data
        self.html_dir = os.path.abspath(html_dir)

        script_dir = os.path.dirname(os.path.abspath(__file__))
        self.statics_dir = os.path.join(script_dir, "statics")
        self.template_path = os.path.join(self.statics_dir, "flame.template")

        # 相对 html_dir 到 statics 的路径 (子页 HTML 引用资源用)
        try:
            self.rel_statics = os.path.relpath(
                self.statics_dir, self.html_dir).replace(os.sep, "/")
        except ValueError:
            # 跨盘符 (Windows C: vs D:) 无法计算相对路径, 使用绝对路径
            self.rel_statics = self.statics_dir.replace(os.sep, "/")

        with open(self.template_path, "r", encoding="utf-8") as f:
            self.template = f.read()

    def build_flame_graph(self, so_name, single_file=False):
        """生成单个 SO 的火焰图 HTML, 返回文件名 (相对 html_dir)

        single_file=False (legacy): .format 注入 + _fix_asset_paths 改资源相对路径,
            产物依赖 statics/ 目录存在。
        single_file=True: _render 模板填充 + bundle 资源内联, 产物为可独立打开的单文件。
        """
        tree_json_path = self.field_data.get(so_name)
        if not tree_json_path or not os.path.exists(tree_json_path):
            print(f"  [SKIP] {so_name}: tree.json not found", file=sys.stderr)
            return None

        # 载入 tree
        with open(tree_json_path, "rb") as f:
            data = json.load(f)
        tree = data.get("tree", data) if isinstance(data, dict) else data
        if not isinstance(tree, dict) or "name" not in tree:
            print(f"  [SKIP] {so_name}: bad tree structure", file=sys.stderr)
            return None

        so_bytes = int(tree.get("value", 0))
        nodes = count_nodes(tree)
        print(f"  {so_name:40s} {so_bytes/1048576:8.2f} MB  {nodes:>8} nodes")

        # string_table + 短键转换
        st = StringTable()
        converted = convert_node(tree, st)

        html_file_name = f"{so_name}_flame.html"
        if single_file:
            return self._render(html_file_name, st.to_dict(), converted)

        # legacy: 相对路径引用 statics/ (产物需 statics/ 同在)
        string_dict_json = st.to_json()
        flame_data_json = json.dumps(
            converted, separators=(",", ":"), ensure_ascii=False)
        tpl = self._fix_asset_paths(self.template)
        html = tpl.format(string_dict=string_dict_json,
                          flame_data=flame_data_json)
        output_path = os.path.join(self.html_dir, html_file_name)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(html)
        return html_file_name

    def _render(self, flame_graph_name, string_dict, flame_data):
        """模板填充 + 资源内联 + 单文件写出 (orjson 可选, bs4 内联)。

        镜像旧 _render 流水线: 拷贝 4 个 d3 资源到 html_dir → bundle 内联 → 清理。
        bs4 缺失时 bundle 返回 False, 拷贝资源保留 (HTML 仍可用, 非单文件)。
        必须在 .format() 之后 bundle: 资源文件内容含 { } 会破坏 .format。
        """
        with open(self.template_path, encoding="utf-8") as f:
            html = f.read()
        html = html.format(string_dict=_dumps(string_dict),
                           flame_data=_dumps(flame_data))
        flame_path = os.path.join(self.html_dir, flame_graph_name)
        with open(flame_path, "w", encoding="utf-8") as f:
            f.write(html)

        resources = [
            "d3.flameGraph.min.css", "d3.v7.js",
            "d3-flamegraph.min.js", "d3-flamegraph-tooltip.min.js",
        ]
        copied = []
        for name in resources:
            src = os.path.join(self.statics_dir, name)
            dst = os.path.join(self.html_dir, name)
            if os.path.exists(src):
                shutil.copy2(src, dst)
                copied.append(dst)

        bundle_ok = bundle(self.html_dir, flame_graph_name)
        if bundle_ok:
            for p in copied:
                try:
                    os.remove(p)
                except OSError:
                    pass
        else:
            print(f"  [WARN] {flame_graph_name}: bs4 未安装, 资源未内联 (保留拷贝, 非单文件)",
                  file=sys.stderr)
        return flame_graph_name

    def build_full_flame_graph(self):
        """预留: 构建全量合并火焰图 (暂未实现)"""
        pass

    def _fix_asset_paths(self, tpl):
        """把模板里裸资源路径改成相对 html_dir 的路径"""
        r = self.rel_statics
        tpl = tpl.replace('href="d3.flameGraph.min.css"',
                          f'href="{r}/d3.flameGraph.min.css"')
        tpl = tpl.replace('href="d3-flamegraph.css"',
                          f'href="{r}/d3-flamegraph.css"')
        tpl = tpl.replace('src="d3.v7.js"', f'src="{r}/d3.v7.js"')
        tpl = tpl.replace('src="d3-flamegraph.min.js"',
                          f'src="{r}/d3-flamegraph.min.js"')
        tpl = tpl.replace('src="d3-flamegraph-tooltip.min.js"',
                          f'src="{r}/d3-flamegraph-tooltip.min.js"')
        return tpl


@timing_decorator(description="生成火焰图")
def data_to_text(data, field_data, html_dir, limit=None,
                 ratio_limit=None, size_limit=10, config_data=None,
                 single_file=False):
    """遍历 topdown 层级数据 (top→kit→so), 为每个 SO 生成火焰图并用链接引用。

    data:       topdown 分析结果, 结构:
        { top_name: {
              "size": float,            # MB
              "third_kind": {
                  (kit_id, kit_name): {
                      "size": float,     # MB
                      "ratio": float,    # 0-1
                      "so": {
                          so_name: {
                              "size": float,    # MB
                              "ratio": float,   # 0-1
                              "flame": bool,    # 是否生成火焰图
                          } } } } } }
    field_data:     {so_name: tree_json_path}
    html_dir:       单 SO HTML 输出目录
    limit:          每级最多展示 N 个
    ratio_limit:    SO 占比低于此百分比则截断 (仅 so_index>0 时)
    size_limit:     SO 内存小于此 MB 则跳过
    config_data:    配置 dict, 含 'heading' 键 (控制是否调 build_full_flame_graph)
    返回:           HTML 文本串 (h2/h3 标题 + 链接)
    """
    if config_data is None:
        config_data = {"heading": True}
    if limit is None:
        limit = len(CIRCLE_NUMBERS)
    limit = min(limit, len(CIRCLE_NUMBERS))

    flame = FlameGraph(field_data, html_dir)
    if not config_data.get("heading"):
        flame.build_full_flame_graph()

    text = []
    for top_index, (top_name, top_v) in enumerate(data.items()):
        text.append(
            f'<h2>{top_index + 1}、{top_name}，总计占用内存'
            f'{round(top_v.get("size"), 2)}MB，其中top领域为:</h2>')
        third = top_v.get("third_kind", {})
        for kit_index, (kit_name, kit_v) in enumerate(third.items()):
            if limit and kit_index >= limit:
                break
            text.append(
                f'<h3>&nbsp;&nbsp;（{kit_index + 1}） {kit_name[1]} '
                f'申请内存{round(kit_v.get("size"), 2)}MB，'
                f'占比{round(kit_v.get("ratio") * 100, 2)}%, '
                f'领域内内存占用top so依次为:</h3>')
            so_map = kit_v.get("so", {})
            for so_index, (so_name, so_v) in enumerate(so_map.items()):
                if limit and so_index >= limit:
                    break
                if so_index > 0 and ratio_limit and \
                        so_v.get("ratio") < ratio_limit / 100:
                    break
                if so_v.get("size", 0) < size_limit:
                    break
                text.append(
                    f'&nbsp;&nbsp;&nbsp;&nbsp;{CIRCLE_NUMBERS[so_index]} '
                    f'{so_name} （{round(so_v.get("size"), 2)}MB '
                    f'{round(so_v.get("ratio") * 100, 2)}%） '
                    f'--领域内占比'
                    f'{round(safe_divide(so_v.get("size"), kit_v.get("size")) * 100, 2)}%'
                    f'<br>')
                if (so_name is not None) and (so_v.get("flame") is not False):
                    html_file_name = flame.build_flame_graph(so_name, single_file=single_file)
                    if html_file_name:
                        text.append(
                            f'&nbsp;&nbsp;&nbsp;&nbsp;<a href="{html_file_name}" '
                            f'target="_blank">📊 查看 {so_name} 火焰图</a><br>')
    return ''.join(text)


def build(version_dir, output_path=None, template_path=None, statics_dir=None,
         single_file=False):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if statics_dir is None:
        statics_dir = os.path.join(script_dir, "statics")
    if template_path is None:
        template_path = os.path.join(statics_dir, "example.template")

    version_dir = os.path.abspath(version_dir)
    version_name = os.path.basename(version_dir)
    if output_path is None:
        output_path = os.path.join(
            version_dir, f"{version_name}_flamegraphs.html")
    output_path = os.path.abspath(output_path)

    # 收集 *_tree.json
    tree_files = sorted(glob.glob(os.path.join(version_dir, "*_tree.json")))
    if not tree_files:
        print(f"[WARN] {version_dir} 下未找到 *_tree.json", file=sys.stderr)
        return 1

    field_data = {}
    for tf in tree_files:
        so_name = os.path.basename(tf)[:-len("_tree.json")]
        field_data[so_name] = tf

    print(f"版本: {version_name}")
    print(f"找到 {len(field_data)} 个 SO tree.json")
    print("-" * 60)

    # Step 1: 生成每个 SO 的 _flame.html
    flame = FlameGraph(field_data, version_dir)
    link_parts = []
    total_bytes = 0
    for so_name in sorted(field_data.keys()):
        html_file_name = flame.build_flame_graph(so_name, single_file=single_file)
        if html_file_name:
            tree = json.load(open(field_data[so_name], "rb")).get("tree", {})
            so_bytes = int(tree.get("value", 0))
            total_bytes += so_bytes
            link_parts.append(
                f'<h3>{so_name} ({so_bytes/1048576:.2f} MB)</h3>\n'
                f'<p><a href="{html_file_name}" target="_blank">'
                f'📊 查看 {so_name} 火焰图</a></p>')

    print("-" * 60)
    print(f"合计: {total_bytes/1048576:.2f} MB, 生成 {len(link_parts)} 个 SO 火焰图")

    if not link_parts:
        print("[ERROR] 没有 SO 成功生成", file=sys.stderr)
        return 2

    # Step 2: 用 example.template 生成汇总页, {1} 填链接串
    with open(template_path, "r", encoding="utf-8") as f:
        summary_tpl = f.read()

    links_html = "".join(link_parts)
    summary_html = summary_tpl.format(
        version_name,   # {0} 版本名 (title + h1)
        links_html,     # {1} 火焰图链接串
    )

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(summary_html)

    out_size = os.path.getsize(output_path)
    print(f"\n汇总: {output_path}")
    print(f"HTML 大小: {out_size/1048576:.2f} MB")
    return 0


def build_compare(a_tree_path, b_tree_path, so_name, a_label, b_label,
                  output_path, statics_dir=None, single_file=True):
    """同 SO 前后对比火焰图: A/B 两版聚类树 → 单个 flame-c.template HTML (多火焰循环渲染)。

    a_tree_path/b_tree_path: 两版 *_tree.json; 任一可缺(B-only 新增 SO 时 a 传 None/不存在路径)。
    flame-c.template 占位: {0}=标题, {1}=statics 目录, {2}=soData[{name,string_table,tree},...]。
    """
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if statics_dir is None:
        statics_dir = os.path.join(script_dir, "statics")
    template_path = os.path.join(statics_dir, "flame-c.template")

    def _entry(tree_path, label):
        if not tree_path or not os.path.exists(tree_path):
            return None
        data = json.load(open(tree_path, "rb"))
        tree = data.get("tree", data) if isinstance(data, dict) else data
        if not isinstance(tree, dict) or "name" not in tree:
            return None
        st = StringTable()
        converted = convert_node(tree, st)
        return {"name": label, "string_table": st.to_dict(), "tree": converted}

    def _placeholder(label):
        return {"name": f"{label}（无 tree.json，空槽）", "string_table": {"0": "N/A"},
                "tree": {"name": "(无数据)", "value": 0, "children": []}}

    e_a = _entry(a_tree_path, a_label)
    e_b = _entry(b_tree_path, b_label)
    if e_a is None and e_b is None:
        print(f"[WARN] {so_name}: A/B tree.json 均不存在 (both missing) — 不生成，md 注明",
              file=sys.stderr)
        return None
    # 始终 2 槽(A/B)；缺失的版本用空槽占位，保留前后对比结构
    entries = [e_a or _placeholder(a_label), e_b or _placeholder(b_label)]
    empty = [lab for lab, e in [(a_label, e_a), (b_label, e_b)] if e is None]

    with open(template_path, encoding="utf-8") as f:
        html = f.read()
    # 去掉占位符注释行(含 {0}/{1}/{2}, 会被 .format 重复展开浪费体积)
    html = re.sub(r'^\s*//\s*\{0\}\s*=.*$\n', '', html, flags=re.MULTILINE)

    title = f"{so_name} 前后对比 ({a_label} vs {b_label})"
    html = html.format(title, statics_dir, _dumps(entries))

    out_dir = os.path.dirname(os.path.abspath(output_path))
    os.makedirs(out_dir, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)
    if single_file:
        bundle(out_dir, os.path.basename(output_path))
    note = f"（空槽: {','.join(empty)}）" if empty else ""
    print(f"  {so_name}: 2 槽{note} → {output_path}")
    return output_path


def main():
    ap = argparse.ArgumentParser(description="构建火焰图 HTML (单版本汇总 / 前后对比)")
    ap.add_argument("version_dir", nargs="?", help="单版本目录 (含 *_tree.json)")
    ap.add_argument("-o", "--output", help="输出 HTML 路径")
    ap.add_argument("--template", help="汇总模板 (默认 statics/example.template)")
    ap.add_argument("--statics-dir", help="静态资源目录")
    ap.add_argument("--single-file", action="store_true",
                    help="资源内联为单文件 HTML (不依赖 statics/ 目录)")
    ap.add_argument("--compare", action="store_true", help="前后对比模式 (同 SO A/B)")
    ap.add_argument("--a-tree", help="A 版 tree.json 路径")
    ap.add_argument("--b-tree", help="B 版 tree.json 路径")
    ap.add_argument("--so", help="SO 名 (标题/输出文件名)")
    ap.add_argument("--a-label", default="A", help="A 版标签")
    ap.add_argument("--b-label", default="B", help="B 版标签")
    args = ap.parse_args()

    if args.compare:
        if not args.so or not args.output or (not args.a_tree and not args.b_tree):
            print("--compare 需 --so/--output 及至少一个 --a-tree/--b-tree", file=sys.stderr)
            sys.exit(2)
        r = build_compare(args.a_tree, args.b_tree, args.so,
                          args.a_label, args.b_label, args.output,
                          args.statics_dir, args.single_file)
        sys.exit(0 if r else 1)

    if not args.version_dir:
        ap.error("version_dir 必填 (除非 --compare)")
    sys.exit(build(args.version_dir, args.output, args.template,
                   args.statics_dir, args.single_file))


if __name__ == "__main__":
    main()
