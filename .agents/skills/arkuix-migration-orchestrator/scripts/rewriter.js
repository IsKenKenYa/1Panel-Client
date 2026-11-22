import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join, relative, basename, dirname, sep } from 'node:path';

/**
 * Rewriter：源码改写执行器。
 * 消费 MigrationState.decisions + ScanReport locations，对 scaffold 迁入后的源码执行安全改写：
 * - 删除/裁剪/降级 → 注释 import 行 + 重定向到编译保绿 stub 模块 + 调用点插入 TODO 块注释
 * - 降级为OH替代 → import 行注释 + stub 重定向 + 调用点插入替代建议 TODO
 * - equivalent_bridge/degraded_bridge（uk→③④）与⑥降级为平台原生桥接→ 调用点插入 F3 六件套切换 TODO（不改 import——桥接件需接线后才可用）
 * - keep_unknown → 调用点插入搁置标注
 * - reduced_direct（②部分支持）→ 编译阻断项引导：调用点 TODO（不动 import——模块本身可用）
 * - @kit.* 聚合导入 → 按 SDK kit 索引拆分：命中决策模块的符号改自 stub 模块导入，其余符号重发 kit import
 *
 * stub 形态：每模块 ets 根生成 n2b-stubs.ets 真实模块——
 * `export namespace N { export type T = ESObject / export enum E {…占位值} / export class C {static m(…)} / export function f(…ESObject): ESObject }`
 * （按文件内实际用例提取）；原 import 行注释后紧跟 `import { N } from '<rel>/n2b-stubs'` 重定向。
 * 不在业务 .ets 内插语句（避免 arkts-no-misplaced-imports / any-unknown）；接线后应整体删除 stub 模块。
 *
 * 安全约束：不改写既有语句结构（import 行仅整行注释/重定向/拆分重发，其余仅插入注释）；每文件编辑按
 * 行号降序应用（防插入漂移）；幂等（已有 N2B 标注的行/模块跳过，stub 模块由注释态驱动不重复生成）。
 */

const N2B_MARK = '[MIG]';
const TODO_FMT = (decision, module, symbol, action) =>
  `// [MIG] ${module}::${symbol} → ${decision}（${action}）`;
const STUB_MODULE = 'n2b-stubs';
const STUB_HEADER = `/**
 * [MIG] 迁移辅助模块——为已处理的接口提供编译占位。
 * 有桥接件的符号已自动切换到 commons/ 下的桥接转发件（运行时走 Bridge 通道）。
 * 其余符号为编译占位（返回 undefined）——替换为实际实现后删除本文件。
 */`;

