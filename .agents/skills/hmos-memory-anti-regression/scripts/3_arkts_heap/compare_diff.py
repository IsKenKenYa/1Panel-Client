#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
compare_diff.py — 对比两份堆引用链报告,找出 RETAINED 增长/新增的引用链,**按责任侧分类显示**。

用法:
    python3 compare_diff.py A B [阈值KB] [--top N] [--html [PATH|--]] [--json [PATH]]
    # 阈值默认 0.1 KB;只收集 Δretained > 阈值 的链
    # --top N:只输出 Δretained 增量最大的前 N 条引用链(默认全量);见下方"--top N 截断"。
    # A、B 为 *.shortest-path.json(shortest-path.mjs --json 输出),两边都按"去编号链"对齐:
    #   *.shortest-path.json — shortest-path.mjs --json 直接输出(逐对象链,本脚本按签名聚合后比对)
    #   *.diff.md            — 旧格式,arkts_top5.py --diff 生成(末尾含 TSV 块);仅作向后兼容读入

HTML 输出(--html 或 --out):
    --html           生成 <B-stem>.compare.html(与 B 同目录,自包含单文件,内嵌 CSS)
    --html PATH      生成到 PATH(PATH 为 - 则 HTML 写到 stdout,并跳过文本表)
    --html=PATH      同上
    --out PATH       指定 HTML 落地路径(单独使用即生成 HTML,不必再带 --html);- = stdout
    --out=PATH       同上
    HTML 把"差异最短引用链"渲染成节点药丸流(root → … → 对象):
      GC Root 高亮、框架基础设施节点淡显、增长/新增对象按 GROWN(琥珀)/NEW(红)着色,
      Δretained 带"相对最大增量的比例条",顶部带汇总卡片。

