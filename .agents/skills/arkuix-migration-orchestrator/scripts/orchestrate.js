#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync, readdirSync, mkdirSync, copyFileSync } from 'node:fs';
import { resolve, join, dirname, basename, relative as pathRelative } from 'node:path';
import readline from 'node:readline/promises';
import { StateManager, STAGES } from './state-manager.js';
import { planStages, missingPreconditions, pendingStages } from './scheduler.js';
import { invokeSkill, skillCommandFor } from './invoker.js';
import { validate } from './validator.js';
import { loadDecisionMap, presentSix, sixItemsOf, presentUnknown, unknownItemsOf, askDecision, injectArgs } from './prompter.js';
import { applyAdjudications } from './adjudicator.js';
import { applyRewrites } from './rewriter.js';
import { composeReport } from './report.js';
import { atomicWrite } from './writer.js';
import { readFileSync as rf, existsSync as ee } from 'node:fs';

/** 多模块工程自动推导 entry 模块名（modify 模式非 TTY 下 ace modify 二级交互需此应答） */

/**
 * 桥接五件套自动落位 + 自动接线——对齐 ArkUI-X 官方工程结构（三层：commons/features/products）。
 * commons 作为独立 HAR 模块落位工程根（非 entry 子目录），业务模块经 oh-package file: 依赖引用。
 */
export function wireBridgeToProject(bridgeOut, projectRoot, mode, bridgeArtifact) {
  let wired = 0;

  // ①③ commons → 工程根 commons/<module>/（独立 HAR 模块，对齐官方 package-structure-guide）
  const commonsSrc = join(bridgeOut, 'commons');
  if (existsSync(commonsSrc)) {
    wired += wireCommonsAsHar(commonsSrc, projectRoot, bridgeArtifact);
  }

  // ④⑤ .arkui-x/ 平台壳 → 工程对应目录
  for (const plat of ['android', 'ios']) {
    const src = join(bridgeOut, '.arkui-x', plat);
    const dst = join(projectRoot, '.arkui-x', plat);
    if (existsSync(src)) {
      wired += copyDir(src, dst);
    }
  }

  // 接线：Android BridgeRegistry 注册注入宿主 Activity 的 onCreate
  // 仅在存在桥接件时注入——BridgeRegistry 类由 F3 随桥接件生成，空产物注入会引用不存在的类导致编译失败
  const androidJavaDir = join(projectRoot, '.arkui-x', 'android', 'app', 'src', 'main', 'java');
  if (existsSync(androidJavaDir) && (bridgeArtifact?.artifacts ?? []).length > 0) {
    injectBridgeRegistry(androidJavaDir);
  }

  // 接线：iOS BridgePlugin 注册注入宿主 ViewController 的 viewDidLoad（同款空产物守卫）
  const iosAppDir = join(projectRoot, '.arkui-x', 'ios', 'app');
  if (existsSync(iosAppDir) && (bridgeArtifact?.artifacts ?? []).length > 0) {
    injectIOSBridge(iosAppDir, bridgeArtifact);
  }

  // 接线：业务 import 从 n2b-stubs 切换到 commons 模块
  if (bridgeArtifact?.artifacts?.length > 0) {
    rewireImportsToCommons(projectRoot, bridgeArtifact.artifacts, join(projectRoot, 'commons'));
  }
  return wired;
}

/**
 * commons 落位为独立 HAR 模块（工程根 commons/<module>/），并注册到 build-profile + oh-package。
 * 目录结构：commons/<module>/src/main/ets/{interface,utils}/ + Index.ets + oh-package.json5
 */
/** 读取 F1 固化 Compile SDK 版本表的版本键清单（插入序=ace 菜单序，末位即最高推荐）。
 *  用于 compile_sdk 专属指引内联支持清单（非交互场景指引自包含）。读取失败返回 null（退回原文案）。 */
function readSdkVersionKeys(skillDir) {
  if (!skillDir) return null;
  try {
    const table = JSON.parse(readFileSync(join(skillDir, 'arkuix-migration-skeleton', 'rules', 'sdk-versions.json'), 'utf8'));
    const keys = (table.versions ?? []).map((v) => v.key).filter(Boolean);
    return keys.length > 0 ? keys : null;
  } catch { return null; }
}

/** 统计源码树中已含 [MIG] 标注的 .ets 文件数——源码改写幂等跳过的判定依据。 */
function countMigMarkedFiles(root) {
  let marked = 0;
  (function walk(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.') || e.name === 'build') continue;
        const f = join(dir, e.name);
        if (e.isDirectory()) walk(f);
        else if (e.name.endsWith('.ets')) {
          try { if (readFileSync(f, 'utf8').includes('[MIG]')) marked++; } catch { /* skip */ }
        }
      }
    } catch { /* skip */ }
  })(root);
  return marked;
}

/** artifact → commons 落位 HAR 模块名（与 wireCommonsAsHar 的目录净化规则同源）。
 *  以 F3 bridge-artifact files 路径中的 commons/<目录名> 为基准（产物即事实）；
 *  files 异常时兜底与 F3 local-extractor.moduleDir 同规则：去 @ → 按 ./ 切段 → 首段 ohos/hms 且多段时丢弃 → '-' 连接。 */
function harNameOfArtifact(a) {
  const f = a.files?.interface || a.files?.local || a.files?.arkui_x || a.files?.android || '';
  const segs = f.split('/');
  const dirName = segs[segs.indexOf('commons') + 1]
    || String(a.module).replace(/^@/, '').split(/[./]/).filter(Boolean)
      .filter((s, i, arr) => !(i === 0 && arr.length > 1 && (s === 'ohos' || s === 'hms')))
      .join('-');
  return dirName.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
}

