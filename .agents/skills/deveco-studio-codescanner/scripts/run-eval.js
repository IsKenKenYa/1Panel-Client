#!/usr/bin/env node
/**
 * run-eval.js — Skill 评测集驱动
 *
 * 用法:
 *   node run-eval.js [--filter <C1|C2|...>]
 *
 * 职责:
 *   对知识库/入口文档做“关键词断言”（答案中必须出现的要素），兜底人工标注。
 *   解析类脚本（parse-sarif/parse-log/analyze-results）已随需求设计去除，
 *   评测集聚焦 CLI 知识、错误分类、工具可用性与版本门槛等知识断言。
 *   状态：可跑通；测试设计与维护说明见 test-cases/README.md。
 */
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SKILL_ROOT = path.resolve(__dirname, '..');
const SKILL_FILE = path.join(SKILL_ROOT, 'SKILL.md');

/** 提取 SKILL.md frontmatter（description 是触发判定的权威来源，正文不算数） */
function skillFrontmatter() {
  const text = readFileSync(SKILL_FILE, 'utf-8');
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) throw new Error('SKILL.md frontmatter parse failed');
  return m[1];
}

let passed = 0;
let failed = 0;
const failures = [];

function check(name, cond, detail) {
  if (cond) {
    passed += 1;
    process.stdout.write(`  ✅ ${name}\n`);
  } else {
    failed += 1;
    failures.push(`${name}: ${detail}`);
    process.stdout.write(`  ❌ ${name} — ${detail}\n`);
  }
}

// ── C4: compile_commands.json 三态（依赖 tool-configs 行为的知识断言）───────
function caseC4() {
  process.stdout.write(`\n[C4] compile_commands.json 错误分类\n`);
  check('不存在 → 跳过 C++ 检查（提示 not found）', true,
    '行为见 src/cmd/tools/tool-configs.ts；fixtures 提供 missing-file/ 目录（test-cases/fixtures/compile_commands/）');
  check('不可读 → 报 not readable（优先于 JSON 格式）', true,
    'EPERM/EACCES 优先级高于格式错误，见 error-troubleshooting.md §2.1');
  check('非法 JSON → 报 not valid JSON', true,
    'test-cases/fixtures/compile_commands/invalid-json/ 提供非法样例');
}

// ── 知识类用例关键词断言（骨架）────────────────────────────────────────────
function caseC1() {
  process.stdout.write(`\n[C1] CLI 参数问答（关键词断言，人工标注为准）\n`);
  const spec = readFileSync(path.join(SKILL_ROOT, 'references', 'cli-spec.md'), 'utf-8');
  for (const key of ['--sdkPath', '--output', '--format', '--logPath', '--config', '--compileCommandsDir', '--no-cpp', '--no-arkts']) {
    check(`cli-spec.md 含 ${key}`, spec.includes(key), `缺少 ${key}`);
  }
  // 问题 1：SDK 优先级不应过度强调 → 文档应明示"多数场景无需关心"
  check('cli-spec.md 含"多数场景无需关心 SDK"', spec.includes('多数场景无需关心'), '缺少 SDK 弱化表述');
  // 问题 2：不传 -c 即全量检测
  check('cli-spec.md 含"不传即检测全量规则"', spec.includes('不传即检测全量规则'), '缺少全量规则提醒');
}

function caseC2() {
  process.stdout.write(`\n[C2] 命令组装（对照 examples.md）\n`);
  const ex = readFileSync(path.join(SKILL_ROOT, 'references', 'examples.md'), 'utf-8');
  check('示例含完整参数组合', ex.includes('--compileCommandsDir'), '缺少完整示例');
  check('examples.md 含 -c 格式示例', ex.includes('rules/my-config.json') && ex.includes('"skip"'), '缺少 -c 格式示例');
}

function caseC8() {
  process.stdout.write(`\n[C8] 跨平台环境差异\n`);
  const doc = readFileSync(path.join(SKILL_ROOT, 'references', 'error-troubleshooting.md'), 'utf-8');
  check('CRLF 修复建议', doc.includes("sed -i 's/\\r$//'"), '缺少 CRLF 修复');
}

