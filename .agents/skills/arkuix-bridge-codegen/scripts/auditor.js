import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { isShellOnly, netBracketDepth } from './local-extractor.js';

/**
 * 产物自检：五件套落盘后的确定性结构检查——生成 ≠ 一定完好，
 * 残缺项显式呈报给消费方 agent 读取补全（不静默流出残件，也不以失败伪装——
 * 残缺=待补信号，退出码不变）。
 * 检查项（全部确定性，零启发式）：
 * - 硬残缺（deficient——产物坏了/必补）：
 *   file-missing 五件未落盘 / interface-thin 契约空壳 / local-unbalanced 括号不闭合 /
 *   local-shell 空壳 / local-placeholder 失败占位 / arkuix-shape / android-shape / ios-shape
 * - 建议级（suggestions——可选增强）：
 *   contract-thin 契约为单方法兜底（调用面未解析到，信息量低）
 * @param {string} outDir 输出目录
 * @param {Array<{item:object, paths:object, texts:object, localStatus:string, derived?:string}>} pieces
 * @returns {{checked:number, deficient_count:number, deficient:Array,
 *            suggestion_count:number, suggestions:Array}}
 */
export function auditPieces(outDir, pieces) {
  const deficient = [];
  const suggestions = [];
  for (const p of pieces) {
    const name = p.item.name;
    const symbol = p.item.symbol;
    const locations = Array.isArray(p.item.locations) ? p.item.locations : [];
    const issues = [];
    const read = (rel) => {
      const f = join(outDir, rel);
      return existsSync(f) ? readFileSync(f, 'utf8') : null;
    };
    const FIVE = [
      ['interface', p.paths.interface], ['local', p.paths.local], ['arkui_x', p.paths.arkui_x],
      ['impl', p.paths.impl], ['android', p.paths.android], ['ios', p.paths.ios],
    ];
    const texts = {};
    for (const [key, rel] of FIVE) {
      texts[key] = rel ? read(rel) : null;
      if (!texts[key]) {
        issues.push({
          file: rel ?? `(${key})`, kind: 'file-missing', detail: `五件之${key}未落盘`,
          action: '重跑 bridge.js；复现则检查模板渲染与输出目录写权限',
        });
      }
    }

    if (texts.interface !== null) {
      if (!new RegExp(`export\\s+interface\\s+${name}Interface\\b`).test(texts.interface)
        || !/\)\s*:\s*Promise\s*</.test(texts.interface)) {
        issues.push({
          file: p.paths.interface, kind: 'interface-thin', detail: '①Interface 缺方法声明（契约空壳）',
          action: `读取 ${locations[0] ?? '源工程 locations'} 对应源码，按真实 API 面补全 ${name}Interface 方法签名`,
        });
      }
    }

    if (texts.local !== null) {
      if (p.localStatus === 'failed' || /源码读取失败/.test(texts.local.slice(0, 300))) {
        issues.push({
          file: p.paths.local, kind: 'local-placeholder', detail: '②Local 为失败占位（迁移源未读到）',
          action: `读取源工程 locations（${locations.slice(0, 2).join('、') || '见 scan-report'}）对应调用实现，补入本文件`,
        });
      } else if (isShellOnly(texts.local)) {
        issues.push({
          file: p.paths.local, kind: 'local-shell', detail: '②Local 有效内容为空壳（仅注释/import）',
          action: '读取源工程对应调用实现补入（语句完整、括号闭合）',
        });
      } else {
        const depth = netBracketDepth(texts.local);
        if (depth !== 0) {
          issues.push({
            file: p.paths.local, kind: 'local-unbalanced', detail: `②Local 括号不闭合（净深度 ${depth > 0 ? '+' : ''}${depth}）——不可编译`,
            action: `读取源工程 locations（${locations[0] ?? '见 scan-report'}）对应完整语句，补全本文件缺失的闭合与后续语句`,
          });
        }
      }
    }

    if (texts.arkui_x !== null && (!/createBridge\s*\(/.test(texts.arkui_x) || !/callMethod\s*\(/.test(texts.arkui_x))) {
      issues.push({
        file: p.paths.arkui_x, kind: 'arkuix-shape', detail: '③缺 createBridge/callMethod 转发结构',
        action: `按 ①${name}Interface 契约补全 ${name}ArkUIX.ets 的方法转发（Bridge.createBridge + callMethod）`,
      });
    }

    if (texts.impl !== null && (!new RegExp(`class\\s+${name}Impl\\b`).test(texts.impl) || !/getInterface\s*\(/.test(texts.impl))) {
      issues.push({
        file: p.paths.impl, kind: 'impl-shape', detail: `⑥缺 class ${name}Impl/getInterface 分发器结构`,
        action: `补全 ${name}Impl.ets（Android/iOS→③ArkUIX，HarmonyOS→②Local，依赖工程级 PlatformInfo）`,
      });
    }

    if (texts.android !== null && !new RegExp(`class\\s+Bridge${name}\\b[\\s\\S]*extends\\s+BridgePlugin`).test(texts.android)) {
      issues.push({
        file: p.paths.android, kind: 'android-shape', detail: '④缺 class Bridge' + name + ' extends BridgePlugin 结构',
        action: `补全 Bridge${name}.java 类骨架（BridgePlugin 子类+构造子+①契约方法）`,
      });
    }

    if (texts.ios !== null) {
      if (!new RegExp(`@interface\\s+Bridge${name}\\b`).test(texts.ios)) {
        issues.push({
          file: p.paths.ios, kind: 'ios-shape', detail: `⑤.h 缺 @interface Bridge${name} 声明`,
          action: `补全 Bridge${name}.h（BridgePlugin 子类+①契约方法签名）`,
        });
      }
      const mFile = p.paths.ios_m ?? p.paths.ios.replace(/\.h$/, '.m');
      const mText = read(mFile);
      if (mText !== null && !new RegExp(`@implementation\\s+Bridge${name}\\b`).test(mText)) {
        issues.push({
          file: mFile, kind: 'ios-shape', detail: `⑤.m 缺 @implementation Bridge${name}`,
          action: `补全 Bridge${name}.m 实现（对应 .h 声明，围栏内补业务）`,
        });
      }
    }

    if (p.derived === 'default') {
      suggestions.push({
        name, symbol,
        issues: [{
          file: p.paths.interface, kind: 'contract-thin', detail: '契约为单方法兜底（调用面未解析到——信息量低）',
          action: `读取源工程 locations（${locations.slice(0, 2).join('、') || '见 scan-report'}）与 ②Local，补全 ${name}Interface 真实方法面`,
        }],
      });
    }

 // 语义自检：契约面 vs SDK 声明面覆盖缺口（结构自检只保编译可过，语义缺失不设防）
    if (p.sdkFaceMethodCount > 0 && p.contractMethodCount < p.sdkFaceMethodCount) {
      const missing = p.sdkFaceMethodCount - p.contractMethodCount;
      suggestions.push({
        name, symbol,
        issues: [{
          file: p.paths.interface, kind: 'contract-incomplete', kindDetail: '',
          detail: `契约面 ${p.contractMethodCount} 方法 < SDK 声明面 ${p.sdkFaceMethodCount} 方法（缺 ${missing} 个——语义覆盖缺口）`,
          action: `对照 SDK d.ts 声明（scan-report 确认的 SDK ets/api 下 @ohos 模块 d.ts）补全 ${name}Interface 缺失方法及 ②③⑥ 对应实现`,
        }],
      });
    }

    if (issues.length > 0) deficient.push({ name, symbol, issues });
  }
  return {
    checked: pieces.length,
    deficient_count: deficient.length,
    deficient,
    suggestion_count: suggestions.length,
    suggestions,
  };
}