const KIT_LINE_RE = /^import\s+((?:type|lazy)\s+)?(.+?)\s+from\s+['"](@kit\.[A-Za-z0-9_.]+)['"]\s*;?\s*$/;
const KIT_MEMBER_RE = /^import\s+(?:type\s+)?.+?\s+from\s+'(@(?:ohos|hms)\.[A-Za-z0-9_.-]+)'\s*;?\s*$/;

/** @returns {{rewritten:number,commentedImports:number,todoSites:number,stubNames:number,stubMembers:number,kitSplits:number,rdSites:number,files:Set,log:string[]}} */
export function applyRewrites(sourceRoot, decisions, scanReport, opts) {
  const result = { rewritten: 0, commentedImports: 0, todoSites: 0, stubNames: 0, stubMembers: 0, kitSplits: 0, rdSites: 0, ambiguous: 0, files: new Set(), log: [] };
  const chosen = (decisions ?? []).filter((d) => d.chosen);
  const rdItems = scanReport?.adaptation?.reduced_direct ?? [];
  if (chosen.length === 0 && rdItems.length === 0) return result;

 // kit 索引：kitsDir 显式传入（测试）或 ARKUIX_SDK_DIR 推导；缺 SDK 时为 null（kit 拆分降级跳过）
  const kitIndex = buildKitIndex(opts?.kitsDir ?? kitsDirFromEnv());

 // 构建 module::symbol → scan item（locations）映射
  const locationMap = new Map();
  for (const bucket of Object.values(scanReport?.adaptation ?? {})) {
    for (const item of bucket ?? []) {
      if (Array.isArray(item?.locations)) {
        locationMap.set(`${item.module}::${item.symbol}`, item);
      }
    }
  }

 // 收集 scaffold 输出的全部 .ets 文件
  const etsFiles = collectEts(sourceRoot);
  const fileLines = new Map(); // 惰性加载
  const loadFile = (abs) => {
    if (!fileLines.has(abs)) {
      try { fileLines.set(abs, readFileSync(abs, 'utf8').split('\n')); }
      catch { fileLines.set(abs, null); }
    }
    return fileLines.get(abs);
  };

 // stub 模块聚合：模块 ets 根 → 名字 → {types:Set, funcs:Set, consts:Set, enums:Map<name,Set<member>>}
  const stubs = new Map();
  const collectStub = (abs, name, lines) => {
    const root = moduleEtsRoot(abs);
    if (!root) return;
    if (!stubs.has(root)) stubs.set(root, new Map());
    const byName = stubs.get(root);
    if (!byName.has(name)) byName.set(name, { types: new Set(), funcs: new Set(), consts: new Set(), enums: new Map(), statics: new Map(), objProps: new Map(), bareType: false });
    const slot = byName.get(name);
    const usage = usagesOf(lines, name);
    for (const t of usage.types) slot.types.add(t);
    for (const f of usage.funcs) slot.funcs.add(f);
    for (const c of usage.consts) slot.consts.add(c);
    if (usage.bareType) slot.bareType = true;
    for (const [t, ps] of usage.objProps) {
      if (!slot.objProps.has(t)) slot.objProps.set(t, new Map());
      mergeShape(slot.objProps.get(t), ps);
    }
    for (const [e, ms] of usage.enums) {
      if (!slot.enums.has(e)) slot.enums.set(e, new Set());
      for (const m of ms) slot.enums.get(e).add(m);
      slot.types.delete(e); // 枚举自身可作类型使用（N.E 裸引用并入枚举）
    }
    for (const [c, fns] of usage.statics) {
      if (!slot.statics.has(c)) slot.statics.set(c, new Set());
      for (const f of fns) slot.statics.get(c).add(f);
      slot.types.delete(c); // 类形态成员优先于类型别名
    }
  };
  /** 文件 → 同模块 stub 模块的 import 说明符（'../../n2b-stubs' 形态，posix） */
  const stubSpecifierOf = (abs) => {
    const root = moduleEtsRoot(abs);
    if (!root) return null;
    let rel = relative(dirname(abs), root).split('\\').join('/');
    if (rel === '') rel = '.';
    return `${rel}/${STUB_MODULE}`;
  };

 // 每文件待应用编辑（按行号降序应用）；markedModules 记录文件内已标注模块（幂等）
  const opsByFile = new Map();
  const markedModules = new Map();
  const pushOp = (abs, idx, run) => {
    if (!opsByFile.has(abs)) opsByFile.set(abs, []);
    opsByFile.get(abs).push({ idx, run });
  };

  for (const d of chosen) {
    const key = d.point.replace(/^(bd|uk):/, '');
    const [module, symbol] = key.split('::');
    const scanItem = locationMap.get(key);
    const locations = scanItem?.locations ?? [];
    const { importAction, siteAction } = actionFor(d.chosen, scanItem?.suggested_alternative);

 // 1) import 行注释/拆分 + ambient stub 登记（删除/裁剪/降级——桥接切换不改 import 因为桥接件需接线）
    if (importAction && /^@(ohos|hms|kit)\./.test(module)) {
      for (const abs of etsFiles) {
        const lines = loadFile(abs);
        if (!lines) continue;
        if (!markedModules.has(abs)) markedModules.set(abs, new Set());
        if (markedModules.get(abs).has(module)) continue; // 文件内每模块一次（幂等）
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          if (line.includes(N2B_MARK)) continue;
 // 1a) 直接模块导入：注释 + 重定向到 stub 模块
          const dm = line.match(new RegExp(`^import\\s+(type\\s+)?(.+?)\\s+from\\s+['"]${escapeRegExp(module)}['"]\\s*;?\\s*$`));
          if (dm) {
            const names = clauseNames(dm[2]);
            for (const n of names) collectStub(abs, n, lines);
            const spec = stubSpecifierOf(abs);
            const redirect = spec
              ? [`import ${dm[1] ?? ''}{ ${names.join(', ')} } from '${spec}'; // [MIG] 迁移占位`]
              : [];
            pushOp(abs, i, (ls) => ls.splice(i, 1,
              `// [MIG] ${line.trim()}`,
              ...redirect));
            markedModules.get(abs).add(module);
            result.commentedImports++;
            result.stubNames += names.length;
            result.files.add(abs);
            result.log.push(`${relative(sourceRoot, abs).split(sep).join('/')}:${i + 1} import 注释+stub 重定向×${names.length}（${module}）`);
            break; // 每文件只处理一次
          }
 // 1b) kit 聚合导入：kit 导出面符号经索引映射到决策模块 → 拆分（命中符号改自 stub 模块导入，其余重发）
          const km = line.match(KIT_LINE_RE);
          if (km && kitIndex) {
            const segs = namedSegments(km[2]);
            const hits = segs.filter((s) => kitIndex.symbols.get(s.kitName) === module);
            if (hits.length > 0) {
              const kept = segs.filter((s) => !hits.includes(s)).map((s) => s.raw);
              for (const h of hits) collectStub(abs, h.local, lines);
              const spec = stubSpecifierOf(abs);
              const redirect = spec
                ? [`import { ${hits.map((h) => h.local).join(', ')} } from '${spec}'; // [MIG] 迁移占位`]
                : [];
              pushOp(abs, i, (ls) => {
                const reEmit = kept.length
                  ? [`import { ${kept.join(', ')} } from '${km[3]}';`] : []; // lazy 前缀已剥离（拆分后无意义）
                ls.splice(i, 1,
                  `// [MIG] ${km[3]} → ${module}: ${line.trim()}`,
                  ...redirect,
                  ...reEmit);
              });
              markedModules.get(abs).add(module);
              result.commentedImports++;
              result.kitSplits++;
              result.stubNames += hits.length;
              result.files.add(abs);
              result.log.push(`${relative(sourceRoot, abs).split(sep).join('/')}:${i + 1} kit 拆分（${km[3]} → ${module}，改 stub 导入 ${hits.map((s) => s.kitName).join(',')}）`);
              break;
            }
          }
        }
      }
    }

 // 2) 调用点 TODO（所有决策类型）
    for (const loc of locations) {
      const m = /^(.+):(\d+)$/.exec(String(loc));
      if (!m) continue;
      const rel = m[1];
      const line = Number(m[2]);
      const target = findFile(etsFiles, rel, (r, cands) => {
        result.ambiguous++;
        result.log.push(`TODO 落点歧义跳过：${r}（同名候选 ${cands.length} 个）`);
      });
      if (!target) continue;
      const lines = loadFile(target);
      if (!lines) continue;
      const alreadyDone = lines.some((l) => l.includes(N2B_MARK) && l.includes(`${module}::${symbol}`));
      if (alreadyDone) continue; // 幂等（按 module::symbol，防行号漂移致二次命中）
      const idx = line - 1;
      if (idx < 0 || idx >= lines.length) continue;
      const todo = TODO_FMT(d.chosen, module, symbol, siteAction);
      pushOp(target, idx, (ls) => ls.splice(idx, 0, todo));
      result.todoSites++;
      result.files.add(target);
      result.log.push(`${relative(sourceRoot, target).split(sep).join('/')}:${line} 调用点 TODO（${d.chosen}）`);
    }
  }

 // 3) ② reduced_direct 编译阻断项：调用点 TODO 引导（模块可用、部分符号编译被拒——不动 import）
  for (const it of rdItems) {
    const module = it.module;
    const symbol = it.symbol;
    const advice = it.advice || '按页内平台标注调整用法';
    for (const loc of it.locations ?? []) {
      const m = /^(.+):(\d+)$/.exec(String(loc));
      if (!m) continue;
      const target = findFile(etsFiles, m[1], (r, cands) => {
        result.ambiguous++;
        result.log.push(`②TODO 落点歧义跳过：${r}（同名候选 ${cands.length} 个）`);
      });
      if (!target) continue;
      const lines = loadFile(target);
      if (!lines) continue;
      if (lines.some((l) => l.includes(N2B_MARK) && l.includes(`${module}::${symbol}`))) continue;
      const idx = Number(m[2]) - 1;
      if (idx < 0 || idx >= lines.length) continue;
      const todo = `// [MIG] ${module}::${symbol} → ②部分支持（${advice}）`;
      pushOp(target, idx, (ls) => ls.splice(idx, 0, todo));
      result.rdSites++;
      result.files.add(target);
      result.log.push(`${relative(sourceRoot, target).split(sep).join('/')}:${m[2]} ②编译阻断 TODO`);
    }
  }

 // 应用编辑：每文件按行号降序（先改后行，防插入漂移）
  for (const [abs, ops] of opsByFile) {
    const lines = fileLines.get(abs);
    if (!lines) continue;
    ops.sort((a, b) => b.idx - a.idx);
    for (const op of ops) op.run(lines);
    writeFileSync(abs, lines.join('\n'), 'utf8');
  }

 // 落盘 stub 模块（每模块 ets 根一个 n2b-stubs.ets：namespace + type/enum/function/const；纯类型名→顶层 type 别名）
  for (const [root, byName] of stubs) {
    const blocks = [];
    const names = [...byName.keys()].sort();
    for (const name of names) {
      const slot = byName.get(name);
      const hasMembers = slot.types.size + slot.funcs.size + slot.consts.size + slot.enums.size + slot.statics.size > 0;
      if (!hasMembers && (slot.bareType || slot.objProps.size > 0)) {
        const selfShape = slot.objProps.get('');
        if (selfShape && selfShape.size > 0) {
          blocks.push(...emitShape(name, selfShape)); // 嵌套形状 → 具名接口族
          result.stubMembers += 1 + selfShape.size;
        } else {
          blocks.push(`export type ${name} = ESObject; // N2B 纯类型 stub`);
          result.stubMembers += 1;
        }
        continue;
      }
      const members = [
        ...[...slot.enums.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([e, ms]) => {
          const entries = [...ms].map((m, i) => `${m} = ${i}`).join(', '); // 占位值——接线后以真实 SDK 值校准
          return `  export enum ${e} { ${entries} } // N2B 占位枚举（值未标定）`;
        }),
        ...[...slot.statics.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([c, fns]) =>
          `  export class ${c} { // N2B 占位类（调用形态——静态方法）\n${[...fns].sort().map((f) =>
            `    public static ${f}(...args: ESObject[]): ESObject {\n      return undefined; // N2B stub——接线后恢复真实实现\n    }`).join('\n')}\n  }`),
        ...[...slot.types].sort((a, b) => a.localeCompare(b)).flatMap((tn) => {
 // 字面量赋值站点提取过形状 → interface（嵌套字面量在严格 ArkTS 下需要显式形状）；否则宽松别名
          const shape = slot.objProps.get(tn);
          if (shape && shape.size > 0) {
            const decls = emitShape(tn, shape);
            return decls.map((d, i) => (i === 0 ? `  ${d} // N2B 形状 stub（字面量站点提取）` : d));
          }
          return [`  export type ${tn} = ESObject;`];
        }),
        ...[...slot.funcs].sort().map((f) =>
          `  export function ${f}(...args: ESObject[]): ESObject {\n    return undefined; // N2B stub——接线后恢复真实实现\n  }`),
        ...[...slot.consts].sort().map((c) => `  export const ${c}: ESObject = undefined; // N2B stub`),
      ];
      blocks.push(`export namespace ${name} {\n${members.length ? members.join('\n') : ' // 未检出成员——按需手工扩充后接线'}\n}`);
      result.stubMembers += slot.types.size + slot.funcs.size + slot.consts.size + slot.enums.size + slot.statics.size;
    }
    writeFileSync(join(root, `${STUB_MODULE}.ets`), mergeStubModule(join(root, `${STUB_MODULE}.ets`), blocks, STUB_HEADER), 'utf8');
    result.files.add(join(root, `${STUB_MODULE}.ets`));
    result.log.push(`${relative(sourceRoot, root).split(sep).join('/')}/${STUB_MODULE}.ets（${names.length} 名字）`);
  }
  // 回调类型自动补注：stub 符号的方法回调参数缺显式类型 → 加 : ESObject（arkts-no-any-unknown 消除）
  const cbFixed = fixupCallbackTypes(sourceRoot, etsFiles, stubs, result);
  if (cbFixed > 0) {
    console.log(`回调类型补注 ${cbFixed} 处（stub 方法回调参数 +ESObject）`);
  }

  result.rewritten = result.commentedImports + result.todoSites + result.rdSites;
  return result;
}

/**
 * 回调类型自动补注：扫描引用了 stub 符号的 .ets 文件，
 * 对 `.on()/.forEach()/.filter()/.map()/.then()` 等回调中未注类型的参数加 `: ESObject`。
 * 仅处理含 n2b-stubs import 的文件（无 stub 引用的文件不动）。
 */
function fixupCallbackTypes(sourceRoot, etsFiles, stubs, result) {
  let fixed = 0;
  // 收集全部 stub 符号名（用于判定文件是否涉及 stub）
  const allStubNames = new Set();
  for (const [, byName] of stubs) {
    for (const name of byName.keys()) allStubNames.add(name);
  }
  if (allStubNames.size === 0) return 0;

  // 回调方法名（这些方法的回调参数容易被推断为 any）
  const CALLBACK_METHODS = /\.(on|off|forEach|filter|map|then|catch|finally|reduce|some|every|find|findIndex|sort)\s*\(/;

  for (const abs of etsFiles) {
    let lines;
    try { lines = readFileSync(abs, 'utf8').split('\n'); } catch { continue; }
    // 仅处理含 stub 引用的文件
    const hasStub = lines.some(l => {
      for (const n of allStubNames) {
        if (l.includes(n + '.') || l.includes(n + '(') || l.includes(`import { ${n}`) || l.includes(`import ${n}`)) return true;
      }
      return false;
    });
    if (!hasStub) continue;

    let fileChanged = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // 匹配回调方法调用且参数无类型注解
      if (!CALLBACK_METHODS.test(line)) continue;
      // 找 (param) => 或 (param1, param2) =>
      // 不处理已有类型的：(x: Type) =>、() =>、(_, __) =>
      // 匹配回调参数无类型注解：(param) => / (p1, p2) => / param =>（无括号单参）
      const cbRe = /\(\s*([a-zA-Z_$][\w$]*)\s*(?:,\s*([a-zA-Z_$][\w$]*)\s*)?\)\s*=>|(?<![\w$.)\s])([a-zA-Z_$][\w$]*)\s*=>/g;
      let m;
      let newLine = line;
      while ((m = cbRe.exec(line)) !== null) {
        // 有括号形态：m[1]/m[2]；无括号单参形态：m[3]
        const p1 = m[1] ?? m[3];
        const p2 = m[2] ?? null;
        if (!p1 || p1 === '_') continue;
        // 检查参数是否已有类型
        const matchedText = m[0];
        if (matchedText.includes(':')) continue;
        const isBoolCallback = /\.(filter|some|every)\s*\(/.test(line.substring(Math.max(0, m.index - 30), m.index));
        let replacement;
        if (p2) {
          replacement = `(${p1}: ESObject, ${p2}: ESObject${isBoolCallback ? '): boolean =>' : ') =>'}`;
        } else {
          replacement = `(${p1}: ESObject${isBoolCallback ? '): boolean =>' : ') =>'}`;
        }
        newLine = newLine.substring(0, m.index) + replacement + newLine.substring(m.index + m[0].length);
        fileChanged = true;
        fixed++;
      }
      if (newLine !== line) {
        lines[i] = newLine;
      }
    }
    if (fileChanged) {
      writeFileSync(abs, lines.join('\n'), 'utf8');
      result.files.add(abs);
      result.log.push(`${relative(sourceRoot, abs).split(sep).join('/')} 回调类型补注`);
    }
  }
  return fixed;
}

function actionFor(chosen, alt) {
  switch (chosen) {
    case '删除': case '裁剪': case 'platform_trim':
      return { importAction: '裁剪——已按决策删除', siteAction: '该调用已裁剪，如需保留请走平台条件编译' };
    case '重新设计实现':
      return { importAction: '待重设计——import 暂注释', siteAction: '需重新设计跨平台实现（可走 F3 五件套）' };
    case '降级为OH替代':
      return { importAction: `降级替代——原 import 注释，替代：${alt || '需评估'}`, siteAction: `替代实现：${alt || '需评估'}` };
    case '自行实现':
      return { importAction: null, siteAction: '自行实现跨平台等价能力' };
    case 'equivalent_bridge': case 'degraded_bridge': case '降级为平台原生桥接':
 // r6-e2e 实证：被裁到③④的模块可能整体不在 ArkUI-X SDK（fabricated/闭源）——原 import 不动必炸
 // "Cannot find module"。改为重定向 stub 编译保绿；接线时把 stub import 换成 F3 commons ①Interface。
 // ⑥→降级为平台原生桥接同款：移桶④后 F3 生成六件套，本改写负责编译保绿+接线 TODO。
      return { importAction: '桥接切换——原 import 注释并重定向 stub（接线后换 F3 ⑥Impl 分发器）', siteAction: '切换到 F3 六件套（import ⑥Impl，getInterface() 自动选③桥接/②Local）——桥接件接线后可用' };
    case 'keep_unknown':
      return { importAction: null, siteAction: '暂搁置（待后续裁决）' };
    default:
      return { importAction: null, siteAction: `按决策「${chosen}」处理` };
  }
}

/** 文件内对名字的用法提取：N.fn(（成员调用）/ N.Sub（类型裸引用）/ N.Sub.MEMBER（枚举）/ N.c（值引用）/ : N.T = {（字面量形状）/ 裸类型位——忽略注释与 import 行 */
function usagesOf(lines, name) {
  const types = new Set();
  const funcs = new Set();
  const consts = new Set();
  const enums = new Map();
  const statics = new Map(); // 类形态成员（N.Sub.member(...) 调用）→ 静态方法集
  const objProps = new Map(); // typeName -> shape 树（prop -> 子树|null）
  let bareType = false;
  const lineOffsets = [0];
  for (const l of lines) lineOffsets.push(lineOffsets[lineOffsets.length - 1] + l.length + 1);
  const flat = lines.join('\n');
  const offsetOf = (row, col) => lineOffsets[row] + col;
  const memberRe = new RegExp(`(?<![\\w$.])${escapeRegExp(name)}\\.([A-Za-z_$][\\w$]*)(?:\\.([A-Za-z_$][\\w$]*))?(\\s*\\()?`, 'g');
 // 类型裸引用位：注解 `: N = {` / `: N;` / 返回类型 `(): N {` / 泛型 `<N` / 数组 `N[` / as N
  const bareTypeRe = new RegExp(`(?:[:<|]\\s*|as\\s+|(?:^|[,;(&])\\s*)${escapeRegExp(name)}\\s*(?:\\[|[,;)=&>}]|$|\\s*\\{)`);
 // 字面量站点：具名类型 `: N.T = {` 与 顶层名直接注解 `: N = {`
  const literalRe = new RegExp(`:\\s*${escapeRegExp(name)}(?:\\.([A-Za-z_$][\\w$]*))?\\s*=\\s*\\{`, 'g');
 // 返回类型站点：`(): N {`（函数体内 return {...} 的形状并入 N）
  const returnRe = new RegExp(`\\)\\s*:\\s*${escapeRegExp(name)}\\s*\\{`, 'g');
  for (let li = 0; li < lines.length; li++) {
    const l = lines[li];
    const t = l.trim();
    if (t.startsWith('//') || t.startsWith('*') || t.startsWith('/*')) continue;
    if (/^import\b/.test(t)) continue;
    memberRe.lastIndex = 0;
    let m;
    while ((m = memberRe.exec(l)) !== null) {
      const member = m[1];
      if (m[2] !== undefined) {
        if (m[3] !== undefined) {
 // N.Sub.member(...) 调用形态：Sub 为类形态成员——枚举成员不可调用，须以 class+static method 占位保编译
          if (!statics.has(member)) statics.set(member, new Set());
          statics.get(member).add(m[2]);
        } else {
 // N.Sub.member 值形态：枚举成员占位（值未标定，接线后以真实 SDK 值校准）
          if (!enums.has(member)) enums.set(member, new Set());
          enums.get(member).add(m[2]);
        }
        types.delete(member);
      } else if (m[3] === '(') {
        funcs.add(member);
      } else if (/^[A-Z]/.test(member)) {
        if (!enums.has(member)) types.add(member); // 已入 enums 的 Sub 不重复（枚举可作类型）
      } else {
        consts.add(member);
      }
    }
    if (!bareType && bareTypeRe.test(l)) bareType = true;
 // : N[.T] = { ... } —— 展平文本递归形状提取（跨行字面量；T 缺省=顶层名自身；深度≤3）
    literalRe.lastIndex = 0;
    while ((m = literalRe.exec(l)) !== null) {
      const typeName = m[1] ?? '';
      const braceStart = l.indexOf('{', m.index + m[0].length - 1);
      const shape = scanShape(flat, offsetOf(li, braceStart), 3);
      if (shape.props.size === 0) continue;
      if (!objProps.has(typeName)) objProps.set(typeName, new Map());
      mergeShape(objProps.get(typeName), shape.props);
    }
 // (): N { ... } —— 函数体内各 return {...} 的形状并入顶层名 N
    returnRe.lastIndex = 0;
    while ((m = returnRe.exec(l)) !== null) {
      const bodyStart = l.indexOf('{', m.index + m[0].length - 1);
      for (const shape of scanReturnShapes(flat, offsetOf(li, bodyStart))) {
        if (shape.props.size === 0) continue;
        if (!objProps.has('')) objProps.set('', new Map());
        mergeShape(objProps.get(''), shape.props);
      }
    }
  }
  return { types, funcs, consts, enums, statics, objProps, bareType };
}

/** 行号/列号 → 展平文本绝对偏移 */
function offsetOf(row, col) {
  return lineOffsets[row] + col;
}

/** 递归形状扫描：str[start] 起的 '{' → { props: Map<prop, 子树|null>, end }（深度 budget 层；占位属性=原始量值） */
function scanShape(str, start, budget) {
  const props = new Map(); // prop -> { sub: Map|null, arr?: boolean }
  let depth = 0;
  let expectProp = false;
  let curName = null;
  let i = start;
  while (i < str.length && i - start < 20000) {
    const ch = str[i];
    if (ch === '{') {
      depth++;
      if (depth === 1) { expectProp = true; i++; continue; }
      if (depth === 2 && curName !== null) {
        const sub = scanShape(str, i, budget - 1);
        if (budget > 0 && sub.props.size > 0 && !props.get(curName)) props.set(curName, { sub: sub.props, arr: false });
        curName = null;
        depth--; // 子块自身配对括号已由 sub 消费——跳回时回退外层深度（否则后续同级属性失明）
        i = sub.end;
        continue;
      }
      i++;
      continue;
    }
    if (ch === '}') { depth--; i++; if (depth === 0) return { props, end: i }; continue; }
    if (ch === '[' && curName !== null) {
 // 数组值：元素含对象字面量 → Array<元素形状>（非可推断嵌套字面量在严格 ArkTS 下需显式元素类型）；
 // 纯原始量数组 → 平铺 ESObject（BackgroundUtil 编译实验已证兼容）
      const arr = scanArrayElem(str, i, budget);
      if (arr.elem) {
        if (!props.get(curName)) props.set(curName, { sub: arr.elem, arr: true });
        curName = null;
        i = arr.end;
        continue;
      }
      curName = null;
    }
    if (depth === 1 && expectProp) {
      const m = /^[A-Za-z_$][\w$]*/.exec(str.slice(i));
      if (m) {
        let k = i + m[0].length;
        while (k < str.length && /\s/.test(str[k])) k++;
        if (str[k] === ':') {
          if (!props.has(m[0])) props.set(m[0], null);
          curName = m[0];
          i = k + 1;
          expectProp = false;
          continue;
        }
      }
    }
    if (depth === 1 && (ch === ',' || ch === ';')) { expectProp = true; curName = null; }
    i++;
  }
  return { props, end: i };
}

/** 数组跨度扫描：首个对象字面量元素形状（无 → null）与数组结束位（']' 之后） */
function scanArrayElem(str, start, budget) {
  let d = 0;
  for (let i = start; i < str.length && i - start < 10000; i++) {
    const ch = str[i];
    if (ch === '[') { d++; continue; }
    if (ch === ']') { d--; if (d === 0) return { elem: null, end: i + 1 }; continue; }
    if (ch === '{' && d >= 1 && budget > 0) {
      const sub = scanShape(str, i, budget - 1);
      return { elem: sub.props.size > 0 ? sub.props : null, end: sub.end };
    }
  }
  return { elem: null, end: start + 1 };
}

/** 函数体（str[start] 起的 '{'）内收集各 `return {` 字面量形状（用于返回类型） */
function scanReturnShapes(str, start) {
  const out = [];
  let depth = 0;
  let seg = '';
  let i = start;
  while (i < str.length && i - start < 30000) {
    const ch = str[i];
    if (ch === '{') {
      depth++;
      if (depth >= 2 && /\breturn\s*$/.test(seg)) out.push(scanShape(str, i, 3));
      seg = '';
      i++;
      continue;
    }
    if (ch === '}') { depth--; seg = ''; i++; if (depth === 0) return out; continue; }
    if (ch === ';') { seg = ''; i++; continue; }
    seg += ch;
    i++;
  }
  return out;
}

/** 形状值归一：{ sub, arr } | Map（兼容）| null */
function normShape(v) {
  if (!v) return null;
  if (typeof v === 'object' && 'sub' in v) return v;
  if (v.size > 0) return { sub: v, arr: false };
  return null;
}

/** 形状树深合并（多站点属性并集；数组标记 OR） */
function mergeShape(dst, src) {
  for (const [k, v] of src) {
    const nv = normShape(v);
    const cur = normShape(dst.get(k));
    if (!cur) {
      dst.set(k, nv); // 占位也落盘（null=原始量属性，须保留键）
      continue;
    }
    if (!nv) continue;
    if (nv.sub && nv.sub.size) {
      if (!cur.sub || !cur.sub.size) cur.sub = nv.sub;
      else mergeShape(cur.sub, nv.sub);
    }
    if (nv.arr) cur.arr = true;
    dst.set(k, cur);
  }
}

/** 形状树 → interface 声明串（嵌套形状生成 <Name><Prop> 具名接口；数组带元素形状 → Array<>；叶子/原始量 → ESObject） */
function emitShape(name, shape, indent = '  ') {
  const decls = [];
  const fields = [];
  for (const [p, v] of shape) {
    const sub = v && typeof v === 'object' && 'sub' in v ? v.sub : (v && v.size ? v : null);
    const arr = !!(v && typeof v === 'object' && v.arr);
    if (sub && sub.size > 0) {
      const nestedName = `${name}${p[0].toUpperCase()}${p.slice(1)}`;
      decls.push(...emitShape(nestedName, sub, indent));
      fields.push(`${indent}${p}?: ${arr ? `Array<${nestedName}>` : nestedName};`);
    } else {
      fields.push(`${indent}${p}?: ESObject;`);
    }
  }
  return [`${indent.slice(2)}export interface ${name} {\n${fields.join('\n')}\n${indent.slice(2)}}`, ...decls];
}

/** stub 模块合并落盘：已有文件（含手改区）保留——缺失声明追加；同名 namespace 做**成员级**合并（新用例成员补入，防重跑后缺成员炸编译） */
function mergeStubModule(stubPath, blocks, header) {
  const fresh = `${header}\n${blocks.join('\n\n')}\n`;
  let existing;
  try {
    existing = readFileSync(stubPath, 'utf8');
  } catch {
    return fresh; // 不在场 → 全新生成
  }
  const declRe = /^export (?:interface|namespace|type|enum) ([A-Za-z_$][\w$]*)/gm;
  const have = new Set();
  for (const m of existing.matchAll(declRe)) have.add(m[1]);
  let out = existing;
  let appended = 0;
  for (const b of blocks) {
    const head = /^export (namespace|interface|type|enum) ([A-Za-z_$][\w$]*)/.exec(b.split('\n')[0]);
    if (!head) continue;
    const [, kind, name] = head;
    if (!have.has(name)) {
      out += `\n${b}\n`;
      appended++;
      continue;
    }
    if (kind !== 'namespace') continue; // interface/type 同名保留已有（手改优先；形状演进由 TODO 引导）
    out = mergeNamespaceMembers(out, name, b) ?? out; // 成员级合并失败则原样保留
  }
  return out;
}

/** 同名 namespace 成员合并：新块独有成员（按成员名签名判定）插入已有 namespace 闭合括号前；解析失败返回 null（原样保留） */
function mergeNamespaceMembers(text, name, newBlock) {
  const startRe = new RegExp(`^export namespace ${name} \\{`, 'm');
  const sm = startRe.exec(text);
  if (!sm) return null;
  const after = text.slice(sm.index);
  const closeRel = after.search(/^}/m); // namespace 闭合顶格 '}'（emitShape 生成形态）
  if (closeRel === -1) return null;
  const blockEndAbs = sm.index + closeRel;
  const block = text.slice(sm.index, blockEndAbs);
  const sigOf = (l) => (/^ {2}export (?:function|enum|interface|const|type) ([A-Za-z_$][\w$]*)/.exec(l))?.[1] ?? null;
  const haveSet = new Set(block.split('\n').map(sigOf).filter(Boolean));
  const chunks = [];
  let cur = null;
  for (const l of newBlock.split('\n').slice(1, -1)) { // 去 namespace 头行与闭合行
    if (/^ {2}export /.test(l)) { if (cur) chunks.push(cur); cur = [l]; }
    else if (cur) cur.push(l);
  }
  if (cur) chunks.push(cur);
  const missing = chunks.filter((c) => { const s = sigOf(c[0]); return s && !haveSet.has(s); });
  if (missing.length === 0) return text;
  const insert = ['', ' // N2B 增量成员（重跑补入，手改区保留）', ...missing.map((c) => c.join('\n'))];
  return text.slice(0, blockEndAbs) + insert.join('\n') + '\n' + text.slice(blockEndAbs);
}

/** 解析 import 子句的全部本地绑定名（默认名/命名空间/具名含 as 别名后） */
function clauseNames(clause) {
  const names = [];
  const ns = clause.match(/\*\s+as\s+([\w$]+)/);
  if (ns) names.push(ns[1]);
  const brace = clause.indexOf('{');
  const head = (brace === -1 ? clause : clause.slice(0, brace)).replace(/\*\s+as\s+[\w$]+/g, '').replace(/,[^,]*$/, '').replace(/^(?:type|lazy)\s+/, '').trim();
  if (/^[\w$]+$/.test(head)) names.push(head);
  for (const seg of namedSegments(clause)) names.push(seg.local);
  return names;
}

/** 解析具名导入段：{ A, B as C, type D } → [{raw, kitName(原名), local(别名后)}] */
function namedSegments(clause) {
  const brace = clause.indexOf('{');
  if (brace === -1) return [];
  const close = clause.lastIndexOf('}');
  const inner = clause.slice(brace + 1, close === -1 ? undefined : close);
  const segs = [];
  for (const part of inner.split(',')) {
    const seg = part.trim();
    if (!seg) continue;
    const m = seg.match(/^(?:(?:type|lazy)\s+)?([\w$]+)(?:\s+as\s+([\w$]+))?$/);
    if (m) segs.push({ raw: seg, kitName: m[1], local: m[2] || m[1] });
  }
  return segs;
}

/** .ets 文件所属模块的 ets 根（.../src/main/ets）；非模块布局回退到文件所在目录 */
function moduleEtsRoot(abs) {
  // 归一化路径分隔符（Windows \ → /），再匹配 marker
  const normalized = abs.split('\\').join('/');
  const marker = '/src/main/ets/';
  const idx = normalized.lastIndexOf(marker);
  return idx === -1 ? dirname(abs) : normalized.slice(0, idx + marker.length - 1);
}

/**
 * kit 索引（与 F2 kit-index.js 同源约定）：
 * 数据源 = OH SDK `ets/kits/@kit.*.d.ts`（`import X, { A } from '@ohos.mod';` 形态）。
 * @returns {{symbols: Map<string,string>}|null} kit 导出面符号 → @ohos 模块；不可用时 null
 */
export function buildKitIndex(kitsDir) {
  if (!kitsDir) return null;
  let entries;
  try {
    entries = readdirSync(kitsDir);
  } catch {
    return null;
  }
  const symbols = new Map();
  for (const name of entries) {
    if (!name.startsWith('@kit.') || !name.endsWith('.d.ts')) continue;
    let text;
    try {
      text = readFileSync(join(kitsDir, name), 'utf8');
    } catch {
      continue;
    }
    for (const raw of text.split('\n')) {
      const m = raw.match(KIT_MEMBER_RE);
      if (!m) continue;
      const clause = raw.match(/^import\s+(?:type\s+)?(.+?)\s+from\s+/)?.[1] ?? '';
      for (const n of clauseNames(clause)) {
        if (!symbols.has(n)) symbols.set(n, m[1]);
      }
    }
  }
  return symbols.size > 0 ? { symbols } : null;
}

function kitsDirFromEnv() {
  const sdk = process.env.ARKUIX_SDK_DIR;
  return sdk ? join(sdk, 'ets', 'kits') : null;
}

function collectEts(root) {
  const out = [];
  (function walk(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.')) continue;
        const f = join(dir, e.name);
        if (e.isDirectory()) walk(f);
        else if (e.name.endsWith('.ets')) out.push(f);
      }
    } catch { /* unreadable */ }
  })(root);
  return out;
}

function findFile(files, relPath, onAmbiguous) {
  const base = basename(relPath);
 // 精确路径匹配优先
  const exact = files.find((f) => f.endsWith(relPath));
  if (exact) return exact;
 // basename 匹配（模块扁平化后中间目录可能不同）；多候选=歧义（同名文件）→ 宁缺毋错跳过并上报
  const candidates = files.filter((f) => basename(f) === base);
  if (candidates.length > 1) {
    onAmbiguous?.(relPath, candidates);
    return null;
  }
  return candidates[0] ?? null;
}

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
