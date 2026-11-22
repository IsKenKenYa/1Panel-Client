#!/usr/bin/env node
/**
 * ArkUI 内存测试用例构造指南生成器（US-2 / AC-2.1~2.6）
 *
 * 消费热点分析 schema，产出应用内存测试用例构造指南（Markdown），含：
 *  - 三类测试维度：泄漏检测 / 回收验证 / 压力测试（AC-2.2）
 *  - 热点→维度多对多映射（AC-2.3）
 *  - 真机操作步骤（应用侧，AC-2.1 / AC-2.4 不生成框架用例）
 *  - 不提供自动执行脚本，开发者据指南自行测试获取 dump（AC-2.5）
 *  - schema 不可用时降级为通用版指南（AC-2.6）
 *
 * 用法:
 *   node generate-test-guide.mjs --schema <arkui-memory-schema.json> --output <guide.md>
 *   node generate-test-guide.mjs --output <guide.md>           # 无 schema → 通用版
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { resolve, dirname, basename, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ─── 热点类型 → 测试维度（多对多）──────────────────────────────
// 维度：leak=泄漏检测, recycle=回收验证, stress=压力测试
const HOTSPOT_TO_DIMENSIONS = {
  invisible_page: ['leak', 'stress'],
  tabs_cache_not_released: ['recycle', 'leak'],
  tabs_preload_invisible: ['recycle', 'leak'],
  tabs_animation_midpage: ['recycle'],
  list_non_lazy: ['stress', 'leak'],
  list_cachedcount_too_large: ['stress', 'recycle'],
  layout_redundant_nesting: ['stress'],
  nav_stack_too_deep: ['leak', 'stress'],
  cache_pool_not_released: ['recycle', 'leak'],
  xcomponent_not_released: ['leak', 'recycle'],
  large_images_excessive: ['stress', 'leak'],
  imperative_node_cached: ['recycle', 'leak'],
  canvas_gradient: ['stress'],
  image_animator_excessive: ['stress'],
  video_resident: ['leak', 'stress'],
  detached_cache_excessive: ['recycle', 'leak'],
  pixelmap_not_released: ['leak', 'recycle'],
  arkweb_excessive: ['stress', 'recycle'],
  builder_node_dispose_flow: ['leak', 'recycle'],
  cache_pool_opt_not_set: ['recycle', 'leak'],
};

const DIM_LABEL = { leak: '泄漏检测', recycle: '回收验证', stress: '压力测试' };

// 热点类型中文标签
const HOTSPOT_LABELS = {
  invisible_page: '不可见页面冗余加载', tabs_cache_not_released: 'Tabs 缓存数量过多',
  tabs_preload_invisible: '预加载不可见 Tab 页面', tabs_animation_midpage: '冗余加载 Tabs 中间页面',
  list_non_lazy: '长列表滚动不懒加载', list_cachedcount_too_large: '滚动预加载 CachedCount 不合理',
  layout_redundant_nesting: '布局写法冗余低效', nav_stack_too_deep: '页面栈过深',
  cache_pool_not_released: '缓存池/复用池未释放', xcomponent_not_released: 'XComponent 未释放',
  large_images_excessive: 'Image 不合理超大图', imperative_node_cached: '命令式节点缓存',
  canvas_gradient: 'Canvas 替代原生渐变', image_animator_excessive: 'ImageAnimator 帧集过量',
  video_resident: 'Video 组件常驻', detached_cache_excessive: '游离缓存过多',
  pixelmap_not_released: 'PixelMap 未释放', arkweb_excessive: 'ArkWeb 预渲染/预热过多',
  builder_node_dispose_flow: 'BuilderNode 销毁流程不完整',
  cache_pool_opt_not_set: '缓存池清空使能未设置',
};

// ─── 三个测试维度的通用操作范式（应用侧，真机，无自动脚本）──────────
const DIMENSION_GUIDES = {
  leak: {
    name: '泄漏检测',
    purpose: '验证页面/组件离开后内存是否被正确回收，定位"只增不减"的泄漏点。',
    steps: [
      '1. 冷启动应用，进入待测页面前的基线状态，用 ArkUI Inspector 抓首帧 dump（记为 D0）。',
      '2. 进入待测页面，执行该页面的典型操作（滚动/点击/加载内容等）。',
      '3. 返回上级页面或退出待测页面（触发 aboutToDisappear / 页面出栈）。',
      '4. 重复步骤 2-3 共 5~10 次（模拟用户反复进出）。',
      '5. 在最后一次返回后，再次用 ArkUI Inspector 抓 dump（记为 Dn）。',
      '6. 用 ArkUIDumpViewer 打开 D0 与 Dn 对比：若 Dn 的总节点数 / 总内存 / 游离缓存根数量显著高于 D0，且未回落，判定为泄漏。',
      '7. 对比 D0→Dn 的增长节点 tag 分布，定位是哪类组件泄漏（如 Image / XComponent / BuilderNode）。'
    ],
    verify: 'Dn 总内存 ≈ D0（波动 < 10% 视为正常回收）；游离缓存根数量不持续增长。',
  },
  recycle: {
    name: '回收验证',
    purpose: '验证缓存池/复用池/TabContent 等在场景切换后是否被释放，而非常驻。',
    steps: [
      '1. 进入含缓存/复用场景的页面（如 Tabs 多页签 / LazyForEach 长列表 / Reusable 复用组件）。',
      '2. 触发缓存产生：切换 Tab / 滚动列表加载多屏 / 创建复用组件实例。',
      '3. 用 ArkUI Inspector 抓 dump（记为 D1，缓存峰值）。',
      '4. 离开该场景（切到其他 Tab / 返回上级 / 退出页面），停留 3~5 秒等 GC。',
      '5. 再次抓 dump（记为 D2）。',
      '6. 用 ArkUIDumpViewer 的"游离根"面板对比 D1 vs D2：检查 LazyForEach缓存 / Repeat缓存 / Reusable缓存 / 命令式BuilderNode 等游离根数量是否减少或清零。',
      '7. 若游离根数量未减少，检查对应组件是否在 aboutToDisappear / onDestroy 中调用 dispose / release / clear。'
    ],
    verify: 'D2 游离缓存根数量 < D1（理想为 0）；缓存池总内存回落。',
  },
  stress: {
    name: '压力测试',
    purpose: '在极限操作下观察内存峰值与节点膨胀，定位内存劣化的触发条件。',
    steps: [
      '1. 进入待测场景（大图列表 / 深层导航 / 多 Web / Canvas 全屏等）。',
      '2. 执行极限操作：快速连续滚动（>20 屏）/ 快速切换 Tab（>10 次）/ 连续 push 页面到栈深 >10 / 加载多张大图。',
      '3. 在内存峰值时刻（操作进行中或刚结束）用 ArkUI Inspector 抓 dump（记为 Dpeak）。',
      '4. 停止操作，等待 5~10 秒，再抓一次 dump（记为 Didle）。',
      '5. 用 ArkUIDumpViewer 对比 Dpeak vs Didle：查看峰值内存、节点总数、关键组件（Image/Canvas/XComponent/Web）数量。',
      '6. 若 Dpeak 远高于正常使用内存且 Didle 未回落，定位峰值来源（如非懒加载列表的离屏节点、未释放的大图、常驻 Video）。'
    ],
    verify: 'Dpeak 峰值在可接受范围；Didle 回落到接近基线；无异常节点膨胀。',
  },
};

// ─── 按热点类型给出针对性操作建议（应用侧）──────────────────────
const HOTSPOT_TEST_TIPS = {
  invisible_page: '重点操作：进入含 visibility(Hidden) 或不可见 Tab 的页面，停留后返回，抓 dump 看不可见子树是否仍常驻（VisibleAndActive=0 但后代多/内存大）。',
  tabs_cache_not_released: '重点操作：在多 TabContent 的 Tabs 页面来回切换 5+ 次，退出页面后抓 dump，检查 TabContent 子树是否作为游离缓存残留。',
  tabs_preload_invisible: '重点操作：进入 Tabs 页面，检查当前可见页签之外的 TabContent 是否已被预加载构建（有后代节点）。',
  tabs_animation_midpage: '重点操作：从首 Tab 滑动到末 Tab（经过中间页），抓 dump 检查中间 TabContent 是否被冗余构建。',
  list_non_lazy: '重点操作：在含 List/Grid 的长列表快速滚动 20+ 屏，抓 dump 检查离屏节点是否仍在树中（非懒加载会保留全部节点）。',
  list_cachedcount_too_large: '重点操作：滚动 LazyForEach 列表，抓 dump 看 LazyForEach缓存/Repeat缓存 游离根数量是否过多（cachedCount 过大）。',
  layout_redundant_nesting: '重点操作：进入深层嵌套页面，抓 dump 查看 maxDepth 与连续容器嵌套层数。',
  nav_stack_too_deep: '重点操作：连续 push NavDestination 10+ 次（不 pop），抓 dump 看 NavDestination 数量与页面栈内存。',
  cache_pool_not_released: '重点操作：触发 Reusable/复用池场景后离开页面，抓 dump 检查 Reusable缓存 游离根是否释放。',
  xcomponent_not_released: '重点操作：进入含 XComponent 的页面后返回，抓 dump 检查 XComponent 是否作为游离节点残留（IsOnMainTree:0 / IsFrameDisappear:1）。',
  large_images_excessive: '重点操作：加载含大图的列表/网格，抓 dump 检查 Image 的 rawImageSize 与 autoResize 状态，估算 DMA 浪费。',
  imperative_node_cached: '重点操作：触发 BuilderNode/NodeController 创建后离开，抓 dump 检查命令式节点游离根是否释放。',
  canvas_gradient: '重点操作：进入含 Canvas 渐变背景的页面，抓 dump 查看 Canvas FrameRect 像素尺寸与 DMA 占用。',
  image_animator_excessive: '重点操作：进入含 ImageAnimator 的页面，抓 dump 检查其下 Image 子节点数量与帧集内存。',
  video_resident: '重点操作：播放 Video 后离开页面，抓 dump 检查 Video 是否常驻（controller 未 stop/destroy）。',
  detached_cache_excessive: '重点操作：正常使用应用后抓 dump，查看游离缓存根总数是否过多（>100）。',
  pixelmap_not_released: '重点操作：触发 PixelMap 创建（decodeImageFromData/AAImage）后离开，抓 dump 检查 PixelMap 是否释放。',
  arkweb_excessive: '重点操作：进入含多个 Web 组件的页面，抓 dump 检查 Web 节点数量（含游离 Web）。',
  builder_node_dispose_flow: '重点操作：进入含 BuilderNode 命令式节点的页面后返回，抓 dump 检查命令式BuilderNode游离根是否释放；检查源码是否按3步销毁（NodeContainer(undefined)→update(undefined)→dispose()）。',
  cache_pool_opt_not_set: '重点操作：进入含 Repeat/LazyForEach/Reusable 组件的页面后返回，抓 dump 检查缓存池游离根是否释放；检查 MemOpt/ReusableMemOpt/RepeatMemOpt 是否启用。',
};

// ─── 导航结构提取（从源码提取页面+按钮+跳转关系，生成具体操作步骤）──────
// 扫描 .ets 文件：@Entry/@Component struct → 页面名；Button('text') → 按钮；NavPathStack.push/router.pushUrl → 跳转目标
function listEtsFiles(dir) {
  const out = [];
  (function walk(d) {
    let entries;
    try { entries = readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const ent of entries) {
      const p = join(d, ent.name);
      if (ent.isDirectory()) { if (ent.name === 'node_modules' || ent.name === '.git') continue; walk(p); }
      else if (ent.isFile() && ent.name.endsWith('.ets')) out.push(p);
    }
  })(dir);
  return out;
}

function extractNavigation(sourceDir) {
  if (!sourceDir || !existsSync(sourceDir)) return null;
  const files = listEtsFiles(sourceDir);
  const pages = []; // {file, name, isEntry, buttons:[], navs:[{target, button}]}
  for (const file of files) {
    let content;
    try { content = readFileSync(file, 'utf8'); } catch { continue; }
    // 页面名：@Entry @Component struct XXX 或 @Component struct XXX
    const structM = content.match(/@(?:Entry\s+)?Component\s+struct\s+(\w+)/);
    const name = structM ? structM[1] : basename(file, '.ets');
    const isEntry = /@Entry/.test(content);
    // 按钮：Button('text') / Button("text")
    const buttons = [...content.matchAll(/Button\s*\(\s*['"]([^'"]{1,40})['"]/g)].map(m => m[1]);
    // TabContent 标签：TabContent().tabBar('label')
    const tabs = [...content.matchAll(/tabBar\s*\(\s*['"]([^'"]{1,40})['"]/g)].map(m => m[1]);
    // 跳转目标：NavPathStack.push('XXX') / push({name:'XXX'}) / router.pushUrl({url:'pages/XXX'}) / pushPath('XXX')
    const navs = [];
    for (const m of content.matchAll(/\.push(?:Path)?\s*\(\s*['"]([^'"]+)['"]/g)) navs.push({ target: m[1], button: null });
    for (const m of content.matchAll(/\.push(?:Path)?\s*\(\s*{\s*name\s*:\s*['"]([^'"]+)['"]/g)) navs.push({ target: m[1], button: null });
    for (const m of content.matchAll(/pushUrl\s*\(\s*{?\s*url\s*:\s*['"](?:[^'"]*\/)?([^'"/]+)['"]/g)) navs.push({ target: m[1], button: null });
    // 尝试关联按钮与跳转：Button('text')...onClick(...push('target'))
    for (let i = 0; i < buttons.length; i++) {
      // 在该 Button 之后 200 字符内找 push 目标
      const btnIdx = content.indexOf(`Button('${buttons[i]}'`);
      if (btnIdx < 0) continue;
      const slice = content.slice(btnIdx, btnIdx + 300);
      const tM = slice.match(/\.push(?:Path)?\s*\(\s*['"]([^'"]+)['"]/) || slice.match(/pushUrl\s*\(\s*{?\s*url\s*:\s*['"](?:[^'"]*\/)?([^'"/]+)['"]/);
      if (tM) {
        const t = tM[1];
        // 标记该 nav 的 button
        const navIdx = navs.findIndex(n => n.target === t && !n.button);
        if (navIdx >= 0) navs[navIdx].button = buttons[i];
      }
    }
    pages.push({ file, name, isEntry, buttons, tabs, navs });
  }
  // 入口页
  const entryPage = pages.find(p => p.isEntry) || pages.find(p => p.name === 'Index') || pages[0];
  // 构建导航图：pageName → [{target, button}]
  const graph = new Map();
  for (const p of pages) {
    for (const n of p.navs) {
      if (!graph.has(p.name)) graph.set(p.name, []);
      graph.get(p.name).push({ target: n.target, button: n.button });
    }
  }
  // BFS：从入口到各页面的路径
  function findPath(targetName) {
    if (!entryPage) return [];
    if (entryPage.name === targetName) return [];
    const visited = new Set([entryPage.name]);
    const queue = [[entryPage.name, []]];
    while (queue.length) {
      const [cur, path] = queue.shift();
      const edges = graph.get(cur) || [];
      for (const e of edges) {
        if (e.target === targetName) return [...path, { from: cur, to: e.target, button: e.button }];
        if (!visited.has(e.target)) {
          visited.add(e.target);
          queue.push([e.target, [...path, { from: cur, to: e.target, button: e.button }]]);
        }
      }
    }
    return []; // 不可达
  }
  return { pages, entryPage, findPath };
}

// 根据热点 finding 的 file 找其所在页面
function findPageForFile(file, navInfo) {
  if (!navInfo) return null;
  const abs = resolve(file);
  return navInfo.pages.find(p => {
    const pAbs = resolve(p.file);
    return pAbs === abs || basename(pAbs) === basename(abs);
  }) || navInfo.pages.find(p => p.name === basename(file, '.ets'));
}

// 格式化导航路径为可读步骤
function formatNavPath(path, entryPage) {
  if (!path || path.length === 0) return entryPage ? `入口页 ${entryPage.name}（即该页面）` : '';
  const steps = [];
  let cur = entryPage ? entryPage.name : path[0].from;
  steps.push(`入口页 ${cur}`);
  for (const edge of path) {
    const btn = edge.button ? `点击「${edge.button}」按钮` : `通过导航跳转`;
    steps.push(`${btn} → 进入 ${edge.to} 页面`);
  }
  return steps.join(' → ');
}

function generateGuide(schemaPath, sourceDir) {
  const parts = [];
  let findings = [];
  let schemaInfo = null;
  // 导航结构（从源码提取页面+按钮+跳转关系，用于生成具体操作步骤）
  const navInfo = extractNavigation(sourceDir);
  if (navInfo) console.log(`✅ 导航结构提取：${navInfo.pages.length} 页面，入口页 ${navInfo.entryPage?.name || '未识别'}`);

  if (schemaPath && existsSync(schemaPath)) {
    try {
      const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));
      findings = schema.findings || [];
      schemaInfo = {
        total: findings.length,
        bySev: { high: 0, medium: 0, low: 0 },
        inputs: schema.analysis_inputs || [],
      };
      for (const f of findings) schemaInfo.bySev[f.severity] = (schemaInfo.bySev[f.severity] || 0) + 1;
    } catch (e) {
      console.warn(`⚠ schema 解析失败，降级为通用指南: ${e.message}`);
    }
  }

  // ─── 标题与概述 ───
  parts.push('# ArkUI 应用内存测试用例构造指南');
  parts.push('');
  parts.push(`> 生成时间：${new Date().toISOString()}`);
  if (schemaInfo) {
    parts.push(`> 消费 schema：${schemaPath}（${schemaInfo.total} 条热点发现：🔴${schemaInfo.bySev.high} / 🟡${schemaInfo.bySev.medium} / 🟢${schemaInfo.bySev.low}）`);
  } else {
    parts.push('> 未提供有效 schema → 通用版指南（基于预置模板，不含具体热点位置标注）');
  }
  parts.push('');
  parts.push('> 本指南面向**应用侧**测试，不生成 ArkUI 框架测试用例，不提供自动执行脚本。开发者据指南在真机操作并用 ArkUI Inspector 抓取 dump，再交 ArkUIDumpViewer 分析，形成「静态分析→测试→dump→可视化」闭环。');
  parts.push('');

  // ─── 三类测试维度 ───
  parts.push('## 一、测试维度');
  parts.push('');
  parts.push('覆盖三类维度，每条热点可对应一个或多个维度（多对多映射）。');
  parts.push('');
  for (const key of ['leak', 'recycle', 'stress']) {
    const d = DIMENSION_GUIDES[key];
    parts.push(`### ${d.name}`);
    parts.push('');
    parts.push(`**目的**：${d.purpose}`);
    parts.push('');
    parts.push('**操作步骤**（真机，应用侧）：');
    parts.push('');
    for (const s of d.steps) parts.push(s);
    parts.push('');
    parts.push(`**判定标准**：${d.verify}`);
    parts.push('');
  }

  // ─── 热点→维度映射 ───
  parts.push('## 二、热点 → 测试维度映射（多对多）');
  parts.push('');
  parts.push('| 热点类型 | 中文名称 | 建议测试维度 |');
  parts.push('|----------|----------|--------------|');
  const typesInSchema = schemaInfo ? [...new Set(findings.map(f => f.hotspot_type))] : Object.keys(HOTSPOT_TO_DIMENSIONS);
  for (const t of typesInSchema) {
    const dims = (HOTSPOT_TO_DIMENSIONS[t] || ['leak', 'stress']).map(k => DIM_LABEL[k]).join('、');
    parts.push(`| \`${t}\` | ${HOTSPOT_LABELS[t] || t} | ${dims} |`);
  }
  parts.push('');

  // ─── 针对性构造用例（基于 schema findings）───
  if (schemaInfo && findings.length > 0) {
    parts.push('## 三、针对性构造用例（基于热点分析结果）');
    parts.push('');
    parts.push('> 以下用例基于热点分析 schema 的具体发现，建议按严重度（high→medium→low）优先构造。');
    parts.push('');
    // 按严重度排序
    const sevOrder = { high: 0, medium: 1, low: 2 };
    const sorted = [...findings].sort((a, b) => (sevOrder[a.severity] ?? 3) - (sevOrder[b.severity] ?? 3));
    let idx = 1;
    for (const f of sorted) {
      const dims = (HOTSPOT_TO_DIMENSIONS[f.hotspot_type] || ['leak']).map(k => DIM_LABEL[k]).join('、');
      const sevIcon = f.severity === 'high' ? '🔴' : f.severity === 'medium' ? '🟡' : '🟢';
      parts.push(`### 用例 ${idx}. ${sevIcon} ${HOTSPOT_LABELS[f.hotspot_type] || f.hotspot_type}`);
      parts.push('');
      parts.push(`- **热点类型**：\`${f.hotspot_type}\`（${f.severity}）`);
      parts.push(`- **位置**：${f.location || f.file || '-'}`);
      // 具体操作步骤：所在页面 + 到达路径 + 页面内按钮/页签
      let page = null, navPath = [];
      if (navInfo) {
        page = findPageForFile(f.file, navInfo);
        if (page) {
          navPath = navInfo.findPath(page.name);
          parts.push(`- **所在页面**：${page.name}${page.isEntry ? '（入口页）' : ''}`);
          if (navPath.length > 0) parts.push(`- **到达路径**：${formatNavPath(navPath, navInfo.entryPage)}`);
          if (page.buttons && page.buttons.length > 0) parts.push(`- **页面内可操作按钮**：${page.buttons.slice(0, 6).map(b => `「${b}」`).join('、')}`);
          if (page.tabs && page.tabs.length > 0) parts.push(`- **页签**：${page.tabs.slice(0, 6).map(t => `「${t}」`).join('、')}`);
        }
      }
      parts.push(`- **问题描述**：${f.description || '-'}`);
      parts.push(`- **建议测试维度**：${dims}`);
      parts.push(`- **针对性操作建议**：${HOTSPOT_TEST_TIPS[f.hotspot_type] || '参照上述维度的通用操作步骤。'}`);
      // 具体真机操作步骤（结合页面+导航）
      if (page) {
        parts.push(`- **真机操作步骤**：`);
        parts.push(`  1. 冷启动应用，停留在入口页 ${navInfo.entryPage?.name || ''}。`);
        if (navPath.length > 0) parts.push(`  2. 按到达路径操作：${formatNavPath(navPath, navInfo.entryPage)}。`);
        else if (!page.isEntry) parts.push(`  2. 导航到 ${page.name} 页面。`);
        else parts.push(`  2. 停留在入口页 ${page.name}。`);
        parts.push(`  3. 在 ${page.name} 页面触发热点场景（${HOTSPOT_TEST_TIPS[f.hotspot_type]?.replace(/^重点操作：/, '') || '执行典型操作'}）。`);
        parts.push(`  4. 按「${dims}」维度执行（见第一节维度操作步骤）。`);
        parts.push(`  5. 用 ArkUI Inspector 抓 dump，交 ArkUIDumpViewer 对比分析。`);
      }
      parts.push('');
      idx++;
    }
  } else {
    parts.push('## 三、针对性构造用例');
    parts.push('');
    parts.push('> 未提供有效热点 schema，以下为通用建议。建议先用本 skill 分析源码/dump 产出 schema，再据具体热点构造针对性用例。');
    parts.push('');
    parts.push('**通用建议**：');
    parts.push('');
    parts.push('1. 对应用核心页面逐个执行「泄漏检测」流程（反复进出 5-10 次，对比 dump）。');
    parts.push('2. 对含 Tabs / 长列表 / 复用组件的页面执行「回收验证」流程。');
    parts.push('3. 对大图 / 深层导航 / 多 Web 场景执行「压力测试」流程。');
    parts.push('');
  }

  // ─── 闭环指引 ───
  parts.push('## 四、闭环：dump → 可视化分析');
  parts.push('');
  parts.push('据上述指南在真机测试并抓取 dump 后，将 dump 交给 ArkUIDumpViewer 分析，形成闭环：');
  parts.push('');
  parts.push('```');
  parts.push('① 本 skill 分析（源码 + dump）→ 热点报告 + schema + 本构造指南');
  parts.push('② 开发者据本指南在真机操作 → 用 ArkUI Inspector 抓 dump');
  parts.push('③ dump 交给 ArkUIDumpViewer → 交互式 HTML 可视化（组件树 + 内存热力 + 热点高亮）');
  parts.push('④ 对比修复前/后 dump 的节点数与内存，量化优化效果');
  parts.push('```');
  parts.push('');
  parts.push('> **不提供自动执行脚本**：本指南仅给出操作步骤，开发者需在真机手动操作并抓取 dump。');
  parts.push('');

  return parts.join('\n');
}

function main() {
  const args = process.argv.slice(2);
  let schemaPath = null, outputPath = null, sourceDir = null;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--schema' && args[i + 1]) schemaPath = resolve(args[++i]);
    else if (args[i] === '--output' && args[i + 1]) outputPath = resolve(args[++i]);
    else if (args[i] === '--source-dir' && args[i + 1]) sourceDir = resolve(args[++i]);
  }
  if (!outputPath) {
    console.error('用法: node generate-test-guide.mjs --schema <path> --output <guide.md> [--source-dir <dir>]');
    process.exit(1);
  }
  const guide = generateGuide(schemaPath, sourceDir);
  writeFileSync(outputPath, guide, 'utf8');
  console.log(`✅ 内存测试用例构造指南: ${outputPath}`);
}

main();
