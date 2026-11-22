import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/** 产物契约路径拼接（'/' 分隔）——契约值平台无关：win32 的 join 产生 '\' 会破坏
 *  下游消费（F4 落位接线/断言比对均以 '/' 形态书写）；文件系统路径仍用原生 join */
const pJoin = (...segs) => segs.join('/');
import { loadNativeApiMap, matchNativeApi } from './native-map.js';
import { localFilePath, moduleDir, splitLocalContent, freeIdentifiersOf } from './local-extractor.js';
import { methodIndexOf } from './interface-composer.js';

/** 六件套渲染（模板即契约——签名由①Interface 派生； 对齐 docs"一码三平台"范式） */

const tplDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'templates');

export function loadTemplates() {
  const names = ['interface.ets.tpl', 'local.ets.tpl', 'arkuix.ets.tpl', 'impl.ets.tpl',
    'platform-info.ets.tpl', 'android-bridge.java.tpl', 'ios-bridge.h.tpl', 'ios-bridge.m.tpl'];
  const t = {};
  for (const n of names) t[n] = readFileSync(join(tplDir, n), 'utf8');
  return t;
}

function render(tpl, vars) {
  return tpl.replace(/\{\{(\w+)\}\}/g, (_, k) => vars[k] ?? '');
}

/**  TODO 注解三要素：接口名+平台+③④分类 */
export function todoAnnotation(item, platform) {
  return `TODO(ARKUIX-BRIDGE): interface=${item.name} platform=${platform} category=${item.category} — 业务逻辑待开发者补齐`;
}

/** HANDOFF 围栏（Java 行注释 / ObjC pragma 两形态） */
export const FENCE = {
  java: { begin: '// ARKUIX-BRIDGE-HANDOFF BEGIN', end: '// ARKUIX-BRIDGE-HANDOFF END' },
  objc: { begin: '#pragma mark ARKUIX-BRIDGE-HANDOFF BEGIN', end: '#pragma mark ARKUIX-BRIDGE-HANDOFF END' },
};

function androidBodyLines(item, nativeApi) {
  if (nativeApi) {
    const lines = [` // 等价原生 API：${nativeApi.android}`];
 // ：可选最低版本标注（native-api-map min_android）——围栏内自文档，F4 报告/bridge-artifact 同步透传
    if (nativeApi.min_android) {
      lines.push(` // 最低版本要求：Android ${nativeApi.min_android}——低于此版本请升级开发环境或调整适配方案`);
    }
    lines.push(` // return ${nativeApi.android};`);
    return lines;
  }
  const hint = item.category === 'degraded_bridge'
    ? ` // 降级说明：${item.reason || '该能力在 ArkUI-X 侧需降级实现'}`
    : ' // 等价原生 API 未收录（unmapped_native_apis），需人工确认映射';
  return [hint, ` // ${todoAnnotation(item, 'android')}`];
}

function iosBodyLines(item, nativeApi) {
  if (nativeApi) {
    const lines = [` // 等价原生 API：${nativeApi.ios}`];
    if (nativeApi.min_ios) {
      lines.push(` // 最低版本要求：${nativeApi.min_ios}——低于此版本请升级开发环境或调整适配方案`);
    }
    lines.push(` // return ${nativeApi.ios};`);
    return lines;
  }
  const hint = item.category === 'degraded_bridge'
    ? ` // 降级说明：${item.reason || '该能力在 ArkUI-X 侧需降级实现'}`
    : ' // 等价原生 API 未收录（unmapped_native_apis），需人工确认映射';
  return [hint, ` // ${todoAnnotation(item, 'ios')}`];
}

/**
 * ②Local 方法体构建（class 化）：源工程语句按方法名分派到对应契约方法体
 * （语句含 `.方法名(` 即归该方法）；未匹配方法的语句进类尾"未分派原语句"参考块；
 * 无迁移源的方法给 TODO 占位体。方法统一收尾 `return Promise.resolve(null);` 保编译。
 */