function wireCommonsAsHar(commonsSrc, projectRoot, bridgeArtifact) {
  let count = 0;
  const allDirs = readdirSync(commonsSrc, { withFileTypes: true }).filter(e => e.isDirectory());
 // ：过滤裸目录（commons/utils 仅含工程级 PlatformInfo——不模块化，分发进各含 impl 的 HAR）
  const modules = allDirs.filter((mod) =>
    ['interface', 'utils', 'impl'].some((s) => existsSync(join(commonsSrc, mod.name, s))));
  for (const mod of modules) {
    const modName = mod.name.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase(); // hvigor 模块名不允许连字符
    const harRoot = join(projectRoot, 'commons', modName);
    const etsDir = join(harRoot, 'src', 'main', 'ets');
    mkdirSync(etsDir, { recursive: true }); // 防 ENOENT：无任何子件拷贝时也要落 oh-package/hvigorfile
    // 拷贝 interface/ + utils/ + impl/（⑥分发器目录）
    for (const sub of ['interface', 'utils', 'impl']) {
      const subSrc = join(commonsSrc, mod.name, sub);
      if (existsSync(subSrc)) {
        count += copyDir(subSrc, join(etsDir, sub));
      }
    }
    // ：工程级 PlatformInfo 分发进含 impl 的 HAR（⑥的相对 import 改写为 HAR 内层级）
    const platformInfoSrc = join(commonsSrc, 'utils', 'PlatformInfo.ets');
    if (existsSync(platformInfoSrc) && existsSync(join(etsDir, 'impl'))) {
      mkdirSync(join(etsDir, 'utils'), { recursive: true });
      copyFileSync(platformInfoSrc, join(etsDir, 'utils', 'PlatformInfo.ets'));
      rewriteImplPlatformImports(join(etsDir, 'impl'));
      count++;
    }
    // 生成 Index.ets（导出命名空间镜像 + 桥接转发件）
    const namespaceFile = join(etsDir, `${modName}_namespace.ets`);
    const artifactSymbols = (bridgeArtifact?.artifacts ?? []).filter((a) => harNameOfArtifact(a) === modName).map((a) => a.symbol);
    const nsContent = buildBridgeNamespace(mod.name, modName, projectRoot, artifactSymbols);
    if (nsContent) {
      writeFileSync(namespaceFile, nsContent, 'utf8');
      count++;
    }
    // Index.ets 恒生成（namespace 镜像不在场也生成——
    // sensor 类未被业务 rewire 的 HAR 缺 Index 而 oh-package 声明 main=Index.ets = 空壳声明）。
    // 导出面（对齐 six-piece-paradigm 模版）：namespace 镜像（业务 rewire 兼容形态）
    // + ⑥Impl 分发器（模版定义的正式入口——XxxImpl.getInterface() 零平台感知调用）
    // + 具名符号接口实例（具名导入 rewire 形态——import { sym } from '<har>' 直取实例，方法经 Bridge 分发）
    const etsFiles = [];
    if (nsContent) etsFiles.push(`export * from './src/main/ets/${modName}_namespace';`);
    if (!nsContent) {
      // 具名符号接口实例导出（import 全部置顶——严格 ArkTS 禁止语句后置 import）
      const namedImports = [];
      const namedExports = [];
      for (const a of (bridgeArtifact?.artifacts ?? [])) {
        if (!a.symbol || harNameOfArtifact(a) !== modName) continue;
        const iface = `${a.name}Interface`;
        const impl = `${a.name}Impl`;
        if (!existsSync(join(etsDir, 'interface', `${iface}.ets`)) || !existsSync(join(etsDir, 'impl', `${impl}.ets`))) continue;
        namedImports.push(`import { ${iface} } from './src/main/ets/interface/${iface}';`);
        namedImports.push(`import { ${impl} } from './src/main/ets/impl/${impl}';`);
        namedExports.push(`export const ${a.symbol}: ${iface} = ${impl}.getInterface();`);
      }
      etsFiles.push(...namedImports, ...namedExports);
    }
    if (existsSync(join(etsDir, 'impl'))) {
      try {
        for (const f of readdirSync(join(etsDir, 'impl'))) {
          const implClass = /export class (\w+Impl)\b/.exec(readFileSync(join(etsDir, 'impl', f), 'utf8'))?.[1];
          if (implClass) etsFiles.push(`export { ${implClass} } from './src/main/ets/impl/${f.replace(/\.ets$/, '')}';`);
        }
      } catch { /* skip */ }
    }
    const indexFile = join(harRoot, 'Index.ets');
    if (etsFiles.length > 0) {
      writeFileSync(indexFile, etsFiles.join('\n') + '\n', 'utf8');
      count++;
    }
    // 生成 oh-package.json5（HAR 包声明）
    writeFileSync(join(harRoot, 'oh-package.json5'), JSON.stringify({
      name: modName,
      version: '1.0.0',
      main: 'Index.ets',
      types: 'Index.ets',
      deviceTypes: ['default', 'tablet', 'phone'],
    }, null, 2) + '\n', 'utf8');
    count++;
    // 生成模块级 build-profile.json5 + hvigorfile.ts（HAR 模块必需）
    writeFileSync(join(harRoot, 'build-profile.json5'), JSON.stringify({
      apiType: 'stageMode',
      buildOption: {},
      targets: [{ name: 'default' }],
    }, null, 2) + '\n', 'utf8');
    writeFileSync(join(harRoot, 'hvigorfile.ts'),
      '// Script for compiling build behavior. It is built in the build plug-in and cannot be modified currently.\n' +
      'export { harTasks } from \'@ohos/hvigor-ohos-plugin\';\n', 'utf8');
    // HAR 必需的 module.json5（hvigor 读取模块元数据）
    const moduleJson5Dir = join(harRoot, 'src', 'main');
    if (!existsSync(join(moduleJson5Dir, 'module.json5'))) {
      writeFileSync(join(moduleJson5Dir, 'module.json5'), JSON.stringify({
        module: {
          name: modName, // 与目录名一致（hvigor 校验约束）
          type: 'har',
          deviceTypes: ['default', 'tablet'],
        },
      }, null, 2) + '\n', 'utf8');
    }
    count++;
  }

  // 注册 commons 模块到工程 build-profile.json5
  if (modules.length > 0) {
    registerCommonsModules(projectRoot, modules.map(m =>
      m.name.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase()));
  }
  return count;
}

/** ：⑥Impl 内的 PlatformInfo 相对 import 改写（F3 平铺层级 → HAR 嵌套层级） */
function rewriteImplPlatformImports(implDir) {
  (function walk(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        const f = join(dir, e.name);
        if (e.isDirectory()) { walk(f); continue; }
        if (!e.name.endsWith('.ets')) continue;
        let t;
        try { t = readFileSync(f, 'utf8'); } catch { continue; }
        if (t.includes('../../utils/PlatformInfo')) {
          writeFileSync(f, t.split("'../../utils/PlatformInfo'").join("'../utils/PlatformInfo'"), 'utf8');
        }
      }
    } catch { /* skip */ }
  })(implDir);
}

/** 在工程根 build-profile.json5 的 modules 数组中注册 commons 模块（幂等——已注册跳过） */
function registerCommonsModules(projectRoot, modNames) {
  const bpPath = join(projectRoot, 'build-profile.json5');
  if (!existsSync(bpPath)) return;
  let t = readFileSync(bpPath, 'utf8');
  // 宽松解析
  const doc = JSON.parse(t
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*$/gm, '')
    .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3')
    .replace(/'([^'\\]*)'/g, '"$1"')
    .replace(/,(\s*[}\]])/g, '$1'));
  if (!doc.modules) doc.modules = [];
  let added = 0;
  for (const name of modNames) {
    const already = doc.modules.some(m => m.name === name);
    if (!already) {
      doc.modules.push({ name, srcPath: `./commons/${name}`, targets: [{ name: 'default', applyToProducts: ['default'] }] });
      added++;
    }
  }
  if (added > 0) {
    writeFileSync(bpPath, JSON.stringify(doc, null, 2) + '\n', 'utf8');
    console.log(`已注册 ${added} 个 commons 模块到 build-profile.json5`);
  }
}

/**
 * 在宿主 StageActivity 的 onCreate 注入 BridgeRegistry.registerAll 调用。
 * BridgeRegistry 固定包名 com.arkuix.bridge（F3 模板约定），import 直接使用。
 */
function injectBridgeRegistry(androidJavaDir) {
  let activityFile = null;
  (function find(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.isDirectory()) { find(join(dir, e.name)); if (activityFile) return; }
        else if (e.name.endsWith('Activity.java') && !e.name.includes('Bridge')) {
          const t = readFileSync(join(dir, e.name), 'utf8');
          if (t.includes('StageActivity') && t.includes('onCreate')) { activityFile = join(dir, e.name); return; }
        }
      }
    } catch { /* skip */ }
  })(androidJavaDir);
  if (!activityFile) return;
  let t = readFileSync(activityFile, 'utf8');
  if (t.includes('BridgeRegistry')) return; // 已注入，幂等
  t = t.replace(/(import\s+ohos\.stage\.ability\.adapter\.StageActivity;)/,
    `$1\nimport com.arkuix.bridge.BridgeRegistry;\nimport ohos.ace.adapter.capability.bridge.BridgeManager;`);
  t = t.replace(/(super\.onCreate\(savedInstanceState\);)/,
    `$1\n        BridgeRegistry.registerAll(this, BridgeManager.getInstance());`);
  writeFileSync(activityFile, t, 'utf8');
  console.log(`已自动接线：${basename(activityFile)} 的 onCreate 注入 BridgeRegistry.registerAll`);
}

/**
 * 业务调用点 import 从 n2b-stubs 切换到 commons HAR 模块。
 * 通过 oh-package 依赖引用（import { X } from 'bridge-<module>'），非文件路径。
 */
