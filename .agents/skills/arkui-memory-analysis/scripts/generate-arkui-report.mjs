#!/usr/bin/env node
/**
 * ArkUI 内存分析报告生成器
 *
 * 消费 dump 分析和/或源码分析的 schema 输出，
 * 生成 Markdown 格式的分析报告（含问题诊断、修改建议、严重度分级）。
 *
 * 用法:
 *   node generate-arkui-report.mjs --dump-schema <path> [--source-schema <path>] --output <path>
 *   node generate-arkui-report.mjs --source-schema <path> --output <path>
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, cpSync, readdirSync, statSync, unlinkSync } from 'node:fs';
import { resolve, join, basename, dirname, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

// ─── 严重度图标 ─────────────────────────────────────────────────

const SEVERITY_ICON = {
  high: '🔴',
  medium: '🟡',
  low: '🟢',
};

const SEVERITY_LABEL = {
  high: '高',
  medium: '中',
  low: '低',
};

// ─── 热点类型中文映射 ───────────────────────────────────────────

const HOTSPOT_LABELS = {
  invisible_page: '不可见页面冗余加载',
  tabs_cache_not_released: 'Tabs 缓存数量过多',
  tabs_preload_invisible: '预加载不可见 Tab 页面',
  tabs_animation_midpage: '冗余加载 Tabs 中间页面',
  list_non_lazy: '长列表滚动不懒加载',
  list_cachedcount_too_large: '滚动预加载 CachedCount 不合理',
  layout_redundant_nesting: '布局写法冗余低效',
  nav_stack_too_deep: '页面栈过深',
  cache_pool_not_released: '缓存池/复用池未释放',
  xcomponent_not_released: 'XComponent 未释放',
  large_images_excessive: 'Image 不合理超大图',
  imperative_node_cached: '命令式节点缓存',
  canvas_gradient: 'Canvas 替代原生渐变',
  image_animator_excessive: 'ImageAnimator 帧集过量',
  video_resident: 'Video 组件常驻',
  detached_cache_excessive: '游离缓存过多',
  pixelmap_not_released: 'PixelMap 未释放',
  arkweb_excessive: 'ArkWeb 预渲染/预热过多',
  builder_node_dispose_flow: 'BuilderNode 销毁流程不完整',
  cache_pool_opt_not_set: '缓存池清空使能未设置',
};

// ─── 可视化工具查看建议 ─────────────────────────────────────────

const VIZ_TIPS = {
  invisible_page: '在 ArkUIDumpViewer 中打开「隐藏态」视图，自动展开通往每个 🟠 在树隐藏节点的路径，直观查看该不可见子树的层级和内存占用；点击节点在详情面板查看 `VisibleAndActive=0` 字段确认',
  tabs_cache_not_released: '在 ArkUIDumpViewer 中点击工具栏「游离根」开关，查看 Tabs 切换后是否有大量 TabContent 子树残留；切换数据源对比不同页签状态下的组件树节点数变化',
  tabs_preload_invisible: '在 ArkUIDumpViewer 中搜索 `TabContent`，查看当前可见页签之外的 TabContent 子树是否已构建；对比「游离根」面板中缓存根的数量',
  list_non_lazy: '在 ArkUIDumpViewer 中搜索 `List`，查看其子节点数是否远超屏幕可见行数；滚动后重新查看，离屏节点是否仍在树中',
  list_cachedcount_too_large: '在 ArkUIDumpViewer 中打开「游离根」开关，查看 LazyForEach缓存 / Repeat缓存 类型的游离根节点数，数值过大说明 cachedCount 过高',
  layout_redundant_nesting: '在 ArkUIDumpViewer 中点击树中深层节点，查看详情面板的 `Depth` 值；观察是否存在连续 Stack/Column/Row 同类型节点无意义包裹',
  canvas_gradient: '在 ArkUIDumpViewer 中搜索 `Canvas`，在布局视图（X 光）中查看其 `FrameRect` 像素尺寸；内存热力叠加会显示该节点的 DMA 占用',
  image_animator_excessive: '在 ArkUIDumpViewer 中搜索 `ImageAnimator`，展开其子节点查看 Image 数量和 `rawImageSize`；内存热力叠加显示该子树的总 DMA',
  video_resident: '在 ArkUIDumpViewer 中搜索 `Video`，在布局视图中确认其位置和尺寸；查看详情面板的 `FrameRect`',
  large_images_excessive: '在 ArkUIDumpViewer 中搜索 `Image`，内存热力叠加会按量级着色，红色高亮节点即大图；在详情面板查看 `rawImageSize` 确认像素尺寸',
  detached_cache_excessive: '在 ArkUIDumpViewer 中点击工具栏「游离根」开关，查看与 root 同层的顶层树数量和类型（LazyForEach缓存/Repeat缓存/Reusable缓存），各根的节点数',
};

function getVisualizationTip(hotspotType) {
  return VIZ_TIPS[hotspotType] || null;
}

// ─── 报告生成 ───────────────────────────────────────────────────

function generateReport(schemas) {
  const parts = [];

  // ─── 标题 ───
  parts.push('# ArkUI 内存热点分析报告');
  parts.push('');
  parts.push(`> 生成时间：${new Date().toISOString()}`);
  parts.push(`> 分析输入：${schemas.map(s => s.analysis_type === 'dump' ? `Dump 文件 (${s.input_file || s.input_path})` : `源码 (${s.input_path})`).join(' + ')}`);
  parts.push('');

  // ─── 汇总统计 ───
  const allFindings = schemas.flatMap(s => s.findings || []);
  const totalHigh = allFindings.filter(f => f.severity === 'high').length;
  const totalMedium = allFindings.filter(f => f.severity === 'medium').length;
  const totalLow = allFindings.filter(f => f.severity === 'low').length;

  parts.push('## 一、分析汇总');
  parts.push('');
  parts.push('| 维度 | 数值 |');
  parts.push('|------|------|');
  for (const s of schemas) {
    if (s.analysis_type === 'dump') {
      parts.push(`| 分析类型 | Dump 文件分析 |`);
      parts.push(`| 节点总数 | ${s.stats?.node_count || '-'} |`);
      parts.push(`| 最大深度 | ${s.stats?.max_depth || '-'} |`);
      parts.push(`| 组件类型数 | ${s.stats?.tag_types || '-'} |`);
    } else {
      parts.push(`| 分析类型 | 源码静态分析 |`);
      parts.push(`| 扫描文件数 | ${s.stats?.files_scanned || '-'} |`);
    }
  }
  parts.push(`| 发现问题总数 | ${allFindings.length} |`);
  parts.push(`| 🔴 高严重度 | ${totalHigh} |`);
  parts.push(`| 🟡 中严重度 | ${totalMedium} |`);
  parts.push(`| 🟢 低严重度 | ${totalLow} |`);
  parts.push('');

  // ─── ArkUIDumpViewer 可视化工具推荐 ───
  const hasDumpFindings = schemas.some(s => s.analysis_type === 'dump' && (s.findings || []).length > 0);
  if (hasDumpFindings) {
    parts.push('## 二、ArkUI 内存可视化工具（推荐）');
    parts.push('');
    parts.push('> 本报告的 dump 侧分析基于组件树结构做定性判断。要查看**完整的交互式内存可视化**，强烈推荐使用 **ArkUIDumpViewer** 工具。');
    parts.push('');
    parts.push('### 工具简介');
    parts.push('');
    parts.push('ArkUIDumpViewer 将 ArkUI inspector dump 解析为**自包含、可交互的离线 HTML**（SVG 组件树 + 布局视图），无需联网，双击即可打开。');
    parts.push('');
    parts.push('### 核心能力');
    parts.push('');
    parts.push('| 功能 | 说明 | 与本报告热点的关系 |');
    parts.push('|------|------|---------------------|');
    parts.push('| **树视图** | 圆形节点 + Reingold–Tilford 紧凑布局，按节点状态着色（🟢在树显示 / 🟠在树隐藏 / ⚪️游离） | 直观查看不可见页面（H-01）、Tabs 缓存（H-02）、游离缓存根 |');
    parts.push('| **内存热力叠加** | 每个节点显示自身 + 全部子孙的总内存（基础 native heap + 图形 DMA），按量级热度着色 | 定位 ImageAnimator 帧集（H-09）、大图 DMA（H-08 Canvas / 大图）的内存来源 |');
    parts.push('| **隐藏态默认视图** | 自动展开通往每个「在树隐藏」节点的路径、折叠纯显示分支 | 直接定位不可见页面（H-01）的隐藏子树位置和层级 |');
    parts.push('| **布局视图（X 光）** | 用每个节点的 `FrameRect` 真实坐标画矩形叠在设备框上 | 查看全屏 Canvas（H-08）的实际像素尺寸、Video 组件（H-11）位置 |');
    parts.push('| **游离根开关** | 一键显示与 root 同层的其它顶层树（LazyForEach 缓存/Repeat 缓存/Reusable 缓存） | 检查缓存池不释放（H-02/H-06）的游离缓存根数量和规模 |');
    parts.push('| **搜索过滤** | 按标签 / ID / 文本 / compid / 组件名过滤，命中高亮并缩放 | 快速定位 TabContent / Canvas / Video / ImageAnimator 等特定组件 |');
    parts.push('| **详情面板** | 从 root 到节点的可点击路径 + 关键字段 + **完整原始属性** | 查看节点的 `VisibleAndActive` / `cachedCount` / `rawImageSize` 等原始字段 |');
    parts.push('| **骨架 + 聚合** | 7000+ 节点的超大树自动精简为可读规模 | 面对真实应用（上千节点）不会卡死，关键容器仍可见 |');
    parts.push('');
    parts.push('### 快速使用');
    parts.push('');
    parts.push('```bash');
    parts.push('# 1. 将 dump 文件放入 dumps/ 目录（可按应用建子目录）');
    parts.push('#    例如：dumps/哔哩哔哩/B站.dump');
    parts.push('');
    parts.push('# 2. 生成内存基线 + 构建可视化 HTML');
    parts.push('npm run all          # = 生成 memory.csv + 构建 HTML');
    parts.push('');
    parts.push('# 3. 或只重新构建（已有 memory.csv）');
    parts.push('npm run build');
    parts.push('');
    parts.push('# 4. 打开产物（浏览器双击或起静态服务）');
    parts.push('#    dumps_result_<日期>/index.html');
    parts.push('python3 -m http.server 8917 --directory dumps_result_latest');
    parts.push('#    → 浏览器访问 http://localhost:8917');
    parts.push('```');
    parts.push('');
    parts.push('### 使用建议');
    parts.push('');
    parts.push('1. **先看本报告**了解有哪些热点问题及严重度排序');
    parts.push('2. **再用可视化工具**在 SVG 树上定位每个热点的具体位置，查看节点详情和内存数据');
    parts.push('3. **修复代码后**重新获取 dump，用可视化工具对比验证节点数和内存的变化');
    parts.push('');
    parts.push('> 💡 **提示**：可视化工具的「隐藏态」视图是排查不可见页面（H-01）和 Tabs 缓存（H-02）的最佳入口；「游离根」开关是排查缓存池（H-02/H-06）的最佳入口；「内存热力」叠加是排查 ImageAnimator（H-09）和 Canvas（H-08）DMA 内存的最佳入口。');
    parts.push('');
    parts.push('---');
    parts.push('');
  }

  // ─── 热点分布 ───
  if (allFindings.length > 0) {
    parts.push(`## ${hasDumpFindings ? '三' : '二'}、热点分布`);
    parts.push('');
    parts.push('| 热点类型 | 中文名称 | 数量 | 最高严重度 |');
    parts.push('|----------|----------|------|------------|');
    const typeMap = {};
    for (const f of allFindings) {
      if (!typeMap[f.hotspot_type]) {
        typeMap[f.hotspot_type] = { count: 0, maxSeverity: 'low' };
      }
      typeMap[f.hotspot_type].count++;
      if (f.severity === 'high') typeMap[f.hotspot_type].maxSeverity = 'high';
      else if (f.severity === 'medium' && typeMap[f.hotspot_type].maxSeverity !== 'high') typeMap[f.hotspot_type].maxSeverity = 'medium';
    }
    // Sort by severity then count
    const sorted = Object.entries(typeMap).sort((a, b) => {
      const sevOrder = { high: 0, medium: 1, low: 2 };
      if (sevOrder[a[1].maxSeverity] !== sevOrder[b[1].maxSeverity]) {
        return sevOrder[a[1].maxSeverity] - sevOrder[b[1].maxSeverity];
      }
      return b[1].count - a[1].count;
    });
    for (const [type, info] of sorted) {
      parts.push(`| ${type} | ${HOTSPOT_LABELS[type] || type} | ${info.count} | ${SEVERITY_ICON[info.maxSeverity]} ${SEVERITY_LABEL[info.maxSeverity]} |`);
    }
    parts.push('');
  }

  // ─── 详细问题列表 ───
  parts.push(`## ${hasDumpFindings ? '四' : '三'}、详细问题诊断`);
  parts.push('');

  // Group by severity
  for (const sev of ['high', 'medium', 'low']) {
    const sevFindings = allFindings.filter(f => f.severity === sev);
    if (sevFindings.length === 0) continue;

    parts.push(`### ${SEVERITY_ICON[sev]} ${SEVERITY_LABEL[sev]}严重度 (${sevFindings.length} 项)`);
    parts.push('');

    for (let i = 0; i < sevFindings.length; i++) {
      const f = sevFindings[i];
      parts.push(`#### ${i + 1}. ${HOTSPOT_LABELS[f.hotspot_type] || f.hotspot_type}`);
      parts.push('');
      parts.push(`- **位置**：${f.location}`);
      parts.push(`- **严重度**：${SEVERITY_ICON[sev]} ${SEVERITY_LABEL[sev]}`);
      parts.push(`- **问题描述**：${f.description}`);
      parts.push(`- **修复建议**：${f.suggestion}`);

      // dump 侧 finding 添加可视化查看建议
      const isDumpFinding = schemas.some(s => s.analysis_type === 'dump' && (s.findings || []).includes(f));
      if (isDumpFinding) {
        const vizTip = getVisualizationTip(f.hotspot_type);
        if (vizTip) {
          parts.push(`- **可视化查看**：${vizTip}`);
        }
      }

      if (f.evidence) {
        parts.push('- **证据**：');
        parts.push('```json');
        parts.push(JSON.stringify(f.evidence, null, 2));
        parts.push('```');
      }
      parts.push('');
    }
  }

  // ─── 优化建议汇总 ───
  parts.push(`## ${hasDumpFindings ? '五' : '四'}、总体优化建议`);
  parts.push('');

  if (allFindings.length === 0) {
    parts.push('未发现已知 ArkUI 内存反模式。');
    parts.push('');
    parts.push('> 建议：定期使用 ArkUI Inspector dump 和源码扫描进行持续监控。');
  } else {
    const suggestions = new Set();
    for (const f of allFindings) {
      suggestions.add(`- [${SEVERITY_ICON[f.severity]}] **${HOTSPOT_LABELS[f.hotspot_type] || f.hotspot_type}**：${f.suggestion}`);
    }
    parts.push('按优先级排序的优化建议：');
    parts.push('');
    const sorted = Array.from(suggestions).sort((a, b) => {
      if (a.includes('🔴') && !b.includes('🔴')) return -1;
      if (!a.includes('🔴') && b.includes('🔴')) return 1;
      if (a.includes('🟡') && !b.includes('🟡')) return -1;
      if (!a.includes('🟡') && b.includes('🟡')) return 1;
      return 0;
    });
    for (const s of sorted) {
      parts.push(s);
    }
  }
  parts.push('');

  // ─── 标准化 Schema 输出指引 ───
  parts.push(`## ${hasDumpFindings ? '六' : '五'}、标准化 Schema`);
  parts.push('');
  parts.push('> 以下 schema 可被 skill ④（用例构造指南）或 P2 可视化工具（ArkUIDumpViewer build.ts）消费。');
  parts.push('');
  parts.push('```json');
  parts.push(JSON.stringify({
    schema_version: '1.0',
    findings: allFindings.map(f => ({
      hotspot_type: f.hotspot_type,
      severity: f.severity,
      location: f.location,
      description: f.description,
      suggestion: f.suggestion,
    })),
  }, null, 2));
  parts.push('```');
  parts.push('');

  // ─── 闭环指引 ───
  parts.push(`## ${hasDumpFindings ? '七' : '六'}、测试用例构造闭环与可视化验证`);
  parts.push('');
  parts.push('### 静态分析 → 修复 → 可视化验证 闭环');
  parts.push('');
  parts.push('```');
  parts.push('① 本 Skill 分析（源码 + dump）→ 产出定性报告 + schema');
  parts.push('② 根据「总体优化建议」修复代码');
  parts.push('③ 使用 ArkUI Inspector 获取修复前/后 dump 文件');
  parts.push('④ 将 dump 文件放入 ArkUIDumpViewer 的 dumps/ 目录');
  parts.push('⑤ 运行 npm run all 构建交互式 HTML 可视化');
  parts.push('⑥ 在可视化工具中验证：');
  parts.push('   - 「隐藏态」视图：不可见节点是否已消除');
  parts.push('   - 「游离根」面板：缓存根数量是否减少');
  parts.push('   - 「内存热力」：热点子树内存是否回落');
  parts.push('   - 搜索特定组件（Canvas/Video/ImageAnimator）确认已移除或优化');
  parts.push('⑦ 对比修复前/后的组件树节点数和总内存，量化优化效果');
  parts.push('```');
  parts.push('');
  parts.push('> 💡 **完整闭环**：本 Skill 做定性分析（"有什么问题"）→ ArkUIDumpViewer 做定量可视化（"问题占多少内存、在树的哪个位置"）→ memory-anti-regression Skill 做运行时归因（"为什么劣化、劣化了多少"）。三者配合使用效果最佳。');
  parts.push('');

  return parts.join('\n');
}

// ─── CLI ────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);

  let dumpSchemaPath = null;
  let sourceSchemaPath = null;
  let outputDir = null;
  let dumpFile = null;       // dump 文件或目录路径（用于生成 HTML 可视化）
  let dumpDir = null;        // dump 目录路径（自动遍历所有 .dump 文件生成 schema）
  let sourceDir = null;      // 源码目录路径（用于构造指南的导航提取）
  let skipHtml = false;     // 跳过 HTML 可视化生成

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--dump-schema' && args[i + 1]) {
      dumpSchemaPath = args[++i];
    } else if (args[i] === '--source-schema' && args[i + 1]) {
      sourceSchemaPath = args[++i];
    } else if (args[i] === '--output-dir' && args[i + 1]) {
      outputDir = args[++i];
    } else if (args[i] === '--dump-file' && args[i + 1]) {
      dumpFile = args[++i];
    } else if (args[i] === '--dump-dir' && args[i + 1]) {
      dumpDir = args[i + 1];
      dumpFile = args[i + 1];  // dump-dir 同时作为 CLI 输入
      i++;
    } else if (args[i] === '--source-dir' && args[i + 1]) {
      sourceDir = args[++i];
    } else if (args[i] === '--skip-html') {
      skipHtml = true;
    }
  }

  if (!outputDir) {
    outputDir = 'arkui_memory_analysis';
  }

  // 创建输出目录
  outputDir = resolve(outputDir);
  mkdirSync(outputDir, { recursive: true });
  console.log(`输出目录: ${outputDir}`);

  // 如果指定了 --dump-dir，自动遍历目录下所有 .dump 文件生成 dump schema
  if (dumpDir) {
    const scriptDir = dirname(fileURLToPath(import.meta.url));
    const dumpAnalyzerPath = resolve(scriptDir, 'analyze-arkui-dump.mjs');
    const absDumpDir = resolve(dumpDir);

    // 递归查找所有 .dump 文件
    const dumpFiles = [];
    (function findDumps(dir) {
      const entries = readdirSync(dir, { withFileTypes: true });
      for (const ent of entries) {
        const full = join(dir, ent.name);
        if (ent.isDirectory()) {
          if (ent.name === 'node_modules' || ent.name === '.git') continue;
          findDumps(full);
        } else if (ent.isFile() && (ent.name.endsWith('.dump') || ent.name.endsWith('.json'))) {
          // 只取每个用例的 step_1 作为代表（避免过多重复）
          if (ent.name.includes('case_step_1.') || ent.name.includes('case_step_1_') || (!ent.name.includes('case_step_') && !ent.name.includes('backhome'))) {
            dumpFiles.push(full);
          }
        }
      }
    })(absDumpDir);

    console.log(`遍历 dump 目录: ${absDumpDir}，找到 ${dumpFiles.length} 个 dump 文件`);

    // 逐个分析并合并
    const allDumpFindings = [];
    for (const dumpPath of dumpFiles) {
      try {
        const result = execSync(`node "${dumpAnalyzerPath}" "${dumpPath}"`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
        const schema = JSON.parse(result);
        if (schema.findings && schema.findings.length > 0) {
          allDumpFindings.push(...schema.findings);
        }
      } catch (e) {
        console.warn(`  ⚠ 分析失败: ${basename(dumpPath)} - ${e.message.substring(0, 80)}`);
      }
    }

    if (allDumpFindings.length > 0) {
      const mergedSchema = {
        schema_version: '1.0',
        analysis_type: 'dump',
        input_file: absDumpDir,
        timestamp: new Date().toISOString(),
        stats: {
          node_count: 0,
          max_depth: 0,
          total_findings: allDumpFindings.length,
          by_severity: {
            high: allDumpFindings.filter(f => f.severity === 'high').length,
            medium: allDumpFindings.filter(f => f.severity === 'medium').length,
            low: allDumpFindings.filter(f => f.severity === 'low').length,
          },
        },
        findings: allDumpFindings,
      };
      // 写入临时文件（生成最终 JSON 后删除）
      dumpSchemaPath = join(outputDir, '_dump_schema_merged.json');
      writeFileSync(dumpSchemaPath, JSON.stringify(mergedSchema, null, 2), 'utf8');
      console.log(`✅ Dump schema 自动生成: ${allDumpFindings.length} 条发现（来自 ${dumpFiles.length} 个 dump 文件）`);
    }
  }

  // 加载 schema
  const schemas = [];
  if (dumpSchemaPath) {
    schemas.push(JSON.parse(readFileSync(dumpSchemaPath, 'utf8')));
  }
  if (sourceSchemaPath) {
    schemas.push(JSON.parse(readFileSync(sourceSchemaPath, 'utf8')));
  }

  if (schemas.length === 0 && !dumpDir) {
    console.error('Error: 至少需要 --dump-schema / --source-schema / --dump-dir 之一');
    process.exit(1);
  }

  // 1. 生成 Markdown 报告
  const report = generateReport(schemas);
  const reportPath = join(outputDir, 'arkui-memory-report.md');
  writeFileSync(reportPath, report, 'utf8');
  console.log(`✅ Markdown 报告: ${reportPath}`);

  // 2. 生成标准化 JSON schema
  const allFindings = schemas.flatMap(s => s.findings || []);
  const schemaOutput = {
    schema_version: '1.0',
    timestamp: new Date().toISOString(),
    analysis_inputs: schemas.map(s => ({
      type: s.analysis_type,
      file: s.input_file || s.input_path,
      findings_count: (s.findings || []).length,
    })),
    total_findings: allFindings.length,
    by_severity: {
      high: allFindings.filter(f => f.severity === 'high').length,
      medium: allFindings.filter(f => f.severity === 'medium').length,
      low: allFindings.filter(f => f.severity === 'low').length,
    },
    findings: allFindings,
  };
  const schemaPath = join(outputDir, 'arkui-memory-schema.json');
  writeFileSync(schemaPath, JSON.stringify(schemaOutput, null, 2), 'utf8');
  console.log(`✅ 标准化 JSON: ${schemaPath}`);

  // 生成内存测试用例构造指南（US-2）
  // 逻辑：指南只能从【源码分析】生成（源码→指南→开发者测试获取dump→dump反馈工具=数据飞轮）
  // 不依赖 dump 分析生成（dump 在指南产出之后才存在）。无源码分析则不生成指南。
  let guideGenerated = false;
  if (sourceSchemaPath) {
    const guidePath = join(outputDir, 'arkui-test-guide.md');
    try {
      const scriptDir2 = dirname(fileURLToPath(import.meta.url));
      const sourceDirArg = sourceDir ? ` --source-dir "${resolve(sourceDir)}"` : '';
      execSync(`node "${join(scriptDir2, 'generate-test-guide.mjs')}" --schema "${sourceSchemaPath}" --output "${guidePath}"${sourceDirArg}`, { stdio: 'inherit' });
      guideGenerated = true;
    } catch (e) {
      console.warn(`⚠ 构造指南生成失败: ${e.message}`);
    }
  } else {
    console.log('ℹ 未提供源码分析（--source-schema），跳过用例构造指南生成（指南仅从源码分析生成）');
  }

  // 删除中间文件
  const mergedPath = join(outputDir, '_dump_schema_merged.json');
  try { if (existsSync(mergedPath)) unlinkSync(mergedPath); } catch {}

  // 3. 生成 HTML 可视化（调用 ArkUIDumpViewer）
  if (!skipHtml && dumpFile) {
    const htmlDir = join(outputDir, 'arkui_dump_viewer');
    mkdirSync(htmlDir, { recursive: true });

    // 查找 arkui-dump-viewer CLI 或本仓 build 脚本
    // schema 传给 CLI 用于在 HTML 中高亮热点节点
    const schemaArg = ` --schema "${schemaPath}"`;
    let buildCmd = null;
    try {
      // 尝试用全局安装的 arkui-dump-viewer
      execSync('arkui-dump-viewer --help', { stdio: 'pipe' });
      buildCmd = `arkui-dump-viewer "${dumpFile}" --output "${htmlDir}"${schemaArg}`;
    } catch {
      // 尝试找到 ArkUIDumpViewer 仓库
      const possiblePaths = [
        resolve(process.cwd(), 'src', 'build.ts'),
        resolve(dirname(process.argv[1]), '..', '..', '..', 'src', 'build.ts'),
      ];
      for (const p of possiblePaths) {
        if (existsSync(p)) {
          buildCmd = `npx tsx "${p}" --force --output "${htmlDir}" "${dumpFile}"`;
          break;
        }
      }
    }

    if (buildCmd) {
      console.log(`生成 HTML 可视化: ${buildCmd}`);
      try {
        execSync(buildCmd, { stdio: 'inherit', cwd: dirname(buildCmd.split(' ')[0]) || process.cwd() });
        // 查找生成的 HTML 文件并复制到 html_viewer/
        const htmlFiles = ['index.html'];
        for (const f of htmlFiles) {
          const src = join(htmlDir, f);
          if (!existsSync(src)) {
            // 可能在 dumps_result_*/ 子目录
            const results = execSync(`find "${htmlDir}" -name "index.html" -maxdepth 3`, { encoding: 'utf8' }).trim();
            if (results) {
              const srcPath = results.split('\n')[0];
              const srcDir = dirname(srcPath);
              cpSync(srcDir, htmlDir, { recursive: true, force: true });
            }
          }
        }
        console.log(`✅ HTML 可视化: ${join(htmlDir, 'index.html')}`);
      } catch (e) {
        console.warn(`⚠ HTML 可视化生成失败: ${e.message}`);
        console.warn(`  可手动运行: cd ArkUIDumpViewer && npm run build`);
      }
    } else {
      console.warn('⚠ 未找到 arkui-dump-viewer，跳过 HTML 可视化生成');
      console.warn('  安装方式: npm install -g arkui-dump-viewer-*.tgz');
      console.warn('  或在 ArkUIDumpViewer 仓库目录下运行本脚本');
    }
  } else if (!skipHtml && !dumpFile) {
    console.log('ℹ 未提供 --dump-file，跳过 HTML 可视化生成');
  }

  console.log('');
  console.log('=== 产出完成 ===');
  console.log(`  ${outputDir}/`);
  console.log(`  ├── arkui-memory-report.md     # Markdown 报告`);
  console.log(`  ├── arkui-memory-schema.json   # 标准化 JSON 数据`);
  if (guideGenerated) console.log(`  ├── arkui-test-guide.md        # 内存测试用例构造指南（仅源码分析生成）`);
  if (!skipHtml && dumpFile) {
    console.log(`  └── arkui_dump_viewer/         # 工具解析 dump 生成的所有文件`);
    console.log(`      ├── index.html             # HTML 可视化`);
    console.log(`      ├── *.js                   # JSON 数据文件`);
    console.log(`      └── *.xlsx + images/       # 统计表 + 图表`);
  }
}

main();