function localMethodBodies(name, methods, local, module) {
  const sig = (m) => m.params.map((p) => `${p.name}: ${p.type}`).join(', ');
  if (local.status !== 'migrated') {
    return {
      imports: [],
      bodies: methods.map((m) => [
        `  /** 迁移源读取失败：${(local.reason ?? '需手动补入').replace(/\n/g, ' ')} */`,
        `  public ${m.name}(${sig(m)}): Promise<Bridge.ResultValue> {`,
        `    // TODO(ARKUIX-BRIDGE-LOCAL): 方法体待手动补入（HarmonyOS 端直调 @ohos.* 实现）`,
        `    return Promise.resolve(null);`,
        `  }`,
      ].join('\n')).join('\n\n'),
    };
  }
  const { imports, statements } = splitLocalContent(local.content);
  const sigOf = (m) => m.params.map((p) => `${p.name}: ${p.type}`).join(', ');
 // ：自引用 import 剔除——/接线把源 import 改写为 commons HAR 模块名
  // （@ohos.multimedia.camera → multimedia_camera），Local 本身就在该 HAR 里（自引用 = 编译错/循环）
  const ownHar = module ? moduleDir(module).replace(/-/g, '_') : '';
  const liveImports = imports.filter((l) => {
    const spec = /from\s+['"]([^'"]+)['"]/.exec(l)?.[1] ?? '';
    return spec !== ownHar;
  });
  // 语句单元按 `.方法名(` 分派到对应契约方法体；未命中的语句进类尾"未分派"参考块；
  // 无语句命中的方法给 TODO 占位体
  const assigned = new Map();
  for (const stmt of statements) {
    const m = methods.find((mm) => !assigned.has(mm) && new RegExp(`\\.${escapeRe(mm.name)}\\s*\\(`).test(stmt));
    if (m) assigned.set(m, stmt);
  }
  const bodies = methods.map((m) => {
    const stmt = assigned.get(m);
    const bodyLines = stmt
      ? statementBody(stmt, m.name, local.ref, liveImports)
      : [
        `    // TODO(ARKUIX-BRIDGE-LOCAL): 方法体待从源工程迁入（调用点见 scan-report locations）`,
      ];
    return [
      `  public ${m.name}(${sigOf(m)}): Promise<Bridge.ResultValue> {`,
      ...bodyLines,
      `    return Promise.resolve(null);`,
      `  }`,
    ].join('\n');
  }).join('\n\n');
  const leftover = statements.filter((s) => ![...assigned.values()].includes(s));
  const leftoverBlock = leftover.length
    ? `\n\n  /** 未分派原语句（未匹配契约方法——接线时人工归位）：\n${leftover.flatMap((s) => s.split('\n').map((l) => `   * ${l}`)).join('\n')}\n   */`
    : '';
  return { imports: liveImports, bodies: bodies + leftoverBlock };
}

/**
 * ：语句方法体可编译性判定。
 * - 语句引用 `this.x`（struct/类成员——Local 类无此成员）或含未解析自由标识符
 *   （不在 live import / 内联 const 中）→ **注释化保留**（`// ORIG:` 前缀），方法体保底
 *   `return Promise.resolve(null)`——类真正可编译（兑现 SKILL.md 声称）
 * - 语句自含（标识符全解析、无 this 引用）→ live 平铺（原样执行）
 */