function rewireImportsToCommons(projectRoot, artifacts, commonsRoot) {
  // 构建 源模块名 → commons HAR 名 映射（与 wireCommonsAsHar 落位目录同源——harNameOfArtifact，
  // 保证 import 名/oh-package 依赖键/file: 路径与落位目录三者恒一致）
  const moduleToHar = new Map();
  for (const a of artifacts) {
    moduleToHar.set(a.module, harNameOfArtifact(a));
  }
  if (moduleToHar.size === 0) return;

  // 扫描 .ets 文件，将 `import { X } from '...n2b-stubs'` 中有桥接的符号改为 `import { X } from 'bridge-<mod>'`
  const etsFiles = [];
  (function walk(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.') || e.name === 'build') continue;
        const f = join(dir, e.name);
        if (e.isDirectory()) walk(f);
        else if (e.name.endsWith('.ets')) etsFiles.push(f);
      }
    } catch { /* skip */ }
  })(projectRoot);

  let rewired = 0;
  for (const ets of etsFiles) {
    let t;
    try { t = readFileSync(ets, 'utf8'); } catch { continue; }
    if (!t.includes('n2b-stubs')) continue;
    // 从  注释行提取 符号 → 桥接 HAR 映射（仅映射 MIG 注释中明确标注的符号，不全文扫描）
    // 格式1 直接导入：// [MIG] import { camera } from '@ohos.multimedia.camera'
    // 格式2 kit 拆分：// [MIG] @kit.CameraKit → @ohos.multimedia.camera: import { camera } from '@kit.CameraKit'
    const fileBridgeMap = new Map();
    for (const line of t.split('\n')) {
      if (!line.includes('[MIG]')) continue;
      // 提取源模块（优先 kit 拆分的解析结果，其次直接导入路径）
      const resolved = /→\s+(@ohos\.[^\s:]+)/.exec(line)?.[1];
      const direct = /from\s+'(@[^']+)'/   .exec(line)?.[1];
      const srcModule = resolved ?? direct;
      if (!srcModule) continue;
      const har = moduleToHar.get(srcModule);
      if (!har) continue;
      // 提取本条 MIG 注释涉及的符号名（import 子句中的绑定名）
      const clause = /import\s+(?:type\s+)?(\{[^}]+\}|[\w$]+)/.exec(line)?.[1];
      if (!clause) continue;
      const names = clause.startsWith('{')
        ? clause.slice(1, -1).split(',').map(s => s.trim().split(/\s+as\s+/).pop()).filter(Boolean)
        : [clause.trim()];
      for (const n of names) fileBridgeMap.set(n, har);
    }
    let changed = false;
    t = t.replace(/import\s+(?:type\s+)?(\{[^}]+\}|[\w$]+)\s+from\s+['"][^'"]*n2b-stubs['"];?\s*(?:\/\/.*)?/g, (full, clause) => {
      const names = clause.startsWith('{')
        ? clause.slice(1, -1).split(',').map(s => s.trim().split(/\s+as\s+/).pop()).filter(Boolean)
        : [clause.trim()];
      const bridged = names.filter(n => fileBridgeMap.has(n));
      if (bridged.length === 0) return full;
      const pkg = fileBridgeMap.get(bridged[0]);
      const remaining = names.filter(n => !fileBridgeMap.has(n));
      const lines = [];
      if (bridged.length > 0) {
        lines.push(`import { ${bridged.join(', ')} } from '${pkg}';`);
      }
      if (remaining.length > 0) {
        lines.push(`import { ${remaining.join(', ')} } from './n2b-stubs';`);
      }
      changed = true;
      rewired++;
      return lines.join('\n');
    });
    if (changed) {
      writeFileSync(ets, t, 'utf8');
    }
  }
  if (rewired > 0) console.log(`已自动接线：${rewired} 处业务 import 切换到 commons HAR 模块`);

  // 在引用了桥接模块的 oh-package.json5 中注入 file: 依赖
  wireOhPackageDeps(projectRoot, artifacts, moduleToHar, etsFiles);
}

/** 在业务模块的 oh-package.json5 中注入对 commons HAR 的 file: 依赖 */
function wireOhPackageDeps(projectRoot, artifacts, moduleToHar, etsFiles) {
  // 找到含桥接 import 的文件所在模块（向上找 oh-package.json5）
  const needDeps = new Map(); // harName → Set<moduleDir>
  for (const ets of etsFiles) {
    let t;
    try { t = readFileSync(ets, 'utf8'); } catch { continue; }
    for (const [srcModule, harName] of moduleToHar) {
      if (t.includes(`from '${harName}'`)) {
        // 向上找 oh-package.json5
        let dir = dirname(ets);
        while (dir !== projectRoot && dir !== '/') {
          if (existsSync(join(dir, 'oh-package.json5'))) {
            if (!needDeps.has(harName)) needDeps.set(harName, new Set());
            needDeps.get(harName).add(dir);
            break;
          }
          dir = dirname(dir);
        }
        break;
      }
    }
  }
  // 注入依赖
  for (const [harName, moduleDirs] of needDeps) {
    for (const modDir of moduleDirs) {
      const pkgPath = join(modDir, 'oh-package.json5');
      if (!existsSync(pkgPath)) continue;
      let pkg;
      try { pkg = JSON.parse(readFileSync(pkgPath, 'utf8').replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '').replace(/,(\s*[}\]])/g, '$1')); } catch { continue; }
      if (!pkg.dependencies) pkg.dependencies = {};
      if (!pkg.dependencies[harName]) {
        // file: 相对路径按模块真实嵌套层级计算（如 products/phone 二级——算出 rel 直接使用；
        // harName 与落位目录名同源（harNameOfArtifact），拼路径即可）
        const rel = pathRelative(modDir, join(projectRoot, 'commons', harName)).split('\\').join('/');
        pkg.dependencies[harName] = `file:${rel}`;
        writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n', 'utf8');
        console.log(`已注入依赖：${basename(modDir)}/oh-package.json5 → ${harName}（file:${rel}）`);
      }
    }
  }
}

/**
 * iOS BridgePlugin 注册注入宿主 ViewController 的 viewDidLoad。
 * iOS 无集中 Registry（与 Android 不同），逐个 Bridge 在 ViewController 创建：
 *   BridgeXxx *bridge = [[BridgeXxx alloc] initBridgePlugin:@"BridgeName" bridgeManager:[self getBridgeManager]];
 */
