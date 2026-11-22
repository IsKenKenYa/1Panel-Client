import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/**
 * DecisionPrompter：关键决策点与⑥双来源分流。
 * TTY：呈现题面+选项读 stdin（无效应答重询，连续 3 次无效/流结束→中止）；
 * 非 TTY：预设应答注入（--answer 列表），缺省中止（码 4 语义源）——编排器不代答。
 */

const mapPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'rules/decision-map.json');

export function loadDecisionMap(path) {
  const m = JSON.parse(readFileSync(path ?? mapPath, 'utf8'));
  if (!m.decisionPoints || !m.sixDecision) throw new Error('decision-map 结构非法（decisionPoints/sixDecision）');
  return m;
}

/** ⑥项分流：@ohos.* 独有→删除/重新设计；@hms.*→呈现替代建议+三选项 */
export function presentSix(item) {
  const map = loadDecisionMap();
  if (item.source !== 'ohos') {
    const kind = item.source === 'hms' ? 'hms-closed' : 'kit-closed';
    return {
      point: `bd:${item.module}::${item.symbol}`,
      question: `${item.module} 的 ${item.symbol} 为 ${item.source === 'hms' ? '@hms.* 闭源' : item.source === 'ndk' ? 'NDK C-API（ArkUI-X 未交付）' : '闭源 Kit/未知来源'}接口（⑥）。建议替代方向：${item.suggested_alternative ?? '需开发者评估'}。处理方式`,
      options: [...map.sixDecision[kind].options],
      source: kind,
    };
  }
  return {
    point: `bd:${item.module}::${item.symbol}`,
    question: `${item.module} 的 ${item.symbol} 为 @ohos.* 系统独有接口（F4 从⑤降出⑥）。处理方式`,
    options: [...map.sixDecision['ohos-unique'].options],
    source: 'ohos-unique',
  };
}

/** 从 ScanReport 提取⑥决策项：全量 business_decision（hms/ohos/kit 等任意 source）+ @ohos.* platform_trim（⑤可降出⑥）；不静默忽略任何⑥项 */
export function sixItemsOf(scanReport) {
  const items = [...(scanReport.adaptation?.business_decision ?? [])];
  for (const it of scanReport.adaptation?.platform_trim ?? []) {
    if (it.source === 'ohos') items.push(it);
  }
  return items;
}

/**
 * 决策询问。
 * @param {{point:string,question:string,options:string[],source?:string}} decision
 * @param {{tty:boolean,presets:Record<string,string>,readLine?:(q:string)=>string}} io
 * @returns {{status:'chosen',chosen:string}|{status:'aborted',reason:string}}
 */
export function askDecision(decision, io) {
  const preset = io.presets?.[decision.point];
 //模块级通配——精确 key 无预设时回退 `bd:@模块` 前缀匹配（同模块全部符号共用一答）
  const moduleKey = decision.point.replace(/::[^:]+$/, '');
  const modulePreset = preset === undefined ? io.presets?.[moduleKey] : undefined;
  const effective = preset !== undefined ? preset : modulePreset;
  if (effective !== undefined) {
    if (!decision.options.includes(effective)) {
      return { status: 'aborted', reason: `预设应答非法：${decision.point}=${effective}（合法：${decision.options.join('/')}）` };
    }
    return { status: 'chosen', chosen: effective };
  }
  if (!io.tty) {
    return { status: 'aborted', reason: `非交互模式缺少预设应答：${decision.point}（--answer ${decision.point}=<${decision.options.join('|')}>）` };
  }
  let invalid = 0;
  for (;;) {
    const answer = (io.readLine?.(`${decision.question} [${decision.options.join('/')}]`) ?? '').trim();
    if (answer === null || answer === undefined || answer === '\x04') {
      return { status: 'aborted', reason: `输入流结束（决策点：${decision.point}）` };
    }
    if (decision.options.includes(answer)) return { status: 'chosen', chosen: answer };
    invalid++;
    if (invalid >= 3) return { status: 'aborted', reason: `连续 3 次无效应答（决策点：${decision.point}）` };
    io.readLine?.(`无效应答，请输入：${decision.options.join('/')}`);
  }
}

/** 从 ScanReport 提取 unknown 待裁决项（F4 编排裁决 ） */
export function unknownItemsOf(scanReport) {
  return [...(scanReport.adaptation?.unknown ?? [])];
}

/** unknown 裁决分流：选项=③④⑤/显式搁置；keep_unknown 为明确选择（缺预设=中止，不代答） */
export function presentUnknown(item, map) {
  const m = map ?? loadDecisionMap();
  return {
    point: `uk:${item.module}::${item.symbol}`,
    question: `${item.module} 的 ${item.symbol} 判定依据未覆盖（unknown）。处理方式`,
    options: [...m.unknownDecision.options],
    source: 'unknown',
  };
}

/** 决策→子 Skill 参数注入（decision-map inject 声明；skeleton_mode 为位置参数、overwrite 为 --confirm-overwrite） */
export function injectArgs(decisionPoint, chosen, map) {
  const dp = map.decisionPoints[decisionPoint];
  if (!dp?.inject) return [];
  if (decisionPoint === 'skeleton_mode') return [chosen];
  if (decisionPoint === 'overwrite') return ['--confirm-overwrite', chosen];
  return [];
}