JSON 输出(--json):
    --json           生成 <B-stem>.compare.json(与 B 同目录)
    --json=PATH      生成到 PATH
    结构:{a, b, threshold_kb, summary{grown,new,total,delta_kb}, side_dist[], rows[]}
    rows每条:{delta_kb, count, seq, chain(带 .ts 行号 + 应用模块 [so] 角标的原始链), tag(GROWN/NEW), fm, side,
              so(主SO: leaf向root首个业务节点所属SO/HAP), so_category(应用自身模块/系统框架/ArkTS运行时/...)}
    ——chain 里**仅应用自身模块**节点名末尾带 [so] 角标(如 xxx.ts#Func(line:N)[module.hap]),
      系统 SO(VM 内部/系统框架/GC Root)不加角标;.ts 编译行号可经 resolve-lines.py + sourceMap 还原成 .ets 源码行号;
      so 由节点名派生(无显式SO字段): 应用 .ts→<module>.hap, 框架 .js→子系统SO(映射表), VM内部→libark_jsruntime.so

--top N 截断(只看增量最大的前 N 条):
    --top N / --top=N  只在文本表 / HTML 主体 / JSON rows[] / 责任侧分布里**展示** Δ 降序的前 N 条。
    汇总卡片(增长/新增/合计条数、Δretained 总增量)仍按**全量(超过阈值的全部链)**统计——
    即"问题总规模"照实给出,只是被展示的引用链截到前 N;并用提示行 "(仅展示前 N / 共 M 条,已截断 M−N 条)" 桥接。
    JSON 另在顶层加 {top:N, truncated:被丢条数},rows[] 仍为截断后的前 N。

逻辑:
    - 加载每份报告:*.shortest-path.json 读对象数组,names 反转成 root→leaf 链,分两份口径——
      ① **去编号键(key)**:抹掉一切行号/序号((line:N)、[N]、[File:N] 里的 :N),**只用于 join**,
         与"是否带 sourcemap""版本间行号偏移"无关,键稳定;② **原始链(raw)**:保留行号、只抹 [N]
         噪声,并在**应用自身模块**节点名末尾追加 [so] 角标(annotate_node_so),**用于差异输出展示**(便于按行号定位源码、
          且链上直接携带应用模块归属信息;系统 SO 不加角标,保持简洁)。按 key 聚合(retained 求和、count 累加——
         dominator-retained 对不同对象非重叠,求和即该持有模式真实占用,不重复计);*.diff.md 读末尾
         TSV 块(chain / retained_kb / count / 序号 [/ 责任侧] / [根类型],已聚类,后两列可选,用于 HTML 着色)。
    - 以"去编号键"join A、B(**行号不参与比对**)。
    - 两边都有:Δretained = B.retained - A.retained。
    - 仅 B 有(新链):Δretained = B.retained。
    - 收集 Δretained > 阈值 的,按 Δ 降序输出(引用链列展示 B 的**原始链,带行号 + 应用模块 [so] 角标**):
        Δretained | count(B) | 序号 | 引用链(原始,带行号+应用模块[so]) | [GROWN/NEW]
    - "序号"是 JSON 对象 rank(首见代表)[#x];引用链已带行号,可直接据此定位。

注:比对只看去编号键(行号无关)——版本间某方法挪了行,键不变,不会被误报为 NEW/消失。
   但 A、B 仍需用相同的 sourcemap 开关(都带或都不带):开/关使命名格式不同,即便去了行号也对不齐。
   差异输出里的引用链是原始链(带行号 + 应用模块 [so] 角标),方便定位。
"""
import bisect
import json
import os
import re
import sys
from pathlib import Path

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402


def parse_tsv(path):
    """读 diff.md 末尾 TSV-BEGIN/END 之间的行,返回 {chain: {ret, count, bianhao, side, rtype}}。

    列顺序: chain / retained_kb / count / 序号 / [责任侧] / [根类型],后两列可选。"""
    chains = {}
    in_tsv = False
    with open(path, encoding='utf-8') as f:
        for line in f:
            s = line.rstrip('\n')
            if 'TSV-BEGIN' in s:
                in_tsv = True
                continue
            if 'TSV-END' in s:
                break
            if not in_tsv:
                continue
            parts = s.split('\t')
            if len(parts) < 4:
                continue
            chain, ret, cnt, bianhao = parts[0], parts[1], parts[2], parts[3]
            side = parts[4].strip() if len(parts) > 4 else ''
            rtype = parts[5].strip() if len(parts) > 5 else ''
            try:
                chains[chain] = {'ret': float(ret), 'count': int(cnt), 'bianhao': bianhao,
                                 'side': side, 'rtype': rtype}
            except ValueError:
                pass
    return chains


# ─────────────────────── shortest-path.json 直读 ───────────────────────
# 链分两份口径:
#   • key(去编号链,做 join):抹掉一切行号/序号——(line:N)、纯数字 [N]、以及 [File:N]
#     里的 :N。这样键与"是否带 sourcemap""版本间行号偏移"都无关,比对稳定。
#   • raw(原始链,做展示):保留行号((line:N) / [File:N]),只抹纯数字 [N] 噪声索引,
#     便于按行号定位源码。
def _strip_index(s):
    """raw 用:只抹纯数字 [N] 索引,保留行号(line)。"""
    return re.sub(r'\[\d+\]', '', s or '').strip() or '(anon)'


def _key_strip(s):
    """key 用:抹掉所有行号/序号信息,得到稳定的去编号链。"""
    s = re.sub(r'\(line:\d+\)', '', s or '')
    s = re.sub(r'\[\d+\]', '', s)
    s = re.sub(r':\d+', '', s)          # 抹掉 [File:N] 里的行号
    return s.strip() or '(anon)'


_SO_TAG_RE = re.compile(r'\[[^\[\]]*\.(?:so|hap)\]$')


def _strip_so_tag(s):
    """去掉节点名末尾的 [so] 角标(annotate_node_so 添加的 [xx.so]/[xx.hap]),
    还原纯节点名——用于 HTML 渲染(HTML 已有 so badge,避免重复)。"""
    return _SO_TAG_RE.sub('', s or '').strip() or s or ''


def _root_kind(name):
    """返回 (根类型, 责任侧),对齐 shortest_path_to_diff.py / fault-modes。"""
    if not name:
        return 'Unknown', '待确认'
    if re.search(r'(GlobalEnv|global_env|SourceText|Source_Text|GlobalObject|VMRoot)', name):
        return 'VMRoot', 'ArkTS'
    if re.search(r'(Handle|napi_ref|Reference)', name):
        return 'GlobalHandleRoot', 'Native'
    if 'LocalHandle' in name:
        return 'LocalHandleRoot', 'Native'
    if 'Frame' in name:
        return 'FrameRoot', 'ArkTS'
    return 'Unknown', '待确认'


# ─────────────────────── 责任侧 / 故障模式分类(对齐 hmos-jsleak-analysis fault-modes)───────────────
# 按引用链 GC Root 端(distance≈1)节点名识别故障模式与责任侧:
#   SourceTextModule / Source_Text_Module_Record / global_env / GlobalEnv / GlobalObject / VMRoot → ROOT_VM             · ArkTS
#   Frame / StackFrame                                                                              → ROOT_FRAME          · ArkTS
#   LocalHandle                                                                                     → ROOT_LOCAL_HANDLE   · Native
#   GlobalHandle / Reference / napi_ref / Handle                                                    → ROOT_GLOBAL_HANDLE  · Native
#   其余                                                                                            → Unknown             · 待确认
# 匹配规则(同 fault-modes):优先看 GC Root 端节点;不足则沿链向 root 方向逐节点找特征,首命中即定。
_FAULT_RULES = (
    (re.compile(r'(SourceTextModule|Source_Text_Module_Record|global_env|GlobalEnv|GlobalObject|VMRoot)'), 'ROOT_VM', 'ArkTS'),
    (re.compile(r'(StackFrame|Frame)'), 'ROOT_FRAME', 'ArkTS'),
    (re.compile(r'LocalHandle'), 'ROOT_LOCAL_HANDLE', 'Native'),
    (re.compile(r'(GlobalHandle|napi_ref|Reference|Handle)'), 'ROOT_GLOBAL_HANDLE', 'Native'),
)

# 责任侧展示顺序 + 标题/说明
SIDE_ORDER = (
    ('ArkTS', 'ArkTS', 'VM / 帧栈侧 — 由虚拟机内部 root(GlobalEnv / SourceTextModule / Frame)持有'),
    ('Native', 'Native', 'napi / C++ 句柄侧 — 由 LocalHandle / GlobalHandle / napi_ref 持有'),
    ('待确认', '待确认', '根类型未命中关键字 — 需人工确认(常因当前快照未打 ROOT 标签)'),
)


# ─────────────────────── 节点 → SO/HAP 归因 ───────────────────────
# 引用链节点名编码了归属信息(无显式 SO 字段),据此派生每个节点/每条链来自哪个 SO:
#   A 应用自身 ArkTS: <bundle>/<module>@<ver>/<path>.ts#Class(line:N)[refmod] → <module>.hap
#   B 框架 .js:       _GLOBAL <build_path>/<file>.js#Func(line:N)            → 子系统→SO 映射表
#   C VM 内部结构:    ArkInternal*/JSArray/JSObject/PropertyBox/LexicalEnv/   → libark_jsruntime.so
#                     HiddenClass/Method/GlobalEnv/GlobalObject/...
#   D GC Root 句柄:   GlobalHandleRoot/LocalHandleRoot/VMRoot/FrameRoot       → libark_jsruntime.so
_VM_INTERNAL_RE = re.compile(
    r'^(ArkInternal|JSArray|JSObject|JSFunction|JSNativePointer|JSWrappedNapiObject|JSSharedObject|'
    r'PropertyBox|LexicalEnv|HomeObject|FunctionExtraInfo|ProtoOrHClass|'
    r'HiddenClass|ProfileTypeInfo|TransWithProtoHandler|'
    r'Method|SourceTextModule|GlobalEnv|GlobalObject|VMRoot|'
    r'closure|Prototype|__proto__|'
    r'ImportEntry|ResolvedIndexBinding|ClassLiteral|ArkInternalFunctionTemplate|ExportEntry)')
_GC_ROOT_RE = re.compile(r'^(GlobalHandleRoot|LocalHandleRoot|VMRoot|FrameRoot)')
_APP_OBJ_RE = re.compile(r'/([\w\-]+)@[\d.]+/.*\.ts#')
_FRAMEWORK_JS_RE = re.compile(r'\.js#\w+\(line:\d+\)')
# 子系统(build 路径关键词)→ 系统 SO 映射表(可扩展;未命中标"未映射",不臆测)
_SUBSYSTEM_SO_MAP = (
    (re.compile(r'ace_engine|arkui|declarative_frontend|ark_component|ark_theme|arksearch'), 'libace_compatible.z.so', '系统框架'),
    (re.compile(r'js_runtime|ecmascript|panda'), 'libark_jsruntime.so', '系统框架'),
)


def classify_so(name):
    """节点名 → (so, category)。SO 信息编码在节点名字符串中(无显式字段),需派生。"""
    if not name:
        return '未映射', '未映射（需补充）'
    # A 应用自身 ArkTS(开发者代码): <bundle>/<module>@<ver>/.../*.ts#Class(line)[refmod]
    m = _APP_OBJ_RE.search(name)
    if m:
        return f'{m.group(1)}.hap', '应用自身模块'
    # B 框架 .js: _GLOBAL <build_path>/<file>.js#Func(line:N)
    if _FRAMEWORK_JS_RE.search(name):
        for rx, so, cat in _SUBSYSTEM_SO_MAP:
            if rx.search(name):
                return so, cat
        return '未映射', '系统框架（未映射,需补充）'
    # D GC Root 句柄(先于 C,因 VMRoot 同时命中两者)
    if _GC_ROOT_RE.search(name):
        return 'libark_jsruntime.so', 'ArkTS 运行时(GC Root)'
    # C VM 内部结构
    if _VM_INTERNAL_RE.search(name):
        return 'libark_jsruntime.so', 'ArkTS 运行时'
    return '未映射', '未映射（需补充）'


def chain_primary_so(names_reversed):
    """root→leaf 链 → (主SO, 类别)。从 leaf 向 root 走,跳过 VM 内部/GC Root 管道节点,
    返回首个业务节点(应用/框架)的 SO;全为管道则回退 leaf 的 SO。"""
    for nm in reversed(names_reversed):  # leaf → root
        so, cat = classify_so(nm)
        if cat in ('应用自身模块', '系统框架'):
            return so, cat
    if names_reversed:
        return classify_so(names_reversed[-1])
    return '未映射', '未映射（需补充）'


def annotate_node_so(nm):
    """在节点名末尾追加 [so] 角标(如 xxx.ts#Func(line:N)[module.hap]),
    使引用链文本直接携带 SO 归属信息。**仅对应用自身模块节点追加**——
    系统 SO(VM 内部/系统框架/GC Root 等)不加角标,保持链文本简洁。"""
    so, so_cat = classify_so(nm)
    if so_cat != '应用自身模块':
        return nm
    return f'{nm}[{so}]'


def classify_chain(chain):
    """按引用链 root 端节点名判 (故障模式, 责任侧)。chain 形如 'root → … → leaf'。"""
    for nm in (p.strip() for p in chain.split(' → ')):
        if not nm:
            continue
        for rx, fm, side in _FAULT_RULES:
            if rx.search(nm):
                return fm, side
    return 'Unknown', '待确认'


def parse_shortest_json(path):
    """读 shortest-path.mjs --json 的数组,返回 {去编号键: {ret, count, bianhao, side, rtype, raw}}。
    键(_key_strip,抹掉所有行号/序号)用于 join;raw(_strip_index,保留行号)用于展示。

    shortest-path.mjs 输出的是**逐对象**链(每个可达对象一条),而同一条"去编号键"常被
    多个对象共享(同一持有路径下的同类实例)。这里**按键聚合**:retained 求和、count 累加——
    dominator-retained size 对不同对象是非重叠的(dom tree 每节点唯一 idom),所以求和即该
    持有模式真正占用的内存,不会重复计数。raw 取首见对象(JSON 按 rank 排序,首见即最大 retained)。"""
    try:
        data = json.load(open(path, encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as e:
        sys.exit(f'错误:无法解析 JSON {path}({e})。\n'
                 '  compare_diff.py 接受 *.shortest-path.json 或 *.diff.md(含 TSV 块);\n'
                 '  若这是 .diff.md,请保留 .md 扩展名。')
    if isinstance(data, dict) and 'snapshot' in data:
        sys.exit(f'错误:{path} 是原始 heapsnapshot。请先跑:\n'
                 '    shortest-path.mjs <file>.heapsnapshot --json   # → *.shortest-path.json\n'
                 '  再用 compare_diff.py 对比。')
    if not isinstance(data, list):
        sys.exit(f'错误:{path} 应为 shortest-path.mjs --json 输出的 JSON 数组,'
                 f'实际顶层是 {type(data).__name__}。')

    chains = {}
    for obj in data:
        if not isinstance(obj, dict):
            continue
        names = obj.get('names') or []
        if names:
            rev = list(reversed(names))                         # root → … → leaf
            key = ' → '.join(_key_strip(n) for n in rev)         # 去编号键(无行号,做 join)
            raw = ' → '.join(annotate_node_so(_strip_index(n)) for n in rev)  # 原始链(带行号+SO角标,做展示)
            so, so_cat = chain_primary_so(rev)                   # 主 SO(leaf向root首个业务节点)
        else:
            nm0 = obj.get('name', '(anon)')
            key = _key_strip(nm0)
            raw = annotate_node_so(_strip_index(nm0))
            so, so_cat = classify_so(nm0)
        key = key.replace('\t', ' ')
        raw = raw.replace('\t', ' ')
        rtype, side = _root_kind(obj.get('rootName') or obj.get('name') or '')
        # shortest-path.mjs 的 --json 输出用 `size`(字节，含 --aggregate 聚簇求和)；
        # 旧版/其他来源可能用 `retainedSize`，两者兼容读取。
        ret_bytes = obj.get('size') if obj.get('size') is not None else obj.get('retainedSize')
        ret = (ret_bytes or 0) / 1024.0
        cnt = int(obj.get('count', 1) or 1)
        e = chains.get(key)
        if e is None:
            # 首次见该键:记代表(rank/责任侧/raw/主SO 取首见对象;JSON 按 rank 排序,首见即最大 retained)
            chains[key] = {'ret': ret, 'count': cnt,
                           'bianhao': f"[#{obj.get('rank', '?')}]",
                           'side': obj.get('side') or side,
                           'rtype': obj.get('rootType') or rtype,
                           'raw': raw,
                           'so': so, 'so_category': so_cat}
        else:
            # 同键多对象:retained 求和、count 累加(非重叠 dominator-retained,可加)
            e['ret'] += ret
            e['count'] += cnt
    return chains



def load_chains(path):
    """按扩展名分发:*.json → shortest-path JSON;其余 → diff.md 的 TSV 块。
    若 TSV 解析为空且文件里根本没有 TSV 块,给出明确报错(而非静默 0 条)。"""
    if path.lower().endswith('.json'):
        return parse_shortest_json(path)
    chains = parse_tsv(path)
    if not chains:
        try:
            txt = open(path, encoding='utf-8').read()
        except OSError:
            txt = ''
        if txt and 'TSV-BEGIN' not in txt:
            sys.exit(f'错误:{path} 中未找到 TSV 块(TSV-BEGIN…TSV-END),也没有把它当 JSON 解析。\n'
                     '  compare_diff.py 接受两种输入:\n'
                     '    1) arkts_top5.py --diff 或 shortest_path_to_diff.py 生成的 *.diff.md(末尾含 TSV 块);\n'
                     '    2) shortest-path.mjs --json 生成的 *.shortest-path.json(本脚本可直接读)。\n'
                     f'  该文件既非 .json、又无 TSV 块。若是 *.shortest-path.json 请改用 .json 扩展名;'
                     f'若是原始 *.heapsnapshot 请先跑 shortest-path.mjs --json 或 arkts_top5.py --diff。')
    return chains


# ─────────────────────── HTML 输出 ───────────────────────
# 框架基础设施节点(VM 内部 / 字典 / 原型等),渲染时淡显,让业务节点更突出。
_PLUMBING_RE = re.compile(
    r'(GlobalEnv|global_env|global env|SourceText|Source_Text|GlobalObject|VMRoot|'
    r'ArkInternal|InternalDict|\(object properties\)|\(object elements\)|'
    r'\(closure\)|^closure$|Prototype|__proto__|hidden class|'
    r'Object prototype|Array prototype|SourceTextModule|ArkInternalArray)',
    re.IGNORECASE)

_HTML_CSS = """
*{box-sizing:border-box}
:root{
  --bg:#0b0f14; --panel:#141b24; --panel2:#1c2530; --border:#283542; --border2:#3a4a5e;
  --text:#e6edf3; --muted:#9aa7b5; --faint:#61718a;
  --root:#10b981; --grown:#f5a524; --new:#f43f5e; --accent:#60a5fa;
  --arr:#46586c; --shadow:0 1px 2px rgba(0,0,0,.35);
}
html,body{margin:0;padding:0}
body{
  background:linear-gradient(180deg,#0b0f14 0%,#0d1218 100%);
  color:var(--text);
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",Roboto,Helvetica,Arial,sans-serif;
  font-size:14px;line-height:1.5;padding:24px 16px 72px;-webkit-font-smoothing:antialiased;
}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,"Liberation Mono",monospace}
.report-head{max-width:1200px;margin:0 auto 20px;padding:20px 22px;background:var(--panel);
  border:1px solid var(--border);border-radius:14px;box-shadow:var(--shadow)}
.report-head h1{margin:0 0 12px;font-size:20px;font-weight:650;letter-spacing:.3px}
.kw{color:var(--accent)}
.meta{display:flex;flex-wrap:wrap;align-items:center;gap:8px;font-size:12.5px;color:var(--muted)}
.meta .file{display:inline-flex;align-items:center}
.meta .file b{display:inline-block;width:18px;height:18px;line-height:18px;text-align:center;
  border-radius:5px;font-size:11px;margin-right:6px;background:#334155;color:#cbd6e2;font-weight:700}
.meta .file.a b{background:#334155}
.meta .file.b b{background:#423352}
.meta .vs{color:var(--arr);font-weight:700;padding:0 2px}
.meta-sub{margin-top:8px;color:var(--faint);font-size:12px}
.summary{display:flex;flex-wrap:wrap;gap:10px;margin-top:14px}
.stat{flex:1 1 120px;min-width:110px;background:var(--panel2);border:1px solid var(--border);
  border-radius:10px;padding:10px 12px}
.stat .num{display:block;font-size:20px;font-weight:700}
.stat .lab{display:block;font-size:11.5px;color:var(--muted);margin-top:2px}
.stat.grown{border-color:rgba(245,165,36,.4)} .stat.grown .num{color:var(--grown)}
.stat.new{border-color:rgba(244,63,94,.4)} .stat.new .num{color:var(--new)}
.stat.total .num{color:var(--accent)}
.legend{display:flex;flex-wrap:wrap;gap:14px;margin-top:14px;padding-top:12px;
  border-top:1px dashed var(--border);font-size:11.5px;color:var(--muted)}
.lg{display:inline-flex;align-items:center;gap:6px}
.dot{width:10px;height:10px;border-radius:3px;display:inline-block}
.dot.root{background:var(--root)} .dot.plumb{background:var(--faint)} .dot.leaf{background:var(--accent)}
.dot.grown{background:var(--grown)} .dot.new{background:var(--new)}
.rows{max-width:1200px;margin:0 auto;display:flex;flex-direction:column;gap:10px}
.row{display:flex;gap:16px;align-items:flex-start;background:var(--panel);border:1px solid var(--border);
  border-left-width:4px;border-radius:12px;padding:13px 16px;box-shadow:var(--shadow);transition:border-color .15s}
.row:hover{border-color:var(--border2)}
.row.grown{border-left-color:var(--grown)}
.row.new{border-left-color:var(--new)}
.row-left{flex:0 0 172px;display:flex;flex-direction:column;gap:6px}
.delta{font-size:18px;font-weight:700;letter-spacing:.2px}
.delta .unit{font-size:12px;color:var(--muted);font-weight:500}
.row.grown .delta{color:var(--grown)}
.row.new .delta{color:var(--new)}
.bar{height:5px;background:var(--panel2);border-radius:3px;overflow:hidden}
.bar span{display:block;height:100%;border-radius:3px}
.row.grown .bar span{background:linear-gradient(90deg,var(--grown),#f8c66a)}
.row.new .bar span{background:linear-gradient(90deg,var(--new),#ff7a90)}
.meta-line{display:flex;align-items:center;gap:6px;flex-wrap:wrap;font-size:11.5px;color:var(--muted)}
.tag{font-size:10.5px;font-weight:700;letter-spacing:.5px;padding:2px 7px;border-radius:5px;text-transform:uppercase}
.tag.grown{background:rgba(245,165,36,.15);color:var(--grown)}
.tag.new{background:rgba(244,63,94,.15);color:var(--new)}
.seq{color:var(--faint)}
.count{color:var(--muted)}
.side{font-size:10.5px;font-weight:600;padding:1px 6px;border-radius:4px;border:1px solid var(--border)}
.side.ArkTS{color:var(--accent);border-color:rgba(96,165,250,.4)}
.side.Native{color:#c084fc;border-color:rgba(192,132,252,.4)}
.side{color:var(--faint)}
.rtype{font-size:10.5px;color:var(--faint)}
.node .so{font-style:normal;font-size:9px;font-weight:700;letter-spacing:.3px;padding:1px 5px;
  border-radius:3px;background:rgba(96,165,250,.16);color:#7db4f5;margin-left:5px;white-space:nowrap}
.node.plumbing .so{display:none}
.so-main{font-size:11px;color:#7db4f5;background:rgba(96,165,250,.1);padding:2px 7px;border-radius:5px;
  border:1px solid rgba(96,165,250,.25)}
.sidedist{display:flex;flex-wrap:wrap;gap:10px;margin-top:14px}
.sd{display:inline-flex;align-items:center;gap:6px;font-size:12px;color:var(--muted);
  padding:6px 11px;border-radius:8px;border:1px solid var(--border);background:var(--panel2)}
.sd b{color:var(--text);font-weight:650}
.sd .dot{width:9px;height:9px;border-radius:50%}
.sd.arkts .dot{background:var(--accent)} .sd.arkts b{color:var(--accent)}
.sd.native .dot{background:#c084fc} .sd.native b{color:#c084fc}
.sd.unknown .dot{background:var(--faint)}
.group{display:flex;flex-direction:column;gap:10px;margin-top:18px}
.group:first-of-type{margin-top:0}
.group-head{display:flex;flex-wrap:wrap;align-items:baseline;gap:8px 12px;padding:11px 15px;
  border-radius:10px;border:1px solid var(--border);background:var(--panel2);border-left-width:4px}
.group[data-side="ArkTS"] .group-head{border-left-color:var(--accent)}
.group[data-side="Native"] .group-head{border-left-color:#c084fc}
.group[data-side="待确认"] .group-head{border-left-color:var(--faint)}
.group-head .gname{font-size:15px;font-weight:700}
.group-head .gname.arkts{color:var(--accent)} .group-head .gname.native{color:#c084fc}
.group-head .gdesc{font-size:11.5px;color:var(--muted);flex:1 1 220px}
.group-head .gstat{font-size:12px;color:var(--muted)}
.group-head .gstat b{color:var(--text);font-weight:650}
.group-head .gfm{font-size:11px;color:var(--faint)}
.fm{font-size:10px;font-weight:700;letter-spacing:.4px;padding:2px 6px;border-radius:4px;
  background:rgba(255,255,255,.06);color:var(--muted);white-space:nowrap}
.fm.ROOT_VM,.fm.ROOT_FRAME{color:var(--accent);background:rgba(96,165,250,.13)}
.fm.ROOT_LOCAL_HANDLE,.fm.ROOT_GLOBAL_HANDLE{color:#c084fc;background:rgba(192,132,252,.13)}
.chain{flex:1 1 auto;display:flex;flex-wrap:wrap;align-items:center;gap:6px 4px;padding-top:2px}
.arr{color:var(--arr);font-size:13px;font-weight:600;padding:0 1px;user-select:none}
.node{display:inline-flex;align-items:center;gap:5px;padding:4px 9px;border-radius:7px;
  border:1px solid var(--border);background:var(--panel2);font-size:12.5px;color:var(--text)}
.node .role{font-style:normal;font-size:9px;font-weight:700;letter-spacing:.5px;
  padding:1px 4px;border-radius:3px;background:rgba(255,255,255,.08);color:var(--muted)}
.node.root{border-color:rgba(16,185,129,.5);color:#5eead4;background:rgba(16,185,129,.08)}
.node.root .role{background:rgba(16,185,129,.2);color:#5eead4}
.node.plumbing{color:var(--faint);background:transparent;border-style:dashed;border-color:var(--border);font-size:11.5px}
.node.leaf{font-weight:650}
.node.leaf.grown{border-color:var(--grown);color:#ffd27a;background:rgba(245,165,36,.14)}
.node.leaf.grown .role{background:rgba(245,165,36,.22);color:#ffd27a}
.node.leaf.new{border-color:var(--new);color:#ffb3c1;background:rgba(244,63,94,.14)}
.node.leaf.new .role{background:rgba(244,63,94,.22);color:#ffb3c1}
.empty{color:var(--faint);padding:24px;text-align:center}
@media(max-width:680px){
  .row{flex-direction:column}
  .row-left{flex:1 1 auto;width:100%;flex-direction:row;flex-wrap:wrap;align-items:center;gap:8px}
  .delta{font-size:16px}
}
"""


def _esc(s):
    return (s or '').replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def _render_chain(chain, tag_lower):
    """把 'root → … → 对象' 渲染成节点药丸流 HTML。业务节点带 SO 角标,VM 管道节点淡显无角标。"""
    parts = chain.split(' → ')
    last = len(parts) - 1
    out = []
    for i, nm in enumerate(parts):
        clean_nm = _strip_so_tag(nm)  # 去掉 [so] 角标,HTML 已有 so badge,避免重复
        is_root = (i == 0)
        is_leaf = (i == last)
        cls = ['node']
        role = ''
        so_badge = ''
        if is_root:
            cls.append('root')
            role = '<i class="role">GC ROOT</i>'
        so, so_cat = classify_so(clean_nm)
        is_business = so_cat in ('应用自身模块', '系统框架', '系统框架（未映射,需补充）')
        if is_leaf:
            cls += ['leaf', tag_lower]
            role = '<i class="role">对象</i>'
            if is_business:
                so_badge = f'<i class="so">{_esc(so)}</i>'
        elif not is_root:
            if _PLUMBING_RE.search(clean_nm) and not is_business:
                cls.append('plumbing')
            if is_business:
                so_badge = f'<i class="so">{_esc(so)}</i>'
        if i > 0:
            out.append('<span class="arr">→</span>')
        out.append(f'<span class="{" ".join(cls)}" title="{_esc(clean_nm)}">{_esc(clean_nm)}{role}{so_badge}</span>')
    return ''.join(out)


def _row_html(r, max_delta):
    tag_lower = r['tag'].lower()
    bar_pct = max(3, round(r['delta'] / max_delta * 100))
    return (
        f'<article class="row {tag_lower}">'
        f'<div class="row-left">'
        f'<div class="delta mono">+{r["delta"]:.2f} <span class="unit">KB</span></div>'
        f'<div class="bar"><span style="width:{bar_pct}%"></span></div>'
        f'<div class="meta-line"><span class="tag {tag_lower}">{r["tag"]}</span>'
        f'<span class="fm {r["fm"]}">{r["fm"]}</span></div>'
        f'<div class="meta-line"><span class="so-main" title="主SO(leaf向root首个业务节点)">归属 {_esc(r.get("so", "未映射"))}</span></div>'
        f'<div class="meta-line"><span class="count mono">×{r["count"]}</span>'
        f'<span class="seq mono">{_esc(r["bh"])}</span></div>'
        f'</div>'
        f'<div class="chain">{_render_chain(r["chain"], tag_lower)}</div>'
        f'</article>')


def _group_html(side, label, desc, rows, max_delta):
    total = sum(r['delta'] for r in rows)
    fm_cnt = {}
    for r in rows:
        fm_cnt[r['fm']] = fm_cnt.get(r['fm'], 0) + 1
    fm_line = ' · '.join(f'{k} {v}' for k, v in sorted(fm_cnt.items(), key=lambda x: -x[1]))
    cls = 'arkts' if side == 'ArkTS' else ('native' if side == 'Native' else 'unknown')
    arts = '\n'.join(_row_html(r, max_delta) for r in rows)
    return (
        f'<section class="group" data-side="{_esc(side)}">'
        f'<div class="group-head">'
        f'<span class="gname {cls}">▌ 责任侧 {label}</span>'
        f'<span class="gdesc">{desc}</span>'
        f'<span class="gstat"><b>{len(rows)}</b> 条 · Δ 合计 <b>{total:.2f}</b> KB</span>'
        f'<span class="gfm">{fm_line}</span>'
        f'</div>'
        f'{arts}'
        f'</section>')


def build_html(a_path, b_path, thresh, rows, n_grown, n_new, full_count, full_delta, truncated):
    """rows: 展示用前 N 条 list[dict] {delta,count,bh,chain,tag,fm,side},已按 Δ 降序;
    汇总卡片用 full_count/full_delta(全量 ground truth);truncated>0 表示已被 --top 截断。按责任侧分组渲染。"""
    max_delta = rows[0]['delta'] if rows else 1.0
    max_delta = max_delta if max_delta > 0 else 1.0
    a_name, b_name = os.path.basename(a_path), os.path.basename(b_path)

    groups = {s: [] for s, _, _ in SIDE_ORDER}
    for r in rows:
        groups.setdefault(r['side'], []).append(r)

    # 顶部责任侧分布概览
    sd = []
    for side, label, _ in SIDE_ORDER:
        rs = groups.get(side, [])
        if not rs:
            continue
        cls = 'arkts' if side == 'ArkTS' else ('native' if side == 'Native' else 'unknown')
        sd.append(f'<span class="sd {cls}"><i class="dot"></i>{label} <b>{len(rs)}</b>条 / '
                  f'<b>{sum(x["delta"] for x in rs):.2f}</b> KB</span>')
    sidedist = '<div class="sidedist">' + ''.join(sd) + '</div>' if sd else ''

    sections = '\n'.join(
        _group_html(side, label, desc, groups[side], max_delta)
        for side, label, desc in SIDE_ORDER if groups.get(side))
    body = sections or '<p class="empty">(无超过阈值的增长/新增链)</p>'

    return f'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>堆快照 RETAINED 增量对比 — {_esc(a_name)} → {_esc(b_name)}</title>
<style>{_HTML_CSS}</style>
</head>
<body>
<header class="report-head">
  <h1>堆快照 <span class="kw">RETAINED</span> 增量对比<span style="font-size:12.5px;font-weight:400;color:var(--muted);margin-left:8px">(按责任侧分类)</span></h1>
  <div class="meta">
    <span class="file a"><b>A</b>{_esc(a_path)}</span>
    <span class="vs">→</span>
    <span class="file b"><b>B</b>{_esc(b_path)}</span>
  </div>
  <div class="meta-sub">阈值:Δretained &gt; {_esc(f"{thresh:g}")} KB &nbsp;·&nbsp; 以"去编号引用链"为键 join,按 Δ 降序,再按 GC Root 端节点划责任侧(hmos-jsleak fault-modes){(' &nbsp;·&nbsp; 仅展示增量最大的前 ' + str(len(rows)) + ' / 共 ' + str(full_count) + ' 条,已截断 ' + str(truncated) + ' 条') if truncated else ''}</div>
  <div class="summary">
    <div class="stat grown"><span class="num mono">{n_grown}</span><span class="lab">增长 GROWN</span></div>
    <div class="stat new"><span class="num mono">{n_new}</span><span class="lab">新增 NEW</span></div>
    <div class="stat"><span class="num mono">{full_count}</span><span class="lab">合计条数</span></div>
    <div class="stat total"><span class="num mono">{full_delta:.2f} KB</span><span class="lab">Δretained 总增量</span></div>
  </div>
  {sidedist}
  <div class="legend">
    <span class="lg"><i class="dot root"></i>GC Root(链起点)</span>
    <span class="lg"><i class="dot plumb"></i>框架基础设施(淡显)</span>
    <span class="lg"><i class="dot leaf"></i>增量对象(链终点)</span>
    <span class="lg"><i class="dot grown"></i>GROWN</span>
    <span class="lg"><i class="dot new"></i>NEW</span>
    <span class="lg"><i class="dot" style="background:var(--accent)"></i>ArkTS</span>
    <span class="lg"><i class="dot" style="background:#c084fc"></i>Native</span>
  </div>
</header>
<main class="rows">
{body}
</main>
</body>
</html>
'''


def main():
    argv = sys.argv[1:]
    if not argv:
        print(__doc__); sys.exit(1)

    positionals = []
    html = False
    html_out = None
    json_out = None                       # None=不要;''=默认路径;PATH/-=指定
    top_n = None                          # None=全量;否则只展示前 top_n 条
    i = 0
    while i < len(argv):
        t = argv[i]
        if t in ('-h', '--help'):
            print(__doc__); sys.exit(0)
        elif t == '--html':
            html = True; i += 1
        elif t.startswith('--html='):
            html = True; html_out = t[len('--html='):]; i += 1
        elif t == '--json':
            json_out = ''; i += 1         # 默认路径 <B-stem>.compare.json
        elif t.startswith('--json='):
            json_out = t[len('--json='):]; i += 1
        elif t == '--out':
            if i + 1 >= len(argv):
                print('错误:--out 需指定路径(或 - 代表 stdout)'); sys.exit(1)
            html_out = argv[i + 1]; i += 2
        elif t.startswith('--out='):
            html_out = t[len('--out='):]; i += 1
        elif t == '--top':
            if i + 1 >= len(argv):
                print('错误:--top 需指定 N(正整数)'); sys.exit(1)
            top_n = argv[i + 1]; i += 2
        elif t.startswith('--top='):
            top_n = t[len('--top='):]; i += 1
        else:
            positionals.append(t); i += 1

    if len(positionals) < 2:
        print(__doc__); sys.exit(1)
    a_path, b_path = positionals[0], positionals[1]
    thresh = float(positionals[2]) if len(positionals) > 2 else 0.1

    # 校验 --top N:正整数
    if top_n is not None:
        try:
            top_n = int(top_n)
        except ValueError:
            sys.exit('错误:--top 需为 ≥1 的正整数。')
        if top_n < 1:
            sys.exit('错误:--top 需为 ≥1 的正整数。')

    a = load_chains(a_path)
    b = load_chains(b_path)

    rows = []
    n_new = n_grown = 0
    for key, bd in b.items():
        ba = a.get(key)
        delta = bd['ret'] - (ba['ret'] if ba else 0.0)
        if delta > thresh:
            if ba is None:
                tag, n_new = 'NEW', n_new + 1
            else:
                tag, n_grown = 'GROWN', n_grown + 1
            chain = bd.get('raw') or key    # 展示用原始链(带行号);join 用的是去编号 key
            fm, side = classify_chain(chain)
            rows.append({'delta': delta, 'count': bd['count'], 'bh': bd['bianhao'],
                         'chain': chain, 'tag': tag, 'fm': fm, 'side': side,
                         'so': bd.get('so', '未映射'), 'so_category': bd.get('so_category', '未映射（需补充）')})
    rows.sort(key=lambda r: -r['delta'])
    # --top N 截断:汇总卡片(ground truth)按全量统计;展示用 display_rows(前 N)
    full_count = len(rows)                       # 超过阈值的全部条数(汇总卡片用)
    full_delta = sum(r['delta'] for r in rows)   # 全量 Δretained 合计(汇总卡片用)
    truncated = 0
    display_rows = rows
    if top_n is not None and len(rows) > top_n:
        display_rows = rows[:top_n]
        truncated = len(rows) - top_n
    groups = {s: [] for s, _, _ in SIDE_ORDER}
    for r in display_rows:
        groups.setdefault(r['side'], []).append(r)

    # --out 指定了落地路径即视为要 HTML(不必再带 --html)
    want_html = html or (html_out is not None)
    html_to_stdout = want_html and (html_out == '-')

    # 文本表(HTML 写 stdout 时跳过,只输出 HTML)——按责任侧分组
    if not html_to_stdout:
        print(f"A = {a_path}")
        print(f"B = {b_path}")
        print(f"阈值: Δretained > {thresh} KB   |   增长(GROWN) {n_grown} 条, 新增(NEW) {n_new} 条, 合计 {full_count} 条")
        if truncated:
            print(f"(仅展示增量最大的前 {len(display_rows)} / 共 {full_count} 条,已截断 {truncated} 条)")
        dist = []
        for side, label, _ in SIDE_ORDER:
            rs = groups.get(side, [])
            if rs:
                dist.append(f"{label} {len(rs)}条 / Δ {sum(x['delta'] for x in rs):.2f}KB")
        if dist:
            print("责任侧分布:  " + "   |   ".join(dist))
        print()
        if not rows:
            print("(无超过阈值的增长/新增链)")
        for side, label, desc in SIDE_ORDER:
            rs = groups.get(side, [])
            if not rs:
                continue
            total = sum(x['delta'] for x in rs)
            fm_cnt = {}
            for x in rs:
                fm_cnt[x['fm']] = fm_cnt.get(x['fm'], 0) + 1
            fm_line = ", ".join(f"{k} {v}" for k, v in sorted(fm_cnt.items(), key=lambda p: -p[1]))
            bar = "═" * 78
            print(bar)
            print(f"▌ 责任侧 {label} — {desc}")
            print(f"  {len(rs)} 条,Δ 合计 {total:.2f} KB   |   故障模式: {fm_line}")
            print(bar)
            print(f"  {'Δretained':>9}  {'count':>6}  {'模式':<20}  {'序号':<12}  {'主SO':<24}  引用链")
            print("  " + "─" * 76)
            for x in rs:
                print(f"  {x['delta']:>7.2f}KB  {x['count']:>6}  {x['fm']:<20}  {x['bh']:<12}  {x.get('so','未映射'):<24}  {x['chain']}  [{x['tag']}]")
            print()

    # HTML
    if want_html:
        if html_out is None:
            d = os.path.dirname(b_path)
            stem = os.path.basename(b_path)
            stem = stem.rsplit('.', 1)[0] if '.' in stem else stem
            html_out = os.path.join(d, stem + '.compare.html') if d else (stem + '.compare.html')
        doc = build_html(a_path, b_path, thresh, display_rows, n_grown, n_new,
                         full_count, full_delta, truncated)
        if html_out == '-':
            sys.stdout.write(doc)
        else:
            with open(html_out, 'w', encoding='utf-8') as f:
                f.write(doc)
            if not html_to_stdout:
                print(f"\n📄 HTML 已生成: {html_out}")

    # JSON(供 resolve-lines.py 等下游解析;rows.chain 是带 .ts 行号 + 应用模块 [so] 角标的原始链)
    if json_out is not None:
        if json_out in ('', '-'):
            d = os.path.dirname(b_path)
            stem = os.path.basename(b_path)
            stem = stem.rsplit('.', 1)[0] if '.' in stem else stem
            json_out = os.path.join(d, stem + '.compare.json') if d else (stem + '.compare.json')
        result = {
            'a': a_path, 'b': b_path, 'threshold_kb': thresh,
            'top': top_n,                       # None=未截断(全量);否则只取前 N 条
            'truncated': truncated,             # 因 --top 被丢掉的条数(0 表示未截断)
            'summary': {'grown': n_grown, 'new': n_new, 'total': full_count,
                        'delta_kb': round(full_delta, 2)},
            'side_dist': [{'side': s, 'count': len(groups[s]),
                           'delta_kb': round(sum(x['delta'] for x in groups[s]), 2)}
                          for s, _, _ in SIDE_ORDER if groups.get(s)],
            'rows': [{'delta_kb': round(r['delta'], 4), 'count': r['count'], 'seq': r['bh'],
                      'chain': r['chain'], 'tag': r['tag'], 'fm': r['fm'], 'side': r['side'],
                      'so': r.get('so'), 'so_category': r.get('so_category')}
                     for r in display_rows],
        }
        with open(json_out, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        if not html_to_stdout:
            print(f"📄 JSON 已生成: {json_out}  (rows.chain 带 .ts 行号,可喂 resolve-lines.py + sourceMap 还原 .ets)")


if __name__ == '__main__':
    main()