function injectIOSBridge(iosAppDir, bridgeArtifact) {
  // 找宿主 ViewController（含 viewDidLoad 且继承 StageViewController）
  let vcFile = null;
  (function find(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.isDirectory()) { find(join(dir, e.name)); if (vcFile) return; }
        else if (e.name.endsWith('ViewController.m') && !e.name.includes('Bridge')) {
          const t = readFileSync(join(dir, e.name), 'utf8');
          if (t.includes('viewDidLoad') && t.includes('initWithInstanceName')) { vcFile = join(dir, e.name); return; }
        }
      }
    } catch { /* skip */ }
  })(iosAppDir);
  if (!vcFile) return;
  let t = readFileSync(vcFile, 'utf8');
  if (t.includes('initBridgePlugin')) return; // 已注入，幂等

  // 收集 BridgeSrc 下的 .h 文件名（Bridge 类名）
  const bridgeSrcDir = join(iosAppDir, 'BridgeSrc');
  if (!existsSync(bridgeSrcDir)) return;
  const bridgeHeaders = readdirSync(bridgeSrcDir).filter(f => f.endsWith('.h'));
  if (bridgeHeaders.length === 0) return;

  // 注入 #import（在第一个 #import 后）
  const imports = bridgeHeaders.map(h => `#import "BridgeSrc/${h}"`).join('\n');
  t = t.replace(/(#import\s+"EntryEntryAbilityViewController\.h")/, `$1\n\n${imports}`);

  // 注入 Bridge 创建（在 viewDidLoad 的 [super viewDidLoad] 后）
  const bridgeCreations = bridgeHeaders.map(h => {
    const cls = h.replace('.h', '');
    const bridgeName = cls.replace(/^Bridge/, '');
    return `    ${cls} *${cls.charAt(0).toLowerCase() + cls.slice(1)} = [[${cls} alloc] initBridgePlugin:@"${bridgeName}" bridgeManager:[self getBridgeManager]];`;
  }).join('\n');
  t = t.replace(/(\[super viewDidLoad\];)/, `$1\n\n    // Bridge 注册（由编排器自动注入）\n${bridgeCreations}`);

  writeFileSync(vcFile, t, 'utf8');
  console.log(`已自动接线：${basename(vcFile)} 的 viewDidLoad 注入 ${bridgeHeaders.length} 个 iOS BridgePlugin`);
}

/**
 * 从工程 n2b-stubs 提取指定模块的命名空间，将函数体从 stub 替换为桥接调用。
 * 业务代码的 import 不变（`import { camera } from 'multimedia_camera'`），编译+运行时均通。
 */
function buildBridgeNamespace(f3ModuleName, harName, projectRoot, extraCandidates = []) {
  // 收集 n2b-stubs 中全部匹配的命名空间（不止首个——@kit.* 多符号各自命名空间需全覆盖）
  const matches = [];
  let scanned = false;
  (function scan(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (scanned) return;
        if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.') || e.name === 'build') continue;
        const f = join(dir, e.name);
        if (e.isDirectory()) scan(f);
        else if (e.name === 'n2b-stubs.ets') {
          const t = readFileSync(f, 'utf8');
          const shortNames = f3ModuleName.split('-').pop();
          const candidates = [shortNames, f3ModuleName.replace(/_/g, ''), ...extraCandidates];
          for (const cand of candidates) {
            if (matches.some((m) => m.nsName === cand)) continue;
            const re = new RegExp(`(export namespace ${cand} \\{[\\s\\S]*?\\n\\}(?=\\n|$))`);
            const m = re.exec(t);
            if (m) matches.push({ content: m[1], nsName: cand });
          }
          scanned = true;
        }
      }
    } catch { /* skip */ }
  })(projectRoot);
  if (matches.length === 0) return null;

  // 扫描业务代码，找各命名空间中被引用但未定义的类型
  const referencedTypes = new Set();
  (function scanTypes(dir) {
    try {
      for (const e of readdirSync(dir, { withFileTypes: true })) {
        if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.') || e.name === 'build') continue;
        const f = join(dir, e.name);
        if (e.isDirectory()) scanTypes(f);
        else if (e.name.endsWith('.ets')) {
          const t = readFileSync(f, 'utf8');
          for (const { nsName } of matches) {
            const typeRe = new RegExp(`\\b${nsName}\\.([A-Z][A-Za-z0-9_]*)\\b`, 'g');
            let tm;
            while ((tm = typeRe.exec(t)) !== null) referencedTypes.add(tm[1]);
          }
        }
      }
    } catch { /* skip */ }
  })(projectRoot);

  const bridgeName = f3ModuleName.replace(/[-_](.)/g, (_, c) => c.toUpperCase()).replace(/^./, c => c.toUpperCase());
  const bridgeSetup = `import Bridge from '@arkui-x.bridge';\nconst nsBridge = Bridge.createBridge('${bridgeName}');\n\n`;
  const blocks = matches.map(({ content, nsName }) => {
    const existingTypes = new Set();
    for (const m of content.matchAll(/export\s+(?:type|interface|enum|class)\s+(\w+)/g)) {
      existingTypes.add(m[1]);
    }
    const missingTypes = [...referencedTypes].filter(t => !existingTypes.has(t) && !/^[a-z]/.test(t));
    let result = content.replace(
      /return undefined;\s*\/\/[^\n]*/g,
      `return nsBridge.callMethod('${nsName}_bridge', ...args); // 桥接转发`
    );
    if (missingTypes.length > 0) {
      const decls = `\n  // 补充命名空间中缺失的类型引用（自动扫描业务代码）\n${missingTypes.map(t => `  export type ${t} = ESObject;`).join('\n')}\n`;
      const lastBrace = result.lastIndexOf('\n}');
      if (lastBrace > 0) result = result.substring(0, lastBrace) + decls + result.substring(lastBrace);
    }
    return result;
  });
  return bridgeSetup + blocks.join('\n\n');
}

function copyDir(src, dst) {
  let count = 0;
  try {
    for (const entry of readdirSync(src, { withFileTypes: true })) {
      const from = join(src, entry.name);
      const to = join(dst, entry.name);
      if (entry.isDirectory()) {
        count += copyDir(from, to);
      } else {
        mkdirSync(dirname(to), { recursive: true });
        copyFileSync(from, to);
        count++;
      }
    }
  } catch { /* skip */ }
  return count;
}

/** 多模块工程自动推导 entry 模块名（modify 模式非 TTY 下 ace modify 二级交互需此应答） */

function deriveModifyEntry(root) {
  try {
    const bp = rf(join(resolve(root), 'build-profile.json5'), 'utf8');
    const doc = JSON.parse(bp
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/\/\/.*$/gm, '')
      .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3')
    .replace(/'([^'\\]*)'/g, '"$1"')
      .replace(/,(\s*[}\]])/g, '$1'));
    const modules = doc?.modules ?? [];
    if (modules.length <= 1) return null; // 单模块无需二级交互
    // 优先取名为 entry 的模块；否则取第一个
    const entry = modules.find((m) => m.name === 'entry') ?? modules[0];
    return entry?.name ?? null;
  } catch { return null; }
}

/** CLI 退出码映射（spec  固化，跨版本稳定） */
const EXIT_OK = 0; // 成功：所选阶段全部完成
const EXIT_INTERNAL = 1; // 内部错误
const EXIT_USAGE = 2; // 输入无效：根目录不存在/参数非法（含阶段名非法）
const EXIT_MISSING = 3; // 阶段前置缺失（场景 5）
const EXIT_ABORT = 4; // 用户中止：决策点中止/回滚目标无 checkpoint
const EXIT_SKILL = 5; // 子 Skill 失败（透传失败阶段与子退出码）

const ARTIFACTS = {
  scan: ['scan-report.json'],
  skeleton: ['skeleton-result.json'],
  bridge: ['bridge-artifact.json'],
};
const SCHEMA_OF = {
  'scan-report.json': 'scan-report.schema.json',
  'skeleton-result.json': 'skeleton-result.schema.json',
  'bridge-artifact.json': 'bridge-artifact.schema.json',
};

function usage() {
  return [
    '用法: node scripts/orchestrate.js <工程根目录> [--stages scan,skeleton,bridge,report] [--out <输出目录>]',
    '                              [--skill-dir <同族Skill根目录>] [--answer <决策ID>=<所选>]... [--rollback <阶段>]',
    '                              [--scaffold-from [目录]]',
    '',
    '编排 扫描(F2)→骨架(F1)→桥接(F3)→报告；MigrationState 断点续跑/回滚；产出 7 段迁移报告。',
    '  --stages <列表>     阶段非空子集（执行序固定；未选阶段标记"未执行"）',
    '  --out <目录>        输出目录（modify 默认 <工程>/.arkui-x/migration/——就地改造无独立输出；new 默认 <工程>/arkuix-orchestrate/——scaffold 落点，锚定工程根不随 CWD 漂移）',
    '  --skill-dir <目录>  同族三 Skill 根目录（含 arkuix-interface-scan/ 等）',
    '  --answer <ID>=<值>  决策预设应答（可多次；非 TTY 缺预设=中止）；内联形态 --answer=<ID>=<值> 等价（单 token）',
    '                              Windows PowerShell：含 @ 的 ID（bd:@kit...）建议单引号包裹；路径值用正斜杠 C:/... 免歧义（内部 path.resolve，\\ / 混用均可）',
    '  --rollback <阶段>   启动时回滚至该阶段 checkpoint 后续跑',
    '  --scaffold-from [目录] 骨架脚手架来源（skeleton 阶段非 TTY 下 ace create 交互必崩——',
    '                              默认无值透传给 F1 使用其内置归档物化（零交互/确定性）；给目录则用指定归档）',
    '  --modify-entry <模块名>  多模块 modify 的 entry 显式选择（优先级：本参数 > --answer modify_entry= 预设 > 自动推导；',
    '                              实际生效值落账 MigrationState.decisions 并打印 [modify-entry] ASCII 行）',
    '',
    '环境变量透传约定：',
    '  ARKUIX_SDK_DIR=<路径>    仅作 F2 内部候选溯源（不再视为确认、不透传）；SDK 确认一律 --answer sdk=<目录>',
    '  ARKUIX_SCAN_YES=1        授权自动探测最佳候选（无 ARKUIX_SDK_DIR 时生效）',
    '',
    '退出码: 0 成功 / 1 内部 / 2 输入无效 / 3 阶段前置缺失 / 4 用户中止 / 5 子 Skill 失败',
  ].join('\n');
}

