import { readFileSync } from 'node:fs';

/**
 * 模型前置：
 * - fa           → reject_fa（提示 FA 不支持，零写）
 * - 缺失/不可解析/unknown → reject_unknown（引导先运行 F2，零写）
 * - stage        → pass
 */
export function loadReport(path) {
  let text;
  try {
    text = readFileSync(path, 'utf8');
  } catch (err) {
    return { invalid: true, reason: `ScanReport 缺失或不可读: ${err.message}` };
  }
  let doc;
  try {
    doc = JSON.parse(text);
  } catch (err) {
    return { invalid: true, reason: `ScanReport 不可解析（非合法 JSON）: ${err.message}` };
  }
  if (!doc || typeof doc !== 'object' || !('project_model' in doc)) {
    return { invalid: true, reason: 'ScanReport 缺少 project_model 字段（应为 F2 产物，契约 schema_version=1）' };
  }
  if (doc.schema_version !== undefined && doc.schema_version !== 1) {
    return { invalid: true, reason: `ScanReport schema_version=${doc.schema_version} 不受支持（当前消费 v1）` };
  }
  return { doc };
}

/**
 * @returns {{verdict: 'pass'|'reject_fa'|'reject_unknown', reason: string}}
 */
export function check(report) {
  if (report.invalid) {
    return { verdict: 'reject_unknown', reason: report.reason };
  }
  const model = report.doc.project_model;
  if (model === 'stage') return { verdict: 'pass', reason: 'project_model=stage' };
  if (model === 'fa') {
    return { verdict: 'reject_fa', reason: 'FA 模型不支持，仅支持 Stage 模型' };
  }
  return { verdict: 'reject_unknown', reason: '工程模型无法判定（project_model=unknown），请先运行 F2 接口扫描' };
}

export function rejectMessage(gate) {
  return gate.verdict === 'reject_fa'
    ? 'FA 模型不支持，仅支持 Stage 模型'
    : '工程模型无法判定，请先运行 F2 接口扫描（arkuix-interface-scan）';
}
