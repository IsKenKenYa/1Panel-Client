"use strict";
/**
 * resolve_chain_props.js — 对 compare.json 中**全量差分引用链**按应用模块（bundle 内模块包名）聚合 Δretained，
 * 取劣化 Top3 模块，并列出每个模块的全部相关链明细（Δ / count / tag / 链原文）。
 *
 * 背景：compare.json 的每条差分链 Δ 是该持有模式的劣增量；一个模块（如 @ohos/lottie）会出现在
 * 多条链上，把这些链的 Δ 累加即模块劣化——与总劣化 Δ 同口径、可直接对比。
 * 
 * 流程：
 *   1. 读 compare.json，跳过 SyntheticRoot 伪链
 *   2. 对每条链提取主模块：从 leaf→root 方向找首个业务节点；无业务节点的归为 VM 内部/系统框架/未映射
 *   3. 按主模块聚合：Δ 求和、count 求和、链明细收集（每条链的 Δ/count/tag/原文）
 *   4. 按聚合 Δ 降序取 Top3 模块输出
 *   5. （可选）加载 A/B 双快照，为 Top3 模块的叶子对象做NameDictionary 属性拆解定位函数/行号
 *
 * 用法:
 *   node resolve_chain_props.js <compare.json> [--no-heap] [--out PATH]
 *   node resolve_chain_props.js <compare.json> <A.heapsnapshot> <B.heapsnapshot> [--out PATH]
 *
 * 示例:
 *   node resolve_chain_props.js arkts_compare.json --out arkts_compare.chain-props.json
 *   node resolve_chain_props.js arkts_compare.json A.heapsnapshot B.heapsnapshot --out arkts_compare.chain-props.json
 *
 * 依赖: （仅双快照模式）：@memlab/heap-analysis
 */

const path = require("path");
const fs = require("fs");

// ---------------------------------------------------------------------------
// 参数解析
// ---------------------------------------------------------------------------
function parseArgs(argv) {
    const args = argv.slice(2);
    const positionals = [];
    let outPath = "";
    let noHeap = false;
    for (let i = 0; i < args.length; i++) {
        if (args[i] === "--out" || args[i] === "--json") {
            outPath = args[++i] || "";
        } else if (args[i] === "--no-heap") {
            noHeap = true;
        } else if (args[i] === "-h" || args[i] === "--help") {
            printHelp();
            process.exit(0);
        } else {
            positionals.push(args[i]);
        }
    }
    return { 
        compareJson: positionals[0] || "",
        aSnapshot: positionals[1] || "",
        bSnapshot: positionals[2] || "",
        outPath,
        noHeap,
    };
}

function printHelp() {
    console.log(`
resolve_chain_props.js — 差分链按应用模块聚合劣化 Δ, 取 Top3 模块并列出相关链明细

用法:
  node resolve_chain_props.js <compare.json> [--no-heap] [--out PATH]
  node resolve_chain_props.js <compare.json> <A.heapsnapshot> <B.heapsnapshot> [--out PATH]

参数:
  compare.json     compare_diff.py --json 输出的对比结果 JSON
  A.heapsnapshot   A（旧版）版本的 heapsnapshot 文件（可选，提供后做 NameDictionary 定位）
  B.heapsnapshot   B（新版）版本的 heapsnapshot 文件（可选）
  --no-heap        跳过 heapsnapshot 加载（仅做链级模块聚合，速度快）
  --out PATH       输出 JSON 路径（默认 <compare_stem>.chain-props.json）

输出:
  对 compare.json 的全量差分链按应用模块聚合 Δretained （跳过 SyntheticRoot），
  按聚合 Δ 降序取 Top3 模块，列出每模块的全部相关链（Δ / count / tag / 链原文）。
`);
}

// ---------------------------------------------------------------------------
// 模块提取正则
//   业务节点：举例(实际可按具体应用修改)：com.xingin.xhs_hos/<module>@<ver>/...（module 可为 scoped 包 @xhs/reds 等）
// ---------------------------------------------------------------------------
const MODULE_RE = /com\.xingin\.xhs_hos\/(@?[\w\-.]+(?:\/[\w\-.]+)*)@[\d.]+(?:-[\d.]+)?(?:-[0-9.]+)?/;