export function parseArgs(argv) {
  const opts = { root: null, stages: null, out: null, skillDir: null, answers: [], rollback: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--stages') opts.stages = argv[++i]?.split(',').map((s) => s.trim()).filter(Boolean);
    else if (a === '--out') opts.out = argv[++i];
    else if (a === '--skill-dir') opts.skillDir = argv[++i];
    // ：--answer 双形态——flag 消费下一 argv（--answer k=v）与内联单 token（--answer=k=v）等价；
    // 值内含 '=' 无碍（presetsOf 按首个 '=' 切分决策 ID 与所选值）
    else if (a.startsWith('--answer=')) opts.answers.push(a.slice('--answer='.length));
    else if (a === '--answer') opts.answers.push(argv[++i]);
    else if (a === '--rollback') opts.rollback = argv[++i];
    else if (a === '--scaffold-from') {
      const v = argv[i + 1];
      if (v && !v.startsWith('--')) { opts.scaffoldFrom = v; i++; } // 有值 → 指定归档目录
      else opts.scaffoldFrom = true; // 无值 → F1 内置归档（assets/scaffold-26.0.0）
    }
    else if (a === '--strict-crossplatform') opts.strictCrossplatform = true;
    else if (a === '--modify-entry') opts.modifyEntry = argv[++i];
    else if (a === '--help' || a === '-h') { opts.help = true; return opts; }
    else if (!opts.root) opts.root = a;
    else return { ...opts, error: `多余参数：${a}` };
  }
  return opts;
}

function presetsOf(answers) {
  const map = {};
  for (const a of answers ?? []) {
    const idx = a.indexOf('=');
    if (idx <= 0) throw new Error(`--answer 格式非法：${a}（应为 <决策ID>=<所选>）`);
    map[a.slice(0, idx)] = a.slice(idx + 1);
  }
  return map;
}