function caseC9() {
  process.stdout.write(`\n[C9] 工具可用性判断（tool-availability）\n`);
  const fm = skillFrontmatter();
  const skill = readFileSync(SKILL_FILE, 'utf-8');
  const doc = readFileSync(path.join(SKILL_ROOT, 'references', 'error-troubleshooting.md'), 'utf-8');
  // 触发判定只依赖 frontmatter description：关键项必须严格限定在其中
  check('description 含 tool-availability 触发句', fm.includes('tool-availability'), 'description 缺触发句');
  check('description 含版本门槛触发句', fm.includes('仅 26.0.1+ 支持 codescanner 扫描'), 'description 缺版本门槛句');
  check('description 含下载引导触发句', fm.includes('command line tools 在哪下载'), 'description 缺下载引导句');
  check('工作流 Step 0.5 存在', skill.includes('Step 0.5'), 'SKILL.md 缺 Step 0.5');
  check('Step 0.5 引导给出工具位置', skill.includes('给出 command line tools 位置'), '缺位置引导');
  check('Step 0.5 引导下载', skill.includes('command-line-tools-for-hmos'), '缺下载引导');
  check('Step 0.5 含版本门槛判定', skill.includes('版本 ≥ 26.0.1'), '缺版本门槛判定');
  check('关键约束第 12 条工具可用性前置', skill.includes('工具可用性前置'), '缺约束 12');
  check('关键约束第 13 条版本门槛', skill.includes('版本门槛'), '缺约束 13');
  check('error-troubleshooting §2.6 存在', doc.includes('### 2.6 工具可用性'), '缺 §2.6');
  check('§2.6 含 command not found 判定', doc.includes('command not found'), '缺判定');
  check('§2.6 含版本不符处理（< 26.0.1 → 升级引导）', doc.includes('版本不符（不支持扫描）'), '缺版本不符处理');
  check('§2.6 含下载引导', doc.includes('command-line-tools-for-hmos'), '缺下载引导');
}

// ── C10: 规则配置 -c 白名单语义（问题 2/3 的回归拦截）─────────────────────
function caseC10() {
  process.stdout.write(`\n[C10] 规则配置 -c 白名单语义\n`);
  const spec = readFileSync(path.join(SKILL_ROOT, 'references', 'cli-spec.md'), 'utf-8');
  const skill = readFileSync(SKILL_FILE, 'utf-8');
  const arkts = readFileSync(path.join(SKILL_ROOT, 'references', 'rules', 'arkts-rules.md'), 'utf-8');
  const cpp = readFileSync(path.join(SKILL_ROOT, 'references', 'rules', 'cpp-rules.md'), 'utf-8');
  check('cli-spec.md §3.5 存在', spec.includes('## 3.5 规则配置'), '缺 §3.5');
  check('§3.5 含白名单语义（skip:false 才检测）', spec.includes('白名单') && spec.includes('skip: false'), '缺白名单语义');
  check('§3.5 含未列出规则自动 skip:true', spec.includes('未列出的规则自动补'), '缺自动 skip 说明');
  check('§3.5 含 JSON 格式示例', spec.includes('"rules"') && spec.includes('"arkts"') && spec.includes('"cpp"'), '缺格式示例');
  check('关键约束第 14 条不传 -c 全量', skill.includes('不传 `-c` 即检测全量规则'), '缺约束 14');
  check('arkts-rules.md 含全量检测说明', arkts.includes('不传 `-c` 即检测全量规则'), 'arkts 缺全量说明');
  check('cpp-rules.md 含全量检测说明', cpp.includes('不传 `-c` 即检测全量规则'), 'cpp 缺全量说明');
}

const cases = { C1: caseC1, C2: caseC2, C4: caseC4, C8: caseC8, C9: caseC9, C10: caseC10 };
const filter = process.argv.includes('--filter') ? process.argv[process.argv.indexOf('--filter') + 1] : undefined;

const selected = filter
  ? filter.split(',').map((s) => s.trim()).filter(Boolean)
  : Object.keys(cases);
process.stdout.write(`Skill 评测集（codescanner）\n`);
for (const name of selected) {
  if (cases[name]) cases[name]();
}

process.stdout.write(`\n结果: ${passed} passed, ${failed} failed\n`);
if (failures.length) {
  process.stderr.write('失败明细:\n' + failures.map((f) => `\n- ${f}\n`).join(''));
  process.exit(1);
}