function statementBody(stmt, methodName, ref, liveImports) {
  const hasThis = /\bthis\s*\./.test(stmt);
  const ids = freeIdentifiersOf(stmt, '');
  const resolvable = (id) => {
    for (const line of liveImports) {
      if (line.startsWith('//')) continue; // 注释化的 [MIG] 行不算已解析
      if (bindsImportName(line, id)) return true;
    }
    return false;
  };
  const unresolved = ids.filter((id) => !resolvable(id));
  if (!hasThis && unresolved.length === 0) {
    return [
      `    // 迁移原语句（源工程 ${ref ?? ''}）——参数/返回值接线待补：`,
      ...stmt.split('\n').map((l) => `    ${l}`),
    ];
  }
  const why = hasThis ? '含 this 成员引用（Local 类无该成员）' : `未解析标识符: ${unresolved.join(', ')}`;
  return [
    `    // ORIG（源工程 ${ref ?? ''}）——${why}，注释化保编译；接线时取消注释并：`,
    `    //   形参替换硬编码实参 / this.X 赋值改 return / 补未解析标识符的 import`,
    ...stmt.split('\n').map((l) => `    // ORIG: ${l}`),
  ];
}

/** import 行是否绑定指定标识符（具名/默认/as 别名——委托 local-extractor 同款语义的轻量版） */
function bindsImportName(importLine, id) {
  const m = /^\s*import\s+(?:type\s+)?(.+?)\s+from\s/.exec(importLine);
  if (!m) return false;
  const binding = m[1];
  if (/^[A-Za-z_$][\w$]*$/.test(binding)) return binding === id;
  const named = binding.match(/\{(.*)\}/);
  if (named) {
    return named[1].split(',').some((seg) => {
      const parts = seg.trim().split(/\s+as\s+/);
      return (parts[1] ?? parts[0] ?? '').trim() === id;
    });
  }
  return false;
}