/** 主流程（导出供测试）：返回退出码 */
export async function run(opts) {
  // 输出目录默认值：modify 模式 → 工程内 .arkui-x/migration/（就地改造，无独立输出目录概念）；
  // new 模式 → 工程内 arkuix-orchestrate/（scaffold 落点）。用户显式 --out 时始终优先。
  const presets = presetsOf(opts.answers);
  const modeFromPreset = presets['skeleton_mode'] ?? 'modify'; // F1 默认建议 modify
  const defaultOut = modeFromPreset === 'modify'
    ? join(resolve(opts.root), '.arkui-x', 'migration')
    : join(resolve(opts.root), 'arkuix-orchestrate');
  const outDir = resolve(opts.out ?? defaultOut);
  const skillDir = opts.skillDir ? resolve(opts.skillDir) : null;
  const decisionMap = loadDecisionMap();

  const sm = new StateManager(outDir);
  let state = sm.load(); // Assessing：加载/新建（断点续跑）

 // 回滚：目标须有 checkpoint
  if (opts.rollback) {
    if (!STAGES.includes(opts.rollback)) { console.error(`错误: 非法回滚阶段：${opts.rollback}`); return EXIT_USAGE; }
    const rb = sm.rollbackTo(opts.rollback);
    if (!rb.ok) { console.error(`用户中止: 回滚失败——${rb.reason}`); return EXIT_ABORT; }
    console.log(`已回滚至 ${opts.rollback} checkpoint，续跑从该阶段开始`);
    state = sm.state; // rollbackTo 替换了 state 对象，同步引用
  }

  const plan = planStages(opts.stages);
  if (!plan.ok) { console.error(`错误: ${plan.reason}`); return EXIT_USAGE; }
  sm.markSkipped(STAGES.filter((s) => !plan.stages.includes(s))); // ：未选阶段 skipped
 // N3-b：本轮计划内的阶段若曾被子集轮标 skipped，解锁为 pending（子集运行不再永久锁死阶段）
  let unlocked = 0;
  for (const st of plan.stages) {
    if (state.stages[st].status === 'skipped') { state.stages[st].status = 'pending'; unlocked++; }
  }
  if (unlocked > 0) { console.log(`已解锁 ${unlocked} 个既往被子集轮跳过的阶段：${plan.stages.filter((s) => true).join('→')}`); sm.flush(); }

  const missing = missingPreconditions(plan.stages, state);
  if (missing.length) {
    console.error(`错误: 阶段前置缺失——${missing.join('；')}（请扩大 --stages 或先补跑上游）`);
    return EXIT_MISSING;
  }

 // 续跑完整性校验：plan 依赖的 done 阶段产物须过契约 Schema，损坏→该阶段重跑
  for (const s of ['scan', 'skeleton', 'bridge']) {
    if (state.stages[s].status === 'done' && plan.stages.some((p) => p === s || PREDEP_OF[p]?.includes(s))) {
      const bad = invalidArtifact(outDir, s);
      if (bad) {
        console.log(`检测到 ${s} 阶段产物不完整（${bad}），将从该阶段重跑`);
        state.stages[s].status = 'pending';
        sm.flush();
      }
    }
  }

  const tty = process.stdin.isTTY === true;
  const rl = tty ? readline.createInterface({ input: process.stdin, output: process.stdout }) : null;
  const io = {
    tty,
    presets,
    readLine: (q) => rl?.question(q + ' ').then((a) => String(a)),
  };
  const scanPath = () => join(outDir, 'scan-report.json');

  try {
    let scanReport = null;
 // ⑥业务决策：scan 完成后引导（未确认不推进依赖阶段）
    const missing = []; // N3：本轮全部待答决策（缺预设/非法预设），统一呈报后中止
    const ensureSixDecided = async () => {
      if (scanReport === null && existsSync(scanPath())) {
        scanReport = JSON.parse(readFileSync(scanPath(), 'utf8'));
      }
      if (!scanReport) return;
      for (const item of sixItemsOf(scanReport)) {
        const decision = presentSix(item);
        if (state.decisions.some((d) => d.point === decision.point && d.chosen)) continue; // 已确认保留
        sm.recordDecision({ point: decision.point, question: decision.question, options: decision.options, source: decision.source });
        const r = await askDecision(decision, io);
        if (r.status === 'aborted') {
          missing.push(`${decision.point}=<${decision.options.join('|')}>（${r.reason}）`);
          continue; // N3：不立即中止，收集全部待答后统一呈报
        }
        sm.recordDecision({ point: decision.point, question: decision.question, options: decision.options, chosen: r.chosen, source: decision.source });
      }
    };

 // unknown 编排裁决：scan 完成后逐项引导，裁决后回写 ScanReport（全流程事实一致）
    let unknownAdjudicated = false;
    const ensureUnknownDecided = async () => {
      if (scanReport === null && existsSync(scanPath())) {
        scanReport = JSON.parse(readFileSync(scanPath(), 'utf8'));
      }
      if (!scanReport || unknownAdjudicated) return null;
      for (const item of unknownItemsOf(scanReport)) {
        const decision = presentUnknown(item);
        if (state.decisions.some((d) => d.point === decision.point && d.chosen)) continue; // 已裁决保留
        sm.recordDecision({ point: decision.point, question: decision.question, options: decision.options, source: 'unknown' });
        const r = await askDecision(decision, io);
        if (r.status === 'aborted') {
          missing.push(`${decision.point}=<${decision.options.join('|')}>（${r.reason}）`);
          continue; // N3：统一收集
        }
        sm.recordDecision({ point: decision.point, question: decision.question, options: decision.options, chosen: r.chosen, source: 'unknown' });
      }
 //bd-only 仓（uk=0）也要回写 bd 标注——
 // applyAdjudications 独立于 uk 分支：只要有已 chosen 决策（bd 或 uk）即调用
      const anyChosen = state.decisions.some((d) => d.chosen);
      if (anyChosen) {
        const result = applyAdjudications(scanPath(), state.decisions);
        if (result.moved.length || result.kept.length) {
          console.log(`裁决已回写 ScanReport（unknown→③④⑤ / ⑥→④平台原生桥接）：移桶 ${result.moved.length} 项${result.moved.length ? '（' + result.moved.join('、') + '）' : ''}，显式搁置 ${result.kept.length} 项`);
        }
        scanReport = JSON.parse(readFileSync(scanPath(), 'utf8')); // 刷新缓存（事实一致）
      }
      unknownAdjudicated = true;
      return null;
    };

 // 关键决策点：骨架模式（skeleton 执行前）
 // 初始化即从已落账 decisions 恢复——续跑/回滚轮 skeleton 阶段已 done 不再过决策门，
 // 此前保持 null 会导致落位/改写误判为 new 模式（projectRoot 取 outDir）
    let skeletonMode = state.decisions.find((d) => d.point === 'skeleton_mode' && d.chosen)?.chosen ?? null;
    const ensureSkeletonMode = async () => {
      if (skeletonMode !== null) return null;
      const dp = decisionMap.decisionPoints.skeleton_mode;
      if (!state.decisions.some((d) => d.point === 'skeleton_mode' && d.chosen)) {
        sm.recordDecision({ point: 'skeleton_mode', question: dp.question, options: dp.options });
        const r = await askDecision({ point: 'skeleton_mode', question: dp.question, options: dp.options }, io);
        if (r.status === 'aborted') { console.error(`用户中止: ${r.reason}`); return EXIT_ABORT; }
        sm.recordDecision({ point: 'skeleton_mode', question: dp.question, options: dp.options, chosen: r.chosen });
      }
      skeletonMode = state.decisions.find((d) => d.point === 'skeleton_mode').chosen ?? dp.default;
      return null;
    };

    for (const stage of pendingStages(plan.stages, state)) {
      if (stage === 'report') continue; // report 阶段为内部合成（Reporting 态，不调度子 Skill）
 // 决策前置（AwaitingConfirm）
      if (stage === 'skeleton' || stage === 'bridge') {
        await ensureSixDecided();
        await ensureUnknownDecided();
        if (missing.length > 0) {
          console.error(`用户中止: 需补 ${missing.length} 项决策预设（一次列全，补齐后重跑）——`);
          for (const m of missing) console.error(`  --answer ${m.split('（')[0]}`);
          return EXIT_ABORT;
        }
      }
      if (stage === 'skeleton') {
        const abort = await ensureSkeletonMode();
        if (abort !== null) return abort;
      }

 // Applying：子进程调度——TTY 交互透传（子 Skill 的确认关口直达终端）
      if (!skillDir) { console.error('错误: 缺少 --skill-dir（同族三 Skill 根目录）'); return EXIT_USAGE; }
      const base = skillCommandFor(stage, skillDir);
      const args = [...base.slice(1)];
      if (stage === 'scan') {
        args.push(opts.root, '--out', outDir);
 // （用户反馈：SDK 目录一律经开发者确认，不自作主张）：编排器不再从环境变量自动选定 SDK——
 //  - 开发者显式预设 --answer sdk=<目录>（decision-map 决策点）→ 注入 --sdk-dir（显式=已确认）
 //  - 未预设 → F2 呈报候选清单（推荐序：最新含 kits 在前）并以退出码 4 停止 → 本编排器转"待确认 SDK"
 //  - TTY → F2 交互确认直达终端
 //  - ARKUIX_SDK_DIR/ARKUIX_OH_SDK_DIR 不再视为确认（仅作 F2 内部候选溯源，不再自动注入）
        const sdkPreset = presets['sdk']
          ?? state.decisions.find((d) => d.point === 'sdk' && d.chosen)?.chosen;
        console.error(`[scan] tty=${tty}, sdk-preset=${sdkPreset ? 'given' : 'unset（候选将呈报待确认）'}, spawn=piped（确认门恒走呈报，pty 自动应答免疫）`);
        if (sdkPreset) {
          args.push('--sdk-dir', sdkPreset);
          if (!state.decisions.some((d) => d.point === 'sdk')) {
            sm.recordDecision({
              point: 'sdk', question: 'OpenHarmony SDK 判定源（路径+版本）', options: [],
              chosen: sdkPreset, source: 'preset',
            });
          }
        }
 // --answer force_no_kits=1 → 透传 F2 质量门显式确认开关（仅开发者确认后果后使用）
        if (presets['force_no_kits'] === '1') {
          args.push('--force-no-kits');
          if (!state.decisions.some((d) => d.point === 'force_no_kits')) {
            sm.recordDecision({ point: 'force_no_kits', question: 'SDK 无 kits 后果确认（@kit.* 全归⑥）', options: ['1'], chosen: '1', source: 'preset' });
          }
        }
      }
      if (stage === 'skeleton') {
        args.push(opts.root, '--scan-report', scanPath(), '--mode', skeletonMode, '--out', outDir);
 // new 模式：骨架物化前明确打印 scaffold 落点（用户/agent 事前可知、可 --out 改路径）
        if (skeletonMode === 'new') {
          console.log(`scaffold 落点：${outDir}（new 模式默认工程内平铺目录；如需更改以 --out 显式指定）`);
        }
 // F1 分类/计划确认门——TTY 下不越权：让 F1 自行呈现 scan 分类结果并请用户确认；
 // 非 TTY 不无条件注入 --yes（防绕过强确认门——agent 未呈报即跑完）；
 // 显式授权 = ARKUIX_SCAN_YES=1（SDK+分类一揽子授权，与 F2 同名同义）；未授权时 F1 退出码 6 → 本编排器转码 4 呈报待确认
        if (!tty && process.env.ARKUIX_SCAN_YES === '1') args.push('--yes');
 //scaffold 来源——归档物化（零交互/确定性），TTY/非 TTY 均推荐
        args.push('--scaffold-from');
        if (typeof opts.scaffoldFrom === 'string') args.push(opts.scaffoldFrom);
        if (opts.strictCrossplatform) args.push('--strict-crossplatform'); //  严格模式透传（默认关=注入降警告开关）
 // ：entry 三级来源——显式 --modify-entry > --answer modify_entry= 预设 > 自动推导（多模块 modify）；
 // 生效值落账 MigrationState.decisions（agent 结构化可读）+ ASCII 调试行（Windows 控制台乱码免疫）
        const entryPreset = presets['modify_entry'];
        const effectiveEntry = opts.modifyEntry
          ?? (skeletonMode === 'modify' ? entryPreset : undefined)
          ?? (skeletonMode === 'modify' ? deriveModifyEntry(opts.root) : undefined);
        if (effectiveEntry) {
          args.push('--modify-entry', effectiveEntry);
          const entrySource = opts.modifyEntry ? 'explicit' : (skeletonMode === 'modify' && entryPreset === effectiveEntry ? 'preset' : 'derived');
          sm.recordDecision({
            point: 'modify_entry', question: '多模块 modify 的 entry 模块（ace modify 二级交互应答）',
            options: [], chosen: effectiveEntry, source: entrySource,
          });
          console.log(`[modify-entry] entry=${effectiveEntry} source=${entrySource} (override: --modify-entry <module> | --answer modify_entry=<module>)`);
        }
 // new 模式配置迁移强确认门——决策预设/落账注入 --migrate-configs <yes|no>；
 // 非交互缺预设由 F1 以退出码 6 拒绝（下方转码逻辑转 4 并给 --answer migrate_configs= 专属指引）
        if (skeletonMode === 'new') {
          const mcPreset = presets['migrate_configs']
            ?? state.decisions.find((d) => d.point === 'migrate_configs' && d.chosen)?.chosen;
          if (mcPreset) {
            args.push('--migrate-configs', mcPreset);
            if (!state.decisions.some((d) => d.point === 'migrate_configs')) {
              sm.recordDecision({
                point: 'migrate_configs',
                question: 'new 模式是否合并迁入源工程配置文件（白名单策略 + 遗漏/多改双向校验）',
                options: ['yes', 'no'], chosen: mcPreset, source: 'preset',
              });
            }
          }
 // Compile SDK 版本强确认门（同款不代答语义）：预设注入 --compile-sdk <版本>（值=版本键或全形态，
 // F1 按固化版本表解析替换六元组；与 --scaffold-from <显式目录> 互斥由 F1 校验——编排器恒传内置归档不受影响）
          const csPreset = presets['compile_sdk']
            ?? state.decisions.find((d) => d.point === 'compile_sdk' && d.chosen)?.chosen;
          if (csPreset) {
            args.push('--compile-sdk', csPreset);
            if (!state.decisions.some((d) => d.point === 'compile_sdk')) {
              sm.recordDecision({
                point: 'compile_sdk',
                question: 'new 模式 Compile SDK 版本（scaffold 编译基线；推荐最高 26.0.0，其次源工程版本）',
                options: [], chosen: csPreset, source: 'preset',
              });
            }
          }
        }
      }
      if (stage === 'bridge') args.push(opts.root, '--scan-report', scanPath(), '--out', join(outDir, 'bridge'));
      sm.markRunning(stage);
 //  自检加固：scan 阶段恒以管道模式调度（不继承终端）——F2 的 SDK 确认门在 TTY 交互模式下
 // 会被 agent-pty 自动应答（空行=默认 Y 直接确认候选），开发者根本看不到；恒管道则 F2 必走
 // 非交互分支：无预设 → 退出码 4 + 候选清单 → 本编排器呈报"待确认 SDK"，确认唯一通道
 // = --answer sdk=<目录>（决策落账 MigrationState，可审计）
      const scanPiped = stage === 'scan';
      const result = invokeSkill({ cmd: base[0], args, timeoutMs: opts.timeoutMs, interactive: tty && !scanPiped });
 // ：scan 阶段 F2 退出码 4 = SDK 候选未经开发者确认（强制门）→ 转待确认（码 4），
 // 候选清单原样透传供 agent 呈报（不以"工具失败"误导，也不代答）
      if (stage === 'scan' && result.exitCode === 4) {
        sm.markInterrupted(stage, '待确认 SDK（子退出码 4）');
        console.error('子 Skill 待确认: 阶段=scan 退出码=4（SDK 判定源未经确认—— 询问先行：先向开发者确认本机 SDK 路径，探测候选仅作参考）——');
        console.error('请向开发者确认本机 OpenHarmony SDK 路径（查找方法与参考候选见下方子 Skill 输出），确认后带 --answer sdk=<SDK目录> 重跑（断点续跑自动续 scan 阶段）：');
        if (result.stderr) console.error(result.stderr.trim());
        return EXIT_ABORT;
      }
 // ：子 Skill 确认门未过（退出码 6 =  分类确认未授权）→ 编排器转用户中止（码 4）+
 // 待确认指引（不静默吞掉确认语义，也不再以"工具失败"误导）
      if (result.exitCode === 6) {
        sm.markInterrupted(stage, `待确认（子退出码 6）`);
        console.error(`子 Skill 待确认: 阶段=${stage} 退出码=6（分类/计划确认未授权）——`);
 // new 模式缺 migrate_configs 预设的专属指引（区分于分类确认门——本门须显式 yes/no，不代答）
        if (stage === 'skeleton' && skeletonMode === 'new' && !presets['migrate_configs']
          && !state.decisions.some((d) => d.point === 'migrate_configs' && d.chosen)) {
          console.error('new 模式需确认是否迁移源工程配置文件（白名单合并+遗漏/多改校验）——带 --answer migrate_configs=yes|no 重跑（yes=合并迁入；no=维持 scaffold 模板配置）。');
        }
 // Compile SDK 版本门缺预设的专属指引（支持清单读 F1 固化版本表内联，保证非交互场景指引自包含；读不到时退回原文案）
        if (stage === 'skeleton' && skeletonMode === 'new' && !presets['compile_sdk']
          && !state.decisions.some((d) => d.point === 'compile_sdk' && d.chosen)) {
          const keys = readSdkVersionKeys(skillDir);
          console.error(keys
            ? `new 模式需确认 Compile SDK 版本（scaffold 编译基线；推荐最高 ${keys[keys.length - 1]}，其次源工程版本）——带 --answer compile_sdk=<版本> 重跑（支持清单：${keys.join(' / ')}）。`
            : 'new 模式需确认 Compile SDK 版本（scaffold 编译基线；推荐最高 26.0.0，其次源工程版本）——带 --answer compile_sdk=<版本> 重跑（支持清单见下方子 Skill 输出）。');
        }
        console.error('请向开发者呈报子 Skill 输出的分类结果，确认后带 ARKUIX_SCAN_YES=1（分类确认授权）或 --answer 预设重跑。');
        if (result.stderr) console.error(result.stderr.trim());
        return EXIT_ABORT;
      }
      if (result.exitCode !== 0) {
        sm.markInterrupted(stage, result.timedOut ? `子进程超时` : `子退出码 ${result.exitCode}`);
        console.error(`子 Skill 失败: 阶段=${stage} 子退出码=${result.exitCode}${result.timedOut ? '（超时）' : ''}`);
        if (result.stderr) console.error(result.stderr.trim());
        return EXIT_SKILL;
      }
 // scan 成功也透传子进程 stderr（SDK 全量候选清单/质量警示——即使 agent 抢跑塞了
 // --answer sdk 预设，开发者仍能看到完整候选面做交叉核对）+ stdout 的 SDK 选定行
      if (stage === 'scan') {
        if (result.stderr) console.error(result.stderr.trim());
        const sdkLine = String(result.stdout || '').split('\n')
          .find((l) => l.includes('SDK 判定源') || l.includes('已自动选择 SDK'));
        if (sdkLine) console.error(sdkLine.trim());
      }

 // Checkpointing：产物校验+落账
      const bad = invalidArtifact(outDir, stage);
      if (bad && stage !== 'report') {
        sm.markInterrupted(stage, `产物校验失败（${bad}）`);
        console.error(`子 Skill 失败: 阶段=${stage} 产物校验失败——${bad}`);
        return EXIT_SKILL;
      }
 // ：skeleton 完成后自动执行源码改写（决策→import 注释/stub/调用点 TODO；②阻断项→TODO）
      if (stage === 'skeleton') {
        if (scanReport === null && existsSync(scanPath())) {
          scanReport = JSON.parse(readFileSync(scanPath(), 'utf8'));
        }
        const hasReduced = (scanReport?.adaptation?.reduced_direct ?? []).length > 0;
        if (state.decisions.some((d) => d.chosen) || hasReduced) {
 //modify 模式源码保留在 opts.root，new 模式已迁入 outDir
          const scaffoldDir = skeletonMode === 'modify' ? opts.root : outDir;
 //  实测：kit 拆分索引源=开发者确认的 SDK（scan-report.sdk.path 的 ets/kits）——
 // 此前只靠 ARKUIX_SDK_DIR env（编排链未设→@kit.* 聚合导入静默不拆分）
          const confirmedSdk = scanReport?.sdk?.path;
          const kitsDir = confirmedSdk ? join(confirmedSdk, 'ets', 'kits') : undefined;
          const rr = applyRewrites(scaffoldDir, state.decisions, scanReport, { kitsDir });
          if (rr.rewritten > 0) {
            console.log(`源码改写完成——import 注释 ${rr.commentedImports} 处（kit 拆分 ${rr.kitSplits}），ambient stub ${rr.stubNames} 名字/${rr.stubMembers} 成员，调用点 TODO ${rr.todoSites} 处，②编译阻断 TODO ${rr.rdSites} 处（${rr.files.size} 个文件）`);
          } else {
            const chosenCount = state.decisions.filter((d) => d.chosen).length;
            if (chosenCount > 0) {
              // 源码已含 [MIG] 标注 → 幂等跳过（正常态，info 不告警）；无标注才提示检查源码位置
              const marked = countMigMarkedFiles(scaffoldDir);
              if (marked > 0) {
                console.log(`源码改写幂等跳过——${marked} 个文件已含 [MIG] 标注，本轮无新增改写（决策保持有效）`);
              } else {
                console.warn(`⚠  告警：已确认 ${chosenCount} 项决策但改写 0 处（扫描根：${scaffoldDir}）——请检查源码是否在预期位置；modify 模式源码应在工程根目录`);
              }
            }
          }
        }
      }
      // bridge 产物自动落位工程——生成的桥接代码必须出现在工程内，不是留在编排输出目录让人手动拷
      if (stage === 'bridge') {
        const bridgeOut = join(outDir, 'bridge');
        const projectRoot = skeletonMode === 'modify' ? opts.root : outDir;
        const bridgeArtifactPath = join(bridgeOut, 'bridge-artifact.json');
        const bridgeArtifact = existsSync(bridgeArtifactPath) ? JSON.parse(readFileSync(bridgeArtifactPath, 'utf8')) : null;
        const wired = wireBridgeToProject(bridgeOut, projectRoot, skeletonMode, bridgeArtifact);
        if (wired > 0) {
          console.log(`桥接产物已落位工程：${wired} 文件 → ${projectRoot}（.arkui-x/ + commons/）`);
        }
      }
      sm.markDone(stage, ARTIFACTS[stage] ?? ['migration-report.md'], result.exitCode);
    }

 // Reporting：迁移报告恒产出（未选阶段以"未执行"标注）；report 阶段落账仅在其被计划时
    if (state.stages.report.status !== 'done') {
 //消费裁决后的最新 ScanReport（而非内存中的旧缓存）；bridge 消费落盘产物
      const freshScan = existsSync(scanPath()) ? JSON.parse(readFileSync(scanPath(), 'utf8')) : null;
      const artifacts = {
        scan: freshScan,
        skeleton: existsSync(join(outDir, 'skeleton-result.json')) ? JSON.parse(readFileSync(join(outDir, 'skeleton-result.json'), 'utf8')) : null,
        bridge: existsSync(join(outDir, 'bridge', 'bridge-artifact.json')) ? JSON.parse(readFileSync(join(outDir, 'bridge', 'bridge-artifact.json'), 'utf8')) : null,
      };
 //report 阶段先落账再合成（消除自指 pending）
      if (plan.stages.includes('report')) sm.markDone('report', ['migration-report.md'], 0);
      const md = composeReport(state, artifacts);
      atomicWrite(join(outDir, 'migration-report.md'), md);
    }

 // bridge_codegen 决策点：bridge 产出了五件套时，询问开发者是否继续进行平台代码生成
 // （agent 按 F3 docs/adaptation-guide.md §二B 代填围栏内实现 + 编译验证 + diff 呈报）
    const bridgeArtifactPath = join(outDir, 'bridge', 'bridge-artifact.json');
    if (state.stages.bridge.status === 'done' && existsSync(bridgeArtifactPath)) {
      const bars = JSON.parse(readFileSync(bridgeArtifactPath, 'utf8'));
      if ((bars.artifacts ?? []).length > 0) {
        const dp = decisionMap.decisionPoints.bridge_codegen;
        if (!state.decisions.some((d) => d.point === 'bridge_codegen' && d.chosen)) {
          sm.recordDecision({ point: 'bridge_codegen', question: dp.question, options: dp.options });
          const r = await askDecision({ point: 'bridge_codegen', question: dp.question, options: dp.options }, io);
          if (r.status === 'aborted') {
 // 非 TTY 缺预设 → 默认 skip（可选决策，不阻断——与⑥/uk 必答决策不同）
            sm.recordDecision({ point: 'bridge_codegen', question: dp.question, options: dp.options, chosen: 'skip' });
          } else {
            sm.recordDecision({ point: 'bridge_codegen', question: dp.question, options: dp.options, chosen: r.chosen });
          }
        }
        const codegenChoice = state.decisions.find((d) => d.point === 'bridge_codegen')?.chosen ?? 'skip';
        if (codegenChoice === 'proceed') {
          console.log(`\n═══ 平台代码生成指引（${bars.artifacts.length} 个桥接件待实现）═══`);
          console.log(`  按 F3 docs/adaptation-guide.md §二B（代填档）执行：`);
          console.log(`  1. 逐接口生成围栏内实现（④Android BridgePlugin / ⑤iOS BridgePlugin 方法体）`);
          console.log(`  2. 编译自检：ace build apk → 产物判定（ArkTS 0 Error + APK 在场）`);
          console.log(`  3. diff 呈报开发者确认`);
          // 版本约束门——agent 代填前必须完成版本确认（编排器不代查，只约束 agent 必须查）
          const skel = existsSync(join(outDir, 'skeleton-result.json'))
            ? JSON.parse(readFileSync(join(outDir, 'skeleton-result.json'), 'utf8')) : null;
          const pbLine = skel?.platform_baseline;
          const pbText = pbLine?.android || pbLine?.ios
            ? `${pbLine.android ? `Android minSdk ${pbLine.android.min_sdk}` : ''}${pbLine.android && pbLine.ios ? ' / ' : ''}${pbLine.ios ? `iOS ${pbLine.ios.deployment_target}` : ''}`
            : '（未取得 skeleton 产物基线）';
          console.log(`  工程基线：${pbText}`);
          const unverified = [];
          for (const a of (bars.artifacts ?? [])) {
            if (a.min_android || a.min_ios) {
              console.log(`  ✓ ${a.name}：Android ${a.min_android || '?'} / iOS ${a.min_ios || '?'}（native-api-map 策展——围栏内实现须使用不低于此版本的原生 API）`);
            } else {
              // unmapped 或无版本标注——agent 必须查官方文档确认版本，编排器不代查只约束
              const reason = a.unmapped ? '原生 API 映射未策展（连替代 API 都未知）' : '在 map 但无版本标注';
              console.log(`  ⚠ ${a.name}：${reason}——agent 必须查 Android/iOS 官方文档确认替代 API 及其最低版本，在围栏注释中标注版本要求后方可实现；不得凭猜测选用过新或过时接口`);
              unverified.push(a.name);
            }
          }
          if (unverified.length > 0) {
            console.log(`\n  ⛔ 版本约束门：${unverified.length} 个接口的版本信息未经策展（${unverified.join('、')}）`);
            console.log(`     agent 须逐个查官方文档确认最低版本并在围栏注释中标注，呈报开发者确认后方可代填实现`);
            console.log(`     编排器不代查版本信息——这是 agent 的职责（查不到须如实呈报开发者而非猜测）`);
          }
          console.log(`  ⚠ 使用有问题（编译失败/运行异常）时，请先确认目标设备与开发环境不低于上述版本，并升级 ArkUI-X SDK / Android SDK / Xcode 后重试`);
          console.log(`  桥接产物：${bridgeArtifactPath}`);
          console.log(`  围栏位置：grep -rn "ARKUIX-BRIDGE-HANDOFF" ${outDir}`);
        }
      }
    }

    state.current_stage = 'done';
    delete state.interrupted_at;
    sm.flush();
 //未消费的 --answer 预设 key 告警（防拼错静默丢弃）
    const consumedKeys = new Set(state.decisions.map((d) => d.point));
    for (const key of Object.keys(presets)) {
      if (!consumedKeys.has(key)) {
        // 区分两种情形：决策点不存在（拼写错误） vs 决策已记录预设冗余（断点续跑场景）
        const isKnownDecision = decisionMap.decisionPoints[key.replace(/=.*$/, '')] !== undefined
          || key.startsWith('bd:') || key.startsWith('uk:');
        if (isKnownDecision) {
          console.log(`ℹ 预设 ${key} 已在上次运行中记录（断点续跑冗余，可移除）`);
        } else {
          console.warn(`⚠ 预设未消费：--answer ${key}=...（key 不匹配任何决策点，请检查拼写）`);
        }
      }
    }
    console.log(`编排完成：${plan.stages.join('→')}；产物目录 ${outDir}`);
    return EXIT_OK;
  } finally {
    rl?.close();
  }
}

