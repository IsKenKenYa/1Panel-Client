import { mkdirSync, writeFileSync, renameSync, existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { readFileSync as rf } from 'node:fs';

/** ArtifactWriter：五件套++报告原子写盘 */

export function atomicWrite(file, content) {
  mkdirSync(dirname(file), { recursive: true });
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}

/**
 * 落盘五件套（合并后内容）并组装 BridgeArtifact。
 * @param {string} outDir 输出目录
 * @param {Array<{item:object, paths:object, texts:object, localStatus:string, localReason?:string, unmapped:boolean}>} pieces
 * @returns {{artifact:object, unmapped:string[], localFailures:Array<{name:string,reason:string}>}}
 */
export function writePieces(outDir, pieces, templates) {
  const artifacts = [];
  const unmapped = [];
  const localFailures = [];
  for (const p of pieces) {
    for (const [rel, text] of Object.entries(p.texts)) {
      atomicWrite(join(outDir, rel), text);
    }
    artifacts.push({
      name: p.item.name,
      symbol: p.item.symbol,
      module: p.item.module,
      category: p.item.category,
      files: {
        interface: p.paths.interface,
        local: p.paths.local,
        arkui_x: p.paths.arkui_x,
        impl: p.paths.impl,
        android: p.paths.android,
        ios: p.paths.ios,
      },
      local_status: p.localStatus,
      ...(p.localStatus === 'failed' ? { reason: p.localReason } : {}),
 // ：可选最低版本标注透传（native-api-map min_*；F4 适用版本澄清消费）
      ...(p.nativeApi?.min_android ? { min_android: p.nativeApi.min_android } : {}),
      ...(p.nativeApi?.min_ios ? { min_ios: p.nativeApi.min_ios } : {}),
      ...(p.unmapped ? { unmapped: true } : {}), // 原生 API 映射未收录——F4 报告区分'在 map 无版本'与'不在 map'
    });
    if (p.unmapped) unmapped.push(`${p.item.module}::${p.item.symbol}`);
    if (p.localStatus === 'failed') localFailures.push({ name: p.item.name, reason: p.localReason });
  }
  if (pieces.length > 0) {
    const androidJavaDir = dirname(pieces[0].paths.android);
    atomicWrite(join(outDir, androidJavaDir, 'BridgeRegistry.java'), registryJava(pieces));
 //  工程级平台判断件（⑥分发器共用依赖；在场不覆盖——开发者可定制）
    const pinfoRel = pieces[0].paths.platform_info;
    if (pinfoRel && templates && templates['platform-info.ets.tpl']) {
      const pinfo = join(outDir, pinfoRel);
      if (!existsSync(pinfo)) {
        atomicWrite(pinfo, templates['platform-info.ets.tpl']);
      }
    }
  }
  return { artifact: { schema_version: 1, artifacts, unmapped_native_apis: unmapped }, unmapped, localFailures };
}

/** Android 侧集中注册件——开发者只需在 Application/Ability 初始化处调用一次 BridgeRegistry.registerAll(ctx, mgr) */
export function registryJava(pieces) {
  const entries = pieces
    .map((p) => `        bridgeManager.registerBridgePlugin("${p.item.name}", new Bridge${p.item.name}(context, bridgeManager));`)
    .join('\n');
  return `// BridgeRegistry.java — 由 arkuix-bridge-codegen 生成（接线辅助）\n// 用法：Android 壳工程初始化处调用一次：BridgeRegistry.registerAll(context, BridgeManager.getInstance());\npackage com.arkuix.bridge;\n\nimport android.content.Context;\nimport ohos.ace.adapter.capability.bridge.BridgeManager;\n\npublic final class BridgeRegistry {\n    private BridgeRegistry() {}\n\n    public static void registerAll(Context context, BridgeManager bridgeManager) {\n${entries}\n    }\n}\n`;
}

export function writeArtifactJson(outDir, artifact) {
  const file = join(outDir, 'bridge-artifact.json');
  atomicWrite(file, JSON.stringify(artifact, null, 2) + '\n');
  return file;
}

/** 报告渲染（templates/report.md.tpl 纯文本占位替换， 零依赖） */
export function renderReport(tpl, vars) {
  return tpl.replace(/\{\{(\w+)\}\}/g, (_, k) => vars[k] ?? '');
}