/**
 * 从链中提取主模块：leaf→root 方向首个业务节点所属模块。
 * 无业务节点（纯 VM 内部/GC Root/系统框架）返回 null，归入 "(VM 内部/系统)"。
 */
function chainPrimaryModule(chain) {
    const nodes = (chain || "").split(" → ");
    for (let i = nodes.length - 1; i >= 0; i--) {
        const m = nodes[i].match(MODULE_RE);
        if (m) return m[1];
    }
    return null;
}

// ---------------------------------------------------------------------------
// VM 内部链匹配模式（保留：标记链类别，供报告区分）
// ---------------------------------------------------------------------------
const VM_CHAIN_PATTERNS = [
    "SourceTextModule → ArkInternalArray → ImportEntry",
    "SourceTextModule → ArkInternalArray → ResolvedIndexBinding",
];

function isVMInternalChain(chain) {
    return VM_CHAIN_PATTERNS.some(p => (chain || "").includes(p));
}

// ---------------------------------------------------------------------------
// 从节点名解析函数名和行号
// 格式: com.xingin.xhs_hos/@xhs/xxx@1.0.0/.../Xxx.ts#FuncName(line:N)[module.hap]
// ---------------------------------------------------------------------------
const FUNC_LINE_RE = /([^#\[\]]+\.ts)#([\w$.]+)\(line:(\d+)\)/;

function parseFuncLine(nodeName) {
    const m = nodeName.match(FUNC_LINE_RE);
    if (!m) return null;
    return {
        sourceFile: m[1],
        funcName: m[2],
        line: parseInt(m[3], 10),
    };
}

// ---------------------------------------------------------------------------
// 从 sourceFile 全路径提取应用代码路径
//   com.xingin.xhs_hos/@xhs/basic-utils@1.0.0/.../TraceManager.ts
//   → @xhs/basic-utils/.../TraceManager.ts
// ---------------------------------------------------------------------------
function toAppCodePath(sourceFile, line) {
    if (!sourceFile) return null;
    let p = sourceFile
        .replace(/^com\.xingin\.xhs_hos\//, "")
        .replace(/@[\d.]+\//, "/");
    if (line) p += `:${line}`;
    return p;
}

// ---------------------------------------------------------------------------
// 加载 @memlab/heap-analysis（多包探测，同 shortest-path.mjs）
// ---------------------------------------------------------------------------
async function loadMemlab() {
    for (const mod of ["@memlab/heap-analysis", "@memlab/core", "memlab"]) {
        try {
            const m = await import(mod);
            const gh = m.getFullHeapFromFile || m.default?.getFullHeapFromFile;
            if (gh) return gh;
        } catch { /* 该包未装,继续试下一个 */ }
    }
    return null;
}

// ---------------------------------------------------------------------------
// 主流程
// ---------------------------------------------------------------------------
async function main() {
    const { compareJson, aSnapshot, bSnapshot, outPath, noHeap } = parseArgs(process.argv);

    if (!compareJson) {
        printHelp();
        process.exit(1);
    }
    if (!fs.existsSync(compareJson)) {
        console.error(`错误: compare.json 不存在: ${compareJson}`);
        process.exit(1);
    }
    if (!noHeap && (!aSnapshot || bSnapshot)) {
        // 未提供双快照时自动降级为 --no-heap（仅链级聚合）
        console.error("[resolve_chain_props] 未提供 A/B heapsnapshot，降级为 --no-heap 模式（仅链级模块聚合，不做 NameDictionary 定位）");
    }

    // 1. 读 compare.json，跳过 SyntheticRoot 伪链，按主模块聚合 Δ
    const compareData = JSON.parse(fs.readFileSync(compareJson, "utf-8"));
    const rows = compareData.rows || [];

    // module → { delta, count, chains: [{delta_kb, count, tag, vm_internal, chain}] }
    const moduleAgg = new Map();
    let skippedSynthetic = 0;
    for (const row of rows) {
        const chain = row.chain || "";
        if (chain.includes("Synthetic")) {
            skippedSynthetic++;
            continue;
        }
        const mod = chainPrimaryModule(chain) || "(VM 内部/系统)";
        let agg = moduleAgg.get(mod);
        if (!agg) {
            agg = { delta: 0, count: 0, chains: [] };
            moduleAgg.set(mod, agg);
            agg.delta += row.delta_kb || 0;
            agg.count += row.count || 0;
            agg.chains.push({
                delta_kb: row.delta_kb || 0,
                count: row.count || 0,
                tag: row.tag || "",
                vm_internal: isVMInternalChain(chain),
                chain,
            });
        }
        console.error(`[resolve_chain_props] 差分链总数：${rows.length} (跳过 Synthetic 伪链 ${skippedSynthetic} 条) `);
        console.error(`[resolve_chain_props] 模块聚合：${moduleAgg.size} 个模块/分组`);

        // 2. 按聚合 Δ 降序：Top3 业务模块 + (VM 内部/系统) 单独参考
        //    （(VM 内部/系统) 是"无业务模块节点"的兜底分组，并非真正业务模块，不占 Top3 名额）
        const VM_GROUP = "(VM 内部/系统)";
        const allRanked = [...moduleAgg,entries()]
            .map(([modName, agg]) => ({ modName, ...agg }))
            .sort((x, y) => y.delta - x.delta);
        
        const vmGroup = allRanked.find(m => m.modName === VM_GROUP) || null;
        const businessModules = allRanked.filter(m => m.modName !== VM_GROUP).slice(0, 3);

        // 3. (可选) 加载 A/B 双快照，为 Top3 业务模块的叶子对象做定位
        let top3WithProps = null;
        if (!noHeap && aSnapshot && bSnapshot && fs.existsSync(aSnapshot) && fs.existsSync(bSnapshot)) {
            top3WithProps = await enrichTop3WithProps(businessModules, aSnapshot, bSnapshot);
        }

        const top3 = businessModules.map((m, idx) => {
            const props = top3WithProps ? top3WithProps[idx] : null;
            return {
                rank: idx + 1,
                module: m.module,
                module_delta_kb: Math.round(m.delta * 100) / 100,
                module_count: m.count,
                chain_count: m.chain.length,
                // 相关链明细（按 Δ 降序）
                chain: [...m.chains].sort((a, b) => b.delta_kb - a.delta_kb),
                // 定位信息（双快照模式才有）
                location: props || null,
            };
        })
    }

    // (VM 内部/系统) 参考分组（不算入 Top3）
    const vmRef = vmGroup ? {
        module: VM_GROUP,
        module_delta_kb: Math.round(vmGroup.delta * 100) / 100,
        module_count: vmGroup.count,
        chain_count: vmGroup.chains.length,
        chains: [...vmGroup.chains].sort((a, b) => b.delta_kb - a.delta_kb),
    } : null;

    // 4. 构建输出
    const result = {
        compare_json: path.resolve(compareJson),
        total_chain_delta_kb: Math.round((compareData.summary?.delta_kb ?? 0) * 100) / 100,
        total_chains: compareData.summary?.total ?? rows.length,
        skipped_synthetic: skippedSynthetic,
        top3,
        vm_internal: vmRef,
    };
    if (aSnapshot) result.heapsnapshot_a = path.resolve(aSnapshot);
    if (bSnapshot) result.heapsnapshot_b = path.resolve(bSnapshot);

    // 5. 输出 JSON
    const outPathFinal = outPath || compareJson.replace(/\.json$/, ".chain-props.json");
    fs.writeFileSync(outPathFinal, JSON.stringify(result, null, 2), "utf-8");
    console.error(`[resolve_chain_props] JSON 已保存：${outPathFinal}`);

    // 6. stdout 摘要
    console.log(`\nTop3 业务模块（按全量差分链 Δretained 聚合降序，共 ${moduleAgg.size} 个模块/分组）：\n`);
    for (const t of top3) {
        console.log(`  #${t.rank} ${t.module}`);
        console.log(`     模块劣化 Δ：${t.module_delta_kb} KB (${t.chain_count} 条相关链，count=${t.module_count})`);
        console.log(`     相关链明细：`);
        for (const c of t.chains) {
            const loc = c.vm_internal ? "[VM内部链]" : "";
            console.log(`     +${c,delta_kb.toFixed(2)} KB ×${c.count} ${c.tag}${loc} ${c.chain.slice(0, 180)}`);
        }
        if (t.location) {
            const L = t.location;
            console.log(`      定位：${L.app_code_path || "-"}(${L.lookup_method})`);
        }
        console.log();
    }
    if (vmRef) {
        console.log(`  参考（非业务模块，不占 Top3）：${vmRef.module}`);
        console.log(`     Δ: ${vmRef.module_delta_kb} KB (${vmRef.chain_count} 条相关链，count=${vmRef.module_count}) - VM 形状元数据/系统框架，随开发者对象回落`);
        console.log();
    }
}

// ----------------------------------------------------------------------------
// 双快照定位：加载 A/B，为每个模块取代表叶子对象（链明细中的 Δ 最大链的叶子节点）
// 做 __proto__→constructor / name_parse 定位，并拆解该模块 SourceTextModule 的
// NameDictionary 条目（仅当链含 VM 内部 SourceTextModule 时）。
// 简化实现：直接取该模块下 Δ 最大链的叶子业务节点做 parseFuncLine 定位。
// ----------------------------------------------------------------------------
async function enrichTop3WithProps(rankedModules, aSnapshot, bSnapshot) {
    const getFullHeapFromFile = await loadMemlab();
    if (!getFullHeapFromFile) {
        console.error("[错误] 未找到 memlab。请安装: npm i @memlab/heap-analysis");
        return null;
    }
    // 仅加载 B 快照用于叶子节点名解析（定位信息来自链本身即可，无需完整加载）
    console.error(`[resolve_chain_props] 加载 B heapsnapshot: ${bSnapshot}`);
    const snapshot = await getFullHeapFromFile(bSnapshot);
    console.error("[resolve_chain_props] heapsnapshot 加载完成");

    const nodeIndex = new Map();
    snapshot.nodes.forEach(n => { if (!nodeIndex.has(n.name)) nodeIndex.set(n.name, n); });

    const results = [];
    for (const m of rankedModules) {
        // 取 Δ 最大链的叶子节点名（链末尾业务节点）
        const topChain = [...m.chain].sort((a, b) => b.delta_kb - a.delta_kb)[0];
        const nodes = topChain.chain.split(" → ");
        let leafName = null;
        for (let i = nodes.length - 1; i >= 0; i--){
            const nm = nodes[i].replace(/\[[^\]]*\]$/g, "").trim();
            if (nm && !/^(GlobalHandle|LocalHandleRoot|VMRoot|FrameRoot|SyntheticRoot)/.test(nm)) {
                leafName = nm;
                break;
            }
        }
        let parsed = null;
        let lookupMethod = "chain_leaf_name_parse";
        if (leafName) {
            parsed = parseFuncLine(leafName);
        }
        let appCodePath = null;
        if (parsed && parsed.sourceFile) {
            appCodePath = toAppCodePath(parsed.sourceFile, parsed.line);
        } else if (leafName) {
            appCodePath = leafName
        }
        result.push({
            leaf_node_name: leafName,
            function_name: parsed?.funcName || null,
            line_number: parsed?.line || null,
            source_file: parsed?.sourceFile ? parsed.sourceFile.split("/").pop() : null,
            app_code_path: appCodePath,
            lookup_method: lookupMethod,
        });
    }
    return results;
}

main().catch(e => {
    console.error(`[resolve_chain_props] Error: ${e.message}`);
    console.error(e.stack);
    process.exit(1);
});