const PREDEP_OF = { skeleton: ['scan'], bridge: ['scan'], report: [] };

/** 阶段产物契约校验：任一可校验产物损坏即返回原因（report 阶段无可校验契约返回 null） */
function invalidArtifact(outDir, stage) {
  const rulesDir = new URL('../rules/schemas/', import.meta.url);
  for (const rel of ARTIFACTS[stage] ?? []) {
    const schemaFile = SCHEMA_OF[rel];
    if (!schemaFile) continue;
    const abs = rel === 'bridge-artifact.json' ? join(outDir, 'bridge', rel) : join(outDir, rel);
    if (!existsSync(abs)) return `${rel} 不存在`;
    let instance;
    try {
      instance = JSON.parse(readFileSync(abs, 'utf8'));
    } catch {
      return `${rel} JSON 解析失败`;
    }
    const schema = JSON.parse(readFileSync(new URL(schemaFile, rulesDir), 'utf8'));
    const v = validate(instance, schema);
    if (!v.ok) return `${rel} 契约不符：${v.errors.slice(0, 3).join('；')}`;
  }
  return null;
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (opts.help) { console.log(usage()); return EXIT_OK; }
  if (opts.error) { console.error(`错误: ${opts.error}`); console.error(usage()); return EXIT_USAGE; }
  if (!opts.root) { console.error('错误: 缺少工程根目录'); console.error(usage()); return EXIT_USAGE; }
  if (!existsSync(resolve(opts.root))) { console.error(`错误: 工程根目录不存在：${opts.root}`); return EXIT_USAGE; }
  try {
    return await run(opts);
  } catch (e) {
    console.error(`内部错误: ${e.message}`);
    return EXIT_INTERNAL;
  }
}

if (process.argv[1] && process.argv[1].endsWith('orchestrate.js')) {
  process.exit(await main(process.argv.slice(2)));
}
