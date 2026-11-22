"use strict";
/**
 * queryNode.js —— 提取自 meminsight/dist/Index.js 这一块的逻辑
 *
 * 原始调用链:
 *   Index.js → HMemXProc(meminsight CLI) → ArkNodeProc("ark-node" 子命令)
 *
 * 本脚本去掉 commander 框架依赖, 直接复现 ArkNodeProc 的核心功能:
 *   给定 .heapsnapshot 文件 + node id, 打印该对象的基本信息和全部属性引用。
 *   依赖: @memlab/heap-analysis (@memlab/core) —— 复用项目根 node_modules 即可。
 *
 * 用法:
 *   node queryNode.js -f <heapsnapshot路径> -i <nodeId>
 *   node queryNode.js <heapsnapshot路径> <nodeId>      (位置参数, 更顺手)
 *
 * 示例:
 *   node queryNode.js ./test.heapsnapshot -i 1234
 *   node queryNode.js ./test.heapsnapshot 1234
 */

const path = require("path");
const fs = require("fs");
const { getFullHeapFromFile } = require("@memlab/heap-analysis");

// ---------------------------------------------------------------------------
// 参数解析: 兼容 -f/--file -i/--id 与位置参数两种写法
// ---------------------------------------------------------------------------
function parseArgs(argv) {
    const args = argv.slice(2);
    let file = "";
    let nodeId = -1;

    for (let i = 0; i < args.length; i++) {
        const a = args[i];
        if (a === "-f" || a === "--file") {
            file = args[++i] || "";
        } else if (a === "-i" || a === "--id") {
            nodeId = parseInt(args[++i], 10);
        } else if (file === "") {
            // 第一个非 flag 位置参数当作 file
            file = a;
        } else {
            // 第二个非 flag 位置参数当作 nodeId
            nodeId = parseInt(a, 10);
        }
    }
    return { file, nodeId };
}

// ---------------------------------------------------------------------------
// 主流程: 复现 ArkNodeProc.process(file, nodeId)
// ---------------------------------------------------------------------------
async function processNode(file, nodeId) {
    if (!file) {
        console.error("Please specify heapsnapshot file with -f/--file");
        return;
    }
    const filepath = path.resolve(file);
    if (!fs.existsSync(filepath)) {
        console.error(`File not found: ${filepath}`);
        return;
    }
    if (nodeId < 0) {
        console.error("Please specify node id with -i/--id");
        return;
    }

    console.info(`Parsing heapsnapshot: ${filepath}`);
    const snapshot = await getFullHeapFromFile(filepath);
    if (!snapshot) {
        console.error("Failed to parse heapsnapshot");
        return;
    }

    const node = snapshot.getNodeById(nodeId);
    if (!node) {
        console.error(`Node not found, id: ${nodeId}`);
        return;
    }
    printNode(node);
}

// ---------------------------------------------------------------------------
// 打印节点信息: 完全复现 ArkNodeProc.printNode(node)
// ---------------------------------------------------------------------------
function printNode(node) {
    console.info("\n======================== Node Info ========================\n");
    console.info(`id:           ${node.id}`);
    console.info(`name:         ${node.name}`);
    console.info(`type:         ${node.type}`);
    console.info(`self_size:    ${node.self_size} bytes (${(node.self_size / 1024).toFixed(2)} KB)`);
    console.info(`retainedSize: ${node.retainedSize} bytes (${(node.retainedSize / 1024).toFixed(2)} KB)`);
    console.info(`isString:     ${node.isString}`);
    console.info(`edge_count:   ${node.edge_count}`);

    if (node.isString) {
        const strNode = node.toStringNode();
        if (strNode) {
            const val = strNode.stringValue;
            console.info(`stringValue:  ${val.length > 200 ? val.slice(0, 200) + "...(truncated)" : val}`);
        }
    }

    console.info("\n======================== Properties ========================\n");
    let idx = 0;
    node.forEachReference((edge) => {
        idx++;
        const prop = edge.is_index ? `[${edge.name_or_index}]` : `${edge.name_or_index}`;
        const to = edge.toNode;
        let value = `-> id:${to.id} name:${to.name} type:${to.type} self_size:${to.self_size}`;
        if (to.isString) {
            const s = to.toStringNode()?.stringValue ?? "";
            const shown = s.length > 100 ? s.slice(0, 100) + "..." : s;
            value += `  value:"${shown}"`;
        }
        console.info(`${idx}. ${prop}  ${value}`);
    });
    console.info(`\nTotal properties: ${idx}`);
}

// ---------------------------------------------------------------------------
// 入口
// ---------------------------------------------------------------------------
(async () => {
    const { file, nodeId } = parseArgs(process.argv);
    try {
        await processNode(file, nodeId);
    } catch (e) {
        console.error(`Error: ${e && e.message ? e.message : e}`);
        process.exitCode = 1;
    }
})();