function escapeRe(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * 渲染单接口六件套（③类查 native-api-map：已知→映射等价原生 API，未知→unmapped；④类→降级占位）。
 * ：②Local/③ArkUIX class 化（implements ①），新增⑥Impl 平台分发器；④⑤不变。
 * ④⑤ 按契约**全方法**渲染（单方法渲染会使多方法契约在平台侧缺方法）。
 * @returns {{paths:{interface,local,arkui_x,impl,android,ios,ios_m,platform_info:string},
 *            texts:同 paths 键→渲染文本, unmapped:boolean, nativeApi?:object}}
 */
export function renderFivePieces(item, local, contract, templates) {
  const bridgeName = item.name;
  const moduleDirSeg = moduleDir(item.module);
  const nativeApi = item.category === 'equivalent_bridge' ? matchNativeApi(item.module, item.symbol) : undefined;
  // unmapped：③不在 map / ④不查 map（降级桥接的原生 API 由 agent 在围栏内确定，版本信息同样需人工策展）
  const unmapped = !nativeApi;

  // ：④ Java 全方法声明（每方法一围栏+提示；映射建议置于首方法围栏）
  const javaMethodDecls = contract.methods.map((m, idx) => {
    const hintLines = idx === 0
      ? androidBodyLines(item, nativeApi)
      : androidBodyLines(item, nativeApi).slice(-1); // 后续方法仅标准 TODO 三要素
    return [
      `    public String ${m.name}(${m.params.map((p) => `${javaTypeOf(p.type)} ${p.name}`).join(', ')}) {`,
      [FENCE.java.begin, ...hintLines, FENCE.java.end].join('\n'),
      `        return null; // TODO(ARKUIX-BRIDGE): 返回值待实现（见围栏内标注）`,
      `    }`,
    ].join('\n');
  }).join('\n\n');

  // ：⑤ ObjC 全方法签名（多参选择器 name:arg2: 形态）与实现体
  const objcSigOf = (m) => {
    const parts = m.params.map((p, i) => `${i === 0 ? m.name : `arg${i + 1}`}:(${objcTypeOf(p.type)})${p.name}`);
    return `- (NSString*)${parts.join(' ')};`;
  };
  const objcImplOf = (m) => {
    const parts = m.params.map((p, i) => `${i === 0 ? m.name : `arg${i + 1}`}:(${objcTypeOf(p.type)})${p.name}`);
    return [
      `- (NSString*)${parts.join(' ')} {`,
      [FENCE.objc.begin, ...iosBodyLines(item, nativeApi), FENCE.objc.end].join('\n'),
      `    return nil; // TODO(ARKUIX-BRIDGE): 返回值待实现（见围栏内标注）`,
      `}`,
    ].join('\n');
  };

  const localBuild = localMethodBodies(item.name, contract.methods, local, item.module);
  const localImports = localBuild.imports ? localBuild.imports.join('\n') : '';

  const paths = {
    interface: pJoin('commons', moduleDirSeg, 'interface', `${contract.interfaceName}.ets`),
    local: localFilePath(item),
    arkui_x: pJoin('commons', moduleDirSeg, 'utils', `${item.name}ArkUIX.ets`),
    impl: pJoin('commons', moduleDirSeg, 'impl', `${item.name}Impl.ets`),
    android: pJoin('.arkui-x', 'android', 'app', 'src', 'main', 'java', 'com', 'arkuix', 'bridge', `Bridge${bridgeName}.java`),
    ios: pJoin('.arkui-x', 'ios', 'app', 'BridgeSrc', `Bridge${bridgeName}.h`),
    ios_m: pJoin('.arkui-x', 'ios', 'app', 'BridgeSrc', `Bridge${bridgeName}.m`),
    platform_info: pJoin('commons', 'utils', 'PlatformInfo.ets'),
  };
  const texts = {
    [paths.interface]: render(templates['interface.ets.tpl'], {
      interfaceName: contract.interfaceName,
      methodSignatures: contract.methods
        .map((m) => `  ${m.name}(${m.params.map((p) => `${p.name}: ${p.type}`).join(', ')}): Promise<Bridge.ResultValue>;`)
        .join('\n'),
    }),
    [paths.local]: render(templates['local.ets.tpl'], {
      name: item.name, interfaceName: contract.interfaceName,
      localImports, methodBodies: localBuild.bodies,
    }),
    [paths.arkui_x]: render(templates['arkuix.ets.tpl'], {
      name: item.name, interfaceName: contract.interfaceName, bridgeName,
      methodForwards: contract.methods
        .map((m) => `  public ${m.name}(${m.params.map((p) => `${p.name}: ${p.type}`).join(', ')}): Promise<Bridge.ResultValue> {\n    return ${item.name}ArkUIX.bridgeImpl.callMethod('${m.name}'${m.params.length ? ', ' + m.params.map((p) => p.name).join(', ') : ''});\n  }`)
        .join('\n\n'),
    }),
    [paths.impl]: render(templates['impl.ets.tpl'], {
      name: item.name, interfaceName: contract.interfaceName,
      primaryMethod: contract.methods[0]?.name ?? methodIndexOf(item.symbol),
    }),
    [paths.android]: render(templates['android-bridge.java.tpl'], {
      name: bridgeName, bridgeName,
      methodDecls: javaMethodDecls,
    }),
    [paths.ios]: render(templates['ios-bridge.h.tpl'], {
      name: bridgeName,
      methodSigs: contract.methods.map(objcSigOf).join('\n'),
    }),
    [paths.ios_m]: render(templates['ios-bridge.m.tpl'], {
      name: bridgeName, bridgeName,
      methodImpls: contract.methods.map(objcImplOf).join('\n\n'),
    }),
  };
  return { paths, texts, unmapped, nativeApi };
}

/** Bridge 类型 → Java 形参类型（ESObject→Object——平台侧编解码边界） */
function javaTypeOf(type) {
  return type === 'string' ? 'String' : type === 'number' ? 'double' : type === 'boolean' ? 'boolean' : 'Object';
}

/** Bridge 类型 → ObjC 形参类型 */
function objcTypeOf(type) {
  return type === 'string' ? 'NSString*' : type === 'number' ? 'NSNumber*' : type === 'boolean' ? 'NSNumber*' : 'id';
}

export { loadNativeApiMap };
