#!/usr/bin/env node
/**
 * ArkUI Dump 内存热点分析脚本
 *
 * 解析 ArkUI inspector dump 文件（.dump 文本格式或 .json JSON格式），
 * 检测 ArkUI 内存反模式（不可见页面、缓存不释放、非懒加载等），
 * 输出标准化 schema（JSON）供报告生成和 skill ④ 消费。
 *
 * 用法:
 *   node analyze-arkui-dump.mjs <dump-file> [--memory-csv <path>]
 *
 * 输出: stdout JSON schema (findings 数组)
 */

import { readFileSync, accessSync } from 'node:fs';
import { extname, resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { homedir } from 'node:os';

// ─── 从 npm 包 arkui-dump-viewer 加载解析器 ───────────────────
// 发布态：npm install -g arkui-dump-viewer-*.tar.gz
// 开发态（本仓内）：从源码 src/parser.ts 加载
// Windows 兼容：bare specifier 不查全局 node_modules，绝对路径需 pathToFileURL

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const IS_WIN = process.platform === 'win32';

async function loadParser() {
  const candidates = [];

  // 1. 本地 node_modules（bare specifier，Node ESM 自动解析）
  candidates.push('arkui-dump-viewer');

  // 2. 全局 node_modules — npm root -g
  try {
    const { execSync } = await import('node:child_process');
    const globalRoot = execSync('npm root -g', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).trim();
    if (globalRoot) {
      const parserPath = resolve(globalRoot, 'arkui-dump-viewer', 'dist', 'parser.js');
      candidates.push(IS_WIN ? pathToFileURL(parserPath).href : parserPath);
    }
  } catch {
    // npm 不可用
  }

  // 3. Windows AppData 兜底（npm root -g 可能因 stderr 噪声或权限返回空）
  if (IS_WIN) {
    const appData = process.env.APPDATA || resolve(homedir(), 'AppData', 'Roaming');
    const winGlobalPath = resolve(appData, 'npm', 'node_modules', 'arkui-dump-viewer', 'dist', 'parser.js');
    candidates.push(pathToFileURL(winGlobalPath).href);
  }

  for (const candidate of candidates) {
    try {
      const mod = await import(candidate);
      if (mod.parseDump && mod.parseJsonDump) {
        return { parseDump: mod.parseDump, parseJsonDump: mod.parseJsonDump };
      }
    } catch {
      // try next
    }
  }

  // 开发态回退：从 SCRIPT_DIR 和 CWD 向上查找 src/parser.ts
  const searchDirs = [SCRIPT_DIR, process.cwd()];
  for (const startDir of searchDirs) {
    let dir = startDir;
    for (let i = 0; i < 8; i++) {
      try {
        const parserPath = resolve(dir, 'src', 'parser.ts');
        accessSync(parserPath);
        const mod = await import(IS_WIN ? pathToFileURL(parserPath).href : parserPath);
        return { parseDump: mod.parseDump, parseJsonDump: mod.parseJsonDump };
      } catch {
        dir = resolve(dir, '..');
      }
    }
  }
  throw new Error('无法加载 parser: 请先 npm install -g arkui-dump-viewer 或在 ArkUIDumpViewer 仓库内运行');
}

// ─── 加载内存基线 ─────────────────────────────────────────────

function findMemoryCsv() {
  // 尝试从脚本同级目录加载（打包时会带上）
  const localPath = resolve(SCRIPT_DIR, 'memory.csv');
  try {
    accessSync(localPath);
    return localPath;
  } catch {
    // 回退：从本仓 database 加载（开发态）
    let dir = SCRIPT_DIR;
    for (let i = 0; i < 8; i++) {
      const dbPath = resolve(dir, 'database', 'memory.csv');
      try {
        accessSync(dbPath);
        return dbPath;
      } catch {
        dir = resolve(dir, '..');
      }
    }
    return null;
  }
}

function loadMemoryCsv(csvPath) {
  const text = readFileSync(csvPath, 'utf8');
  const map = new Map();
  const lines = text.trim().split('\n');
  // Skip header
  for (let i = 1; i < lines.length; i++) {
    const parts = lines[i].split(',');
    if (parts.length >= 2) {
      const tag = parts[0].trim();
      const kb = parseFloat(parts[1]);
      if (tag && !isNaN(kb)) {
        map.set(tag, kb);
      }
    }
  }
  return map;
}

// ─── 内存计算 ──────────────────────────────────────────────────

const DEFAULT_MEM_KB = 0; // 未知组件默认 0

function getNodeBaseMem(tag, memMap) {
  return memMap.get(tag) ?? DEFAULT_MEM_KB;
}

function getNodeDma(node) {
  // Image: w × h × 4 bytes (RGBA_8888)
  // XComponent/Web: w × h × 4 × 5 bytes
  if (!node.frame || !node.frame.w || !node.frame.h) return 0;
  const px = node.frame.w * node.frame.h;
  if (node.tag === 'Image' || node.tag === 'image') {
    if (node.isPixmapID || node.isSVG) return 0;
    // Also check rawImageSize
    return px * 4 / 1024; // KB
  }
  if (node.tag === 'XComponent' || node.tag === 'Web') {
    return px * 4 * 5 / 1024;
  }
  return 0;
}

function subtreeMem(node, memMap) {
  let base = getNodeBaseMem(node.tag, memMap);
  let dma = getNodeDma(node);
  for (const child of node.children) {
    const sub = subtreeMem(child, memMap);
    base += sub.base;
    dma += sub.dma;
  }
  return { base, dma };
}

// ─── 遍历工具 ──────────────────────────────────────────────────

// 设置 parent 链（parseDump/parseJsonDump 不自动设 parent）
function setParents(node, parent = null) {
  node.parent = parent;
  for (const child of (node.children || [])) {
    setParents(child, node);
  }
}

// 从节点向上构建导航路径（收集 NavDestination/页面名 + 组件#ID）
function buildNodeLocation(node) {
  const id = node.facts?.ID != null ? node.facts.ID : node.uid;
  const nodeTag = `${node.tag}#${id}`;
  // 向上收集导航上下文
  const crumbs = [];
  let p = node.parent;
  while (p) {
    // 收集 NavDestination（含 name）、Navigation、页面级组件
    if (p.tag === 'NavDestination' || p.tag === 'navDestination') {
      const name = p.facts?.name || p.facts?.ComponentName;
      crumbs.unshift(name ? `NavDestination(${name})#${p.facts?.ID || p.uid}` : `NavDestination#${p.facts?.ID || p.uid}`);
    } else if (p.tag === 'Navigation' || p.tag === 'navigation') {
      crumbs.unshift(`Navigation#${p.facts?.ID || p.uid}`);
    } else if (p.tag === 'stage' || p.tag === 'root') {
      // skip synthetic roots
    } else if (p.facts?.name && p.tag !== 'Forest') {
      crumbs.unshift(`${p.tag}(${p.facts.name})#${p.facts?.ID || p.uid}`);
    }
    p = p.parent;
  }
  const navPath = crumbs.length > 0 ? crumbs.join(' > ') + ' > ' : '';
  return navPath + nodeTag;
}

function walkTree(node, depth = 0, visitor) {
  visitor(node, depth);
  for (const child of node.children) {
    walkTree(child, depth + 1, visitor);
  }
}

function findNodesByTag(root, tags) {
  const results = [];
  walkTree(root, 0, (node) => {
    if (tags.includes(node.tag)) {
      results.push(node);
    }
  });
  return results;
}

function countDescendants(node) {
  let count = 0;
  for (const child of node.children) {
    count += 1 + countDescendants(child);
  }
  return count;
}

function getAncestorPath(node, root) {
  // Simple: return the tag chain from root to node
  // For now just return tag and depth info
  return `${node.tag}@depth${node.facts?.Depth || '?'}`;
}

// ─── 热点检测规则 ───────────────────────────────────────────────

/**
 * 每条规则返回一个 finding 对象:
 * { hotspot_type, severity, location, description, suggestion, evidence }
 */

function detectHiddenPageSubtrees(root, memMap) {
  const findings = [];
  // H-01: VisibleAndActive='0' 的大子树
  walkTree(root, 0, (node) => {
    if (node === root) return;
    const visible = node.facts?.VisibleAndActive;
    if (visible === '0') {
      const desc = countDescendants(node);
      const mem = subtreeMem(node, memMap);
      const totalMemKB = mem.base + mem.dma;
      if (desc > 10 || totalMemKB > 1024) {
        findings.push({
          hotspot_type: 'invisible_page',
          severity: totalMemKB > 10240 ? 'high' : 'medium',
          location: `${buildNodeLocation(node)} (VisibleAndActive=0, ${desc} descendants, ${totalMemKB.toFixed(0)}KB)`,
          description: `不可见子树被构建: ${node.tag} 有 ${desc} 个后代节点, 估算内存 ${(totalMemKB / 1024).toFixed(1)}MB, 但 VisibleAndActive=0 (不可见)`,
          suggestion: '使用条件渲染 if(visible){Page()} 替代 visibility(Hidden), 不构建时零成本; aboutToDisappear 释放 PixelMap 等资源',
          evidence: { tag: node.tag, visibleAndActive: '0', descendantCount: desc, memKB: totalMemKB }
        });
      }
    }
  });
  return findings;
}

function detectTabsCacheNotReleased(root, memMap) {
  const findings = [];
  // H-02: 多个 TabContent 子树同时存活
  const tabContents = findNodesByTag(root, ['TabContent', 'tabContent']);
  if (tabContents.length >= 3) {
    // Check how many are invisible but still in tree
    let invisibleTabs = 0;
    let invisibleMemKB = 0;
    for (const tc of tabContents) {
      const visible = tc.facts?.VisibleAndActive;
      if (visible === '0') {
        invisibleTabs++;
        const mem = subtreeMem(tc, memMap);
        invisibleMemKB += mem.base + mem.dma;
      }
    }
    if (invisibleTabs >= 2) {
      findings.push({
        hotspot_type: 'tabs_cache_not_released',
        severity: invisibleMemKB > 10240 ? 'high' : 'medium',
        location: `${buildNodeLocation(tabs)} (${tabContents.length} TabContent, ${invisibleTabs} invisible)`,
        description: `${tabContents.length} 个 TabContent 同时存活, 其中 ${invisibleTabs} 个不可见但仍缓存, 估算 ${(invisibleMemKB / 1024).toFixed(1)}MB 被缓存占用`,
        suggestion: '设置 Tabs.cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE) 限制缓存; aboutToDisappear 释放 PixelMap',
        evidence: { totalTabs: tabContents.length, invisibleTabs, invisibleMemKB }
      });
    }
  }
  return findings;
}

function detectPreloadedInvisibleTabs(root, memMap) {
  const findings = [];
  // H-03: 当前页 index=0 但其他页已构建
  // In dump, look for Tabs node where only first TabContent is visible
  const tabsNodes = findNodesByTag(root, ['Tabs', 'tabs']);
  for (const tabs of tabsNodes) {
    const tabContents = tabs.children.filter(c => c.tag === 'TabContent' || c.tag === 'tabContent');
    if (tabContents.length >= 3) {
      const visibleOnes = tabContents.filter(tc => tc.facts?.VisibleAndActive === '1');
      const builtInvisible = tabContents.filter(tc => tc.facts?.VisibleAndActive === '0' && countDescendants(tc) > 5);
      if (builtInvisible.length >= 1 && visibleOnes.length <= 1) {
        const mem = builtInvisible.reduce((sum, tc) => {
          const m = subtreeMem(tc, memMap);
          return sum + m.base + m.dma;
        }, 0);
        findings.push({
          hotspot_type: 'tabs_preload_invisible',
          severity: mem > 10240 ? 'high' : 'medium',
          location: `${builtInvisible[0] ? buildNodeLocation(builtInvisible[0]) : 'Tabs'} (${builtInvisible.length} preloaded invisible TabContent, ${mem.toFixed(0)}KB)`,
          description: `当前仅 ${visibleOnes.length} 个页签可见, 但 ${builtInvisible.length} 个不可见页签已被构建(预加载), 估算 ${(mem / 1024).toFixed(1)}MB 预加载成本`,
          suggestion: '仅在用户有明确意图时 preloadItems 相邻页; 不要在 Tabs.onAppear 预加载非相邻页签',
          evidence: { visibleTabs: visibleOnes.length, preloadedInvisible: builtInvisible.length, memKB: mem }
        });
      }
    }
  }
  return findings;
}

function detectListNonLazy(root) {
  const findings = [];
  // H-05: List 内有大量子节点(全量加载)
  const listNodes = findNodesByTag(root, ['List', 'list']);
  for (const list of listNodes) {
    const items = list.children.filter(c => c.tag === 'ListItem' || c.tag === 'listItem' || c.tag === 'Item');
    if (items.length > 30) {
      // Check if LazyForEach is used (detached roots with cache type)
      const hasLazyForEach = list.children.some(c =>
        c.tag === 'LazyForEach' || c.facts?.detachedType === 'LazyForEach缓存'
      );
      if (!hasLazyForEach) {
        findings.push({
          hotspot_type: 'list_non_lazy',
          severity: items.length > 100 ? 'high' : 'medium',
          location: `${buildNodeLocation(container)} (${items.length} ListItem, no LazyForEach detected)`,
          description: `List 内有 ${items.length} 个 ListItem 全量构建, 未检测到 LazyForEach 懒加载, 离屏节点不回收`,
          suggestion: '将 ForEach 替换为 LazyForEach + IDataSource 实现, 仅建可见行+缓冲行',
          evidence: { itemCount: items.length, hasLazyForEach: false }
        });
      }
    }
  }
  return findings;
}

function detectListCachedCountTooLarge(root) {
  const findings = [];
  // H-06: LazyForEach 缓存的离屏节点过多
  // Look for LazyForEach cached items in detached roots
  const detachedRoots = root.forest === 'forest' ? root.children.slice(1) : [];
  for (const det of detachedRoots) {
    if (det.detachedType === 'LazyForEach缓存' || det.detachedType === 'Repeat缓存') {
      const cachedCount = countDescendants(det);
      if (cachedCount > 20) {
        findings.push({
          hotspot_type: 'list_cachedcount_too_large',
          severity: cachedCount > 100 ? 'high' : 'medium',
          location: `${buildNodeLocation(det)} (${cachedCount} cached nodes)`,
          description: `LazyForEach/Repeat 缓存了 ${cachedCount} 个离屏节点, cachedCount 可能设置过大`,
          suggestion: '将 cachedCount 设为 1-3, 一般不超过 5; 离屏节点应自动回收',
          evidence: { cachedCount, detachedType: det.detachedType }
        });
      }
    }
  }
  return findings;
}

function detectDeepNesting(root) {
  const findings = [];
  // H-07: 深度 > 15
  let maxDepth = 0;
  let deepestNode = null;
  walkTree(root, 0, (node, depth) => {
    if (depth > maxDepth) {
      maxDepth = depth;
      deepestNode = node;
    }
  });
  if (maxDepth > 15) {
    // Check for redundant container nesting
    let redundantChain = 0;
    let maxRedundantChain = 0;
    function checkRedundant(node, depth) {
    // All ArkUI container components (layout + scrollable + navigation + framework wrappers)
    const containerTags = [
      'Stack', 'stack', 'Column', 'column', 'Row', 'row', 'Flex', 'flex',
      'Grid', 'grid', 'GridItem', 'griditem', 'List', 'list', 'ListItem', 'listitem',
      'Swiper', 'swiper', 'WaterFlow', 'waterflow', 'Scroll', 'scroll',
      'RelativeContainer', 'relativecontainer',
      'Navigation', 'navigation', 'NavDestination', 'navdestination',
      'Tabs', 'tabs', 'TabContent', 'tabcontent',
      '__Common__', 'IfElse', 'ifelse', 'Column', 'Row',
      'ForEach', 'foreach', 'LazyForEach', 'lazyforeach',
    ];
      if (containerTags.includes(node.tag)) {
        redundantChain++;
        maxRedundantChain = Math.max(maxRedundantChain, redundantChain);
      } else {
        redundantChain = 0;
      }
      for (const child of node.children) {
        checkRedundant(child, depth + 1);
      }
      if (containerTags.includes(node.tag)) {
        redundantChain--;
      }
    }
    checkRedundant(root, 0);

    if (maxRedundantChain > 5) {
      findings.push({
        hotspot_type: 'layout_redundant_nesting',
        severity: maxRedundantChain > 10 ? 'high' : 'medium',
        location: `${deepestNode ? buildNodeLocation(deepestNode) : 'unknown'} (maxDepth=${maxDepth}, maxContainerChain=${maxRedundantChain})`,
        description: `组件树最大深度 ${maxDepth}, 容器连续嵌套 ${maxRedundantChain} 层, 存在冗余布局写法`,
        suggestion: '扁平化布局: @Builder 分解各区域, 每区 2-4 层嵌套; 移除无内容空容器; ForEach 单层遍历',
        evidence: { maxDepth, maxContainerChain: maxRedundantChain }
      });
    }
  }
  return findings;
}

function detectCanvasFullsreen(root) {
  const findings = [];
  // H-08: Canvas 全屏(可能用于渐变背景)
  const canvasNodes = findNodesByTag(root, ['Canvas', 'canvas']);
  for (const canvas of canvasNodes) {
    if (canvas.frame && canvas.frame.w > 500 && canvas.frame.h > 500) {
      const dma = canvas.frame.w * canvas.frame.h * 4 / 1024; // Approximate
      findings.push({
        hotspot_type: 'canvas_gradient',
        severity: 'medium',
        location: `${buildNodeLocation(canvas)} (${canvas.frame.w.toFixed(0)}×${canvas.frame.h.toFixed(0)}, ~${dma.toFixed(0)}KB DMA)`,
        description: `Canvas 组件尺寸 ${canvas.frame.w.toFixed(0)}×${canvas.frame.h.toFixed(0)} 接近全屏, 可能用于绘制静态渐变背景, 会分配 GPU/DMA surface (~${(dma / 1024).toFixed(1)}MB)`,
        suggestion: '静态渐变背景用 Column().linearGradient({ direction, colors }) 声明式接口, 走 shader 路径 O(1) 内存; Canvas 仅用于动态绘制',
        evidence: { width: canvas.frame.w, height: canvas.frame.h, estimatedDmaKB: dma }
      });
    }
  }
  return findings;
}

function detectImageAnimatorExcessive(root) {
  const findings = [];
  // H-09: ImageAnimator 下大量 Image 子节点
  const animNodes = findNodesByTag(root, ['ImageAnimator', 'imageAnimator', 'AnimatedImage']);
  for (const anim of animNodes) {
    const images = anim.children.filter(c => c.tag === 'Image' || c.tag === 'image');
    if (images.length > 10) {
      let totalDma = 0;
      for (const img of images) {
        if (img.rawImageSize) {
          totalDma += img.rawImageSize.w * img.rawImageSize.h * 4 / 1024;
        }
      }
      findings.push({
        hotspot_type: 'image_animator_excessive',
        severity: totalDma > 10240 ? 'high' : 'medium',
        location: `${buildNodeLocation(ia)} (${images.length} frames, ~${totalDma.toFixed(0)}KB)`,
        description: `ImageAnimator 有 ${images.length} 帧, 估算总 DMA ${(totalDma / 1024).toFixed(1)}MB, 全部帧预解码常驻 native heap`,
        suggestion: '控制帧数 ≤ 10; 对帧图下采样到展示尺寸; 用 string/Resource src 让组件按需解码; aboutToDisappear 释放 PixelMap',
        evidence: { frameCount: images.length, estimatedDmaKB: totalDma }
      });
    }
  }
  return findings;
}

function detectVideoResident(root) {
  const findings = [];
  // H-11: Video 组件在非视频页
  const videoNodes = findNodesByTag(root, ['Video', 'video']);
  for (const video of videoNodes) {
    if (video.frame && video.frame.w > 200 && video.frame.h > 100) {
      findings.push({
        hotspot_type: 'video_resident',
        severity: 'low',
        location: `${buildNodeLocation(video)} (${video.frame.w.toFixed(0)}×${video.frame.h.toFixed(0)})`,
        description: 'Video 组件存在, 如 autoplay+循环会使解码器/缓冲常驻, native 媒体内存增长',
        suggestion: '非视频页不要放置 Video; 页面离开时 controller.stop(); 短动画用 ImageAnimator 替代',
        evidence: { width: video.frame.w, height: video.frame.h }
      });
    }
  }
  return findings;
}

function detectLargeImages(root, memMap) {
  const findings = [];
  // Extra: 大量大图导致 DMA 过高
  const imageNodes = findNodesByTag(root, ['Image', 'image']);
  let largeImages = 0;
  let totalDma = 0;
  let firstLargeImg = null;
  for (const img of imageNodes) {
    if (img.rawImageSize && img.rawImageSize.w * img.rawImageSize.h > 500 * 500) {
      largeImages++;
      totalDma += img.rawImageSize.w * img.rawImageSize.h * 4 / 1024;
      if (!firstLargeImg) firstLargeImg = img;
    }
  }
  if (largeImages > 5 && totalDma > 20480) { // >20MB
    findings.push({
      hotspot_type: 'large_images_excessive',
      severity: totalDma > 51200 ? 'high' : 'medium',
      location: `${firstLargeImg ? buildNodeLocation(firstLargeImg) : 'root'} — ${largeImages} large Image nodes (~${(totalDma / 1024).toFixed(1)}MB total DMA)`,
      description: `${largeImages} 个大尺寸 Image 组件(>500×500), 总 DMA 约 ${(totalDma / 1024).toFixed(1)}MB`,
      suggestion: '对大图下采样到展示尺寸; 使用 SVG 替代位图; 非可见图片不预解码; 滚动列表用 LazyForEach 按需加载',
      evidence: { largeImageCount: largeImages, totalDmaKB: totalDma }
    });
  }
  return findings;
}

function detectDetachedCaches(root) {
  const findings = [];
  // Extra: 大量游离缓存根
  const detachedRoots = root.forest === 'forest' ? root.children.slice(1) : [];
  let totalCached = 0;
  let cacheTypes = {};
  for (const det of detachedRoots) {
    const count = countDescendants(det);
    totalCached += count;
    const type = det.detachedType || 'unknown';
    cacheTypes[type] = (cacheTypes[type] || 0) + count;
  }
  if (totalCached > 100) {
    findings.push({
      hotspot_type: 'detached_cache_excessive',
      severity: totalCached > 500 ? 'high' : 'medium',
      location: `${detachedRoots[0] ? buildNodeLocation(detachedRoots[0]) : 'root'} — ${detachedRoots.length} detached roots (${totalCached} total cached nodes)`,
      description: `游离缓存根 ${detachedRoots.length} 个, 总缓存节点 ${totalCached} 个: ${JSON.stringify(cacheTypes)}`,
      suggestion: '检查 LazyForEach/Repeat/Reusable 缓存是否合理释放; 游离缓存过多说明组件被缓存但未回收',
      evidence: { detachedCount: detachedRoots.length, totalCached, cacheTypes }
    });
  }
  return findings;
}

function detectNavStackTooDeep(root) {
  const findings = [];
  const navNodes = findNodesByTag(root, ['NavDestination', 'navDestination']);
  if (navNodes.length > 5) {
    findings.push({
      hotspot_type: 'nav_stack_too_deep',
      severity: 'high',
      location: `${navNodes[0] ? buildNodeLocation(navNodes[0]) : 'root'} — ${navNodes.length} NavDestination nodes in tree`,
      description: `页面栈中有 ${navNodes.length} 个 NavDestination 节点，页面栈过深，每页持有独立组件树和数据`,
      suggestion: '限制 NavPathStack 深度；用 replacePath 替代 pushPath；离开页面时 pop() 释放',
      evidence: { navDestinationCount: navNodes.length }
    });
  }
  return findings;
}

function detectImperativeNodes(root) {
  const findings = [];
  // Check detached roots for CNode/ArkTsFrameNode types
  const detachedRoots = root.forest === 'forest' ? root.children.slice(1) : [];
  let imperativeCount = 0;
  let firstImperative = null;
  for (const det of detachedRoots) {
    if (det.detachedType && (det.detachedType.includes('CNode') || det.detachedType.includes('ArkTsFrameNode') || det.detachedType.includes('RootBuilder'))) {
      imperativeCount += countDescendants(det) + 1;
      if (!firstImperative) firstImperative = det;
    }
  }
  // Also check raw for all imperative node flags (ArkTS + CAPI)
  walkTree(root, 0, (node) => {
    if (node.raw && node.raw.some(l => {
      // ArkTS command nodes
      if (l.startsWith('IsCNode:') && l.includes('1')) return true;
      if (l.startsWith('IsArkTsFrameNode:') && l.includes('1')) return true;
      if (l.startsWith('IsRootBuilderNode:') && l.includes('1')) return true;
      if (l.startsWith('IsArkTsRenderNode:') && l.includes('1')) return true;
      // NodeContainer hosts imperative nodes
      if (l.includes('NodeContainer') && node.tag === 'NodeContainer') return true;
      return false;
    })) {
      imperativeCount++;
    }
  });
  if (imperativeCount > 10) {
    findings.push({
      hotspot_type: 'imperative_node_cached',
      severity: 'medium',
      location: `${firstImperative ? buildNodeLocation(firstImperative) : 'root'} — ${imperativeCount} imperative nodes (CNode/ArkTsFrameNode/RootBuilder)`,
      description: `检测到 ${imperativeCount} 个命令式节点（BuilderNode/CAPI），脱离声明式树管理，可能未释放`,
      suggestion: 'BuilderNode 使用后 dispose() 释放；CAPI 节点手动管理生命周期；优先使用声明式 @Builder/@Reusable',
      evidence: { imperativeNodeCount: imperativeCount }
    });
  }
  return findings;
}

function detectXComponentLeak(root) {
  const findings = [];
  const xcNodes = findNodesByTag(root, ['XComponent', 'xcomponent']);
  for (const xc of xcNodes) {
    // Check raw attributes for detachment flags
    const isOnMainTree = xc.raw?.find(l => l.includes('IsOnMainTree: 0'));
    const isFrameDisappear = xc.raw?.find(l => l.includes('IsFrameDisappear: 1'));
    const visible = xc.facts?.VisibleAndActive;
    // Detached XComponent still alive (not on main tree, frame disappeared, but still visible/active in dump)
    if (isOnMainTree && isFrameDisappear) {
      const mem = subtreeMem(xc, new Map());
      const totalKB = mem.base + mem.dma;
      findings.push({
        hotspot_type: 'xcomponent_not_released',
        severity: totalKB > 10240 ? 'high' : 'medium',
        location: `${buildNodeLocation(xc)} (IsOnMainTree:0, IsFrameDisappear:1, ${countDescendants(xc)} descendants, ${totalKB.toFixed(0)}KB)`,
        description: `XComponent 节点已脱离主树(IsOnMainTree:0)且帧已消失(IsFrameDisappear:1)但仍存活于 dump 中, nativeWindow/Surface 可能延迟释放. 含 ${countDescendants(xc)} 个后代节点, 估算 ${totalKB.toFixed(0)}KB`,
        suggestion: '在 XComponent onDestroy 回调中释放 nativeWindow; LazyForEach onItemDestroy 中主动释放 XComponent; 页面离开时释放 Surface 引用',
        evidence: { isOnMainTree: false, isFrameDisappear: true, descendantCount: countDescendants(xc), memKB: totalKB }
      });
    }
    // Also check: XComponent in visible state but with frame info suggesting it's full-screen video player
    if (xc.frame && xc.frame.w > 1000 && xc.frame.h > 1500) {
      const isLargeVideo = !findings.some(f => f.location.includes(xc.facts?.ID || ''));
      if (isLargeVideo) {
        findings.push({
          hotspot_type: 'xcomponent_not_released',
          severity: 'medium',
          location: `${buildNodeLocation(xc)} (${xc.frame.w.toFixed(0)}×${xc.frame.h.toFixed(0)} full-screen video player)`,
          description: `全屏 XComponent 视频播放器 (${xc.frame.w.toFixed(0)}×${xc.frame.h.toFixed(0)}) 存在, 如同时有多个则可能存在播放器未释放`,
          suggestion: 'Swiper/LazyForEach 切换时前一页 XComponent 应立即释放; 直播播放器不可见时调用 release()',
          evidence: { width: xc.frame.w, height: xc.frame.h }
        });
      }
    }
  }
  return findings;
}

function detectGridSwiperNotLazy(root) {
  const findings = [];
  // H-05: any scrollable container (List/Grid/Swiper/WaterFlow) with ForEach/Repeat (not LazyForEach) and many children
  const scrollableTags = ['Grid', 'grid', 'Swiper', 'swiper', 'List', 'list', 'WaterFlow', 'waterflow'];
  const scrollNodes = findNodesByTag(root, scrollableTags);
  for (const container of scrollNodes) {
    const containerName = container.tag;
    // Check for ForEach/Repeat (non-lazy iteration)
    const hasForEach = container.children.some(c => c.tag === 'ForEach' || c.tag === 'foreach');
    const hasRepeat = container.children.some(c => c.tag === 'Repeat' || c.tag === 'repeat');
    const hasLazyForEach = container.children.some(c => c.tag === 'LazyForEach');
    if ((hasForEach || hasRepeat) && !hasLazyForEach) {
      // Count total items in the iteration node
      const iterNode = container.children.find(c => ['ForEach', 'foreach', 'Repeat', 'repeat'].includes(c.tag));
      const itemCount = iterNode ? (iterNode.declaredChildSize || countDescendants(iterNode)) : 0;
      if (itemCount > 10) {
        // Count invisible items
        let invisibleCount = 0;
        let invisibleMemKB = 0;
        if (iterNode) {
          walkTree(iterNode, 0, (n) => {
            if (n !== iterNode && n.facts?.VisibleAndActive === '0' && n.children.length > 0) {
              invisibleCount++;
              const m = subtreeMem(n, new Map());
              invisibleMemKB += m.base + m.dma;
            }
          });
        }
        if (invisibleCount > 3 || itemCount > 20) {
          findings.push({
            hotspot_type: 'list_non_lazy',
            severity: invisibleMemKB > 10240 ? 'high' : 'medium',
            location: `${buildNodeLocation(container)} > ${iterNode?.tag || 'ForEach'} (${itemCount} items, ${invisibleCount} invisible, ~${(invisibleMemKB/1024).toFixed(1)}MB wasted)`,
            description: `${containerName} 内使用 ${iterNode?.tag || 'ForEach'} 而非 LazyForEach, ${itemCount} 个子项全量构建, 其中 ${invisibleCount} 个不可见仍常驻, 估算 ${(invisibleMemKB/1024).toFixed(1)}MB 浪费`,
            suggestion: '将 ForEach/Repeat 替换为 LazyForEach 实现懒加载; 设合理 cachedCount; 不可见项应自动回收',
            evidence: { container: containerName, itemCount, invisibleCount, wastedMemKB: invisibleMemKB }
          });
        }
      }
    }
  }
  return findings;
}

function detectDeepTreeDepth(root) {
  const findings = [];
  let maxDepth = 0;
  let deepestNode = null;
  walkTree(root, 0, (node, depth) => {
    if (depth > maxDepth) {
      maxDepth = depth;
      deepestNode = node;
    }
  });
  if (maxDepth > 30) {
    findings.push({
      hotspot_type: 'layout_redundant_nesting',
      severity: maxDepth > 60 ? 'high' : 'medium',
      location: `${deepestNode ? buildNodeLocation(deepestNode) : "unknown"} (maxDepth=${maxDepth})`,
      description: `组件树最大嵌套深度 ${maxDepth} 层${maxDepth > 60 ? ' (远超合理范围 30)' : ''}, 布局计算开销大, 可能存在冗余容器嵌套`,
      suggestion: '扁平化布局: 用 relativeLayout 替代多层 Stack/Column/Row; @Builder 分解; 合并 __Common__/IfElse 包装层',
      evidence: { maxDepth, deepestTag: deepestNode?.tag }
    });
  }
  return findings;
}

function detectHeavyDetachedRoots(root) {
  const findings = [];
  const detachedRoots = root.forest === 'forest' ? root.children.slice(1) : [];
  for (const det of detachedRoots) {
    const descendantCount = countDescendants(det);
    if (descendantCount < 50) continue; // Skip small detached roots
    // Check for heavy components in the detached subtree
    const heavyComponents = findNodesByTag(det, ['XComponent', 'Video', 'Canvas']);
    const imageCount = findNodesByTag(det, ['Image', 'image']).length;
    const mem = subtreeMem(det, new Map());
    const totalKB = mem.base + mem.dma;
    if (totalKB > 5120 || heavyComponents.length > 0 || imageCount > 10) {
      const components = [];
      if (heavyComponents.length > 0) components.push(`${heavyComponents.length} XComponent/Video/Canvas`);
      if (imageCount > 10) components.push(`${imageCount} Image`);
      findings.push({
        hotspot_type: heavyComponents.length > 0 ? 'xcomponent_not_released' : 'detached_cache_excessive',
        severity: totalKB > 51200 ? 'high' : 'medium',
        location: `${buildNodeLocation(det)} (${descendantCount} descendants, ~${(totalKB/1024).toFixed(1)}MB${components.length > 0 ? ', ' + components.join('/') : ''})`,
        description: `游离根 ${det.tag} 含 ${descendantCount} 个后代节点${components.length > 0 ? ', 含 ' + components.join('、') : ''}, 估算 ${(totalKB/1024).toFixed(1)}MB${heavyComponents.length > 0 ? '. 重负载组件(XComponent/Video)在游离子树中未释放是 P0 级问题' : ''}`,
        suggestion: heavyComponents.length > 0
          ? 'LazyForEach onItemDestroy 中释放 XComponent/Video; Swiper 切换时前一页播放器立即 release(); 不可见时暂停而非缓存'
          : '降低 cachedCount; 游离子树中的 Image/PixelMap 应在 aboutToDisappear 释放',
        evidence: { descendantCount, totalKB, heavyComponents: heavyComponents.length, imageCount, detachedType: det.detachedType }
      });
    }
  }
  return findings;
}

function detectImageAutoSizeMismatch(root) {
  const findings = [];
  const imageNodes = findNodesByTag(root, ['Image', 'image']);
  let mismatchCount = 0;
  let totalWastedKB = 0;
  let autoResizeFalseCount = 0;
  let firstMismatch = null;
  let firstAutoResizeFalse = null;
  for (const img of imageNodes) {
    const displaySize = img.dstRect || (img.frame ? { w: img.frame.w, h: img.frame.h } : null);
    if (!img.rawImageSize || !displaySize) continue;
    const rawArea = img.rawImageSize.w * img.rawImageSize.h;
    const displayArea = displaySize.w * displaySize.h;
    if (rawArea > 0 && displayArea > 0) {
      const ratio = rawArea / displayArea;
      if (ratio > 4) {
        mismatchCount++;
        totalWastedKB += (rawArea - displayArea) * 4 / 1024;
        if (!firstMismatch) firstMismatch = img;
      }
    }
    if (img.autoResize === false) {
      autoResizeFalseCount++;
      if (!firstAutoResizeFalse) firstAutoResizeFalse = img;
    }
  }
  if (mismatchCount > 3) {
    findings.push({
      hotspot_type: 'large_images_excessive',
      severity: totalWastedKB > 10240 ? 'high' : 'medium',
      location: `${firstMismatch ? buildNodeLocation(firstMismatch) : 'root'} — ${mismatchCount} Image nodes with rawImageSize >> display size (~${(totalWastedKB/1024).toFixed(1)}MB wasted${autoResizeFalseCount > 0 ? `, ${autoResizeFalseCount} autoResize:false` : ''})`,
      description: `${mismatchCount} 个 Image 组件的 rawImageSize 远大于显示尺寸（>4 倍）${autoResizeFalseCount > 0 ? `，${autoResizeFalseCount} 个 autoResize:false 未下采样` : ''}，浪费约 ${(totalWastedKB/1024).toFixed(1)}MB`,
      suggestion: '启用 Image.autoResize(true) 按显示尺寸下采样；大图避免 syncLoad:true 阻塞主线程',
      evidence: { mismatchCount, totalWastedKB, autoResizeFalseCount }
    });
  }
  // Report many autoResize:false even without size mismatch (itself a systemic issue)
  if (autoResizeFalseCount > 10 && mismatchCount <= 3) {
    findings.push({
      hotspot_type: 'large_images_excessive',
      severity: autoResizeFalseCount > 50 ? 'high' : 'medium',
      location: `${firstAutoResizeFalse ? buildNodeLocation(firstAutoResizeFalse) : 'root'} — ${autoResizeFalseCount} Image nodes with autoResize:false`,
      description: `${autoResizeFalseCount} 个 Image 组件未启用 autoResize（下采样），大图会以原始分辨率解码常驻内存。即使当前 rawImageSize 与显示尺寸匹配，未来替换为大图时会产生浪费`,
      suggestion: '启用 Image.autoResize(true) 让系统按显示尺寸下采样；全局搜索 autoResize:false 统一改为 true',
      evidence: { autoResizeFalseCount, mismatchCount }
    });
  }
  return findings;
}

function detectForEachRatio(root) {
  const findings = [];
  let forEachCount = 0;
  let lazyForEachCount = 0;
  let firstForEach = null;
  walkTree(root, 0, (node) => {
    if (node.tag === 'ForEach') { forEachCount++; if (!firstForEach) firstForEach = node; }
    if (node.tag === 'LazyForEach') lazyForEachCount++;
  });
  if (forEachCount >= 5 && lazyForEachCount === 0) {
    findings.push({
      hotspot_type: 'list_non_lazy',
      severity: forEachCount > 15 ? 'high' : 'medium',
      location: `${firstForEach ? buildNodeLocation(firstForEach) : "root"} — ${forEachCount} ForEach, ${lazyForEachCount} LazyForEach (ratio: ∞)`,
      description: `组件树中有 ${forEachCount} 个 ForEach 但 0 个 LazyForEach，大量列表全量构建不回收`,
      suggestion: '将长列表的 ForEach 逐步迁移到 LazyForEach + IDataSource',
      evidence: { forEachCount, lazyForEachCount }
    });
  } else if (forEachCount >= 10 && lazyForEachCount > 0 && forEachCount / lazyForEachCount > 10) {
    findings.push({
      hotspot_type: 'list_non_lazy',
      severity: 'medium',
      location: `${firstForEach ? buildNodeLocation(firstForEach) : "root"} — ${forEachCount} ForEach, ${lazyForEachCount} LazyForEach (ratio: ${(forEachCount/lazyForEachCount).toFixed(1)}:1)`,
      description: `ForEach 与 LazyForEach 比率 ${(forEachCount/lazyForEachCount).toFixed(1)}:1，大部分列表未用懒加载`,
      suggestion: '将 ForEach 逐步迁移到 LazyForEach',
      evidence: { forEachCount, lazyForEachCount, ratio: forEachCount/lazyForEachCount }
    });
  }
  return findings;
}

function detectArkWebExcessive(root) {
  const findings = [];
  const webNodes = findNodesByTag(root, ['Web', 'web']);
  // Count Web nodes that are not on main tree (pre-rendered/pre-heated)
  let detachedWebCount = 0;
  for (const web of webNodes) {
    const isOnMainTree = web.raw?.find(l => l.includes('IsOnMainTree: 1'));
    if (!isOnMainTree) detachedWebCount++;
  }
  if (webNodes.length >= 3) {
    findings.push({
      hotspot_type: 'arkweb_excessive',
      severity: webNodes.length >= 5 ? 'high' : 'medium',
      location: `${webNodes[0] ? buildNodeLocation(webNodes[0]) : "root"} — ${webNodes.length} Web nodes (${detachedWebCount} detached/pre-rendered)`,
      description: `${webNodes.length} 个 Web 组件存活${detachedWebCount > 0 ? `，其中 ${detachedWebCount} 个脱离主树（预渲染/预热）` : ''}，每个 Web 节点含独立渲染进程，内存开销大`,
      suggestion: '减少预渲染/预热数量到 1 个；离开页面时释放未使用的 Web 节点；按需创建而非预创建',
      evidence: { webCount: webNodes.length, detachedWebCount }
    });
  }
  return findings;
}

// ── H-04 dump 侧信号: Tab 动画未禁用（animationDuration=0 或 animationMode!=NO_ANIMATION）──
function detectTabsAnimationEnabled(root) {
  const findings = [];
  const tabsNodes = findNodesByTag(root, ['Tabs', 'tabs']);
  for (const tabs of tabsNodes) {
    const f = tabs.facts || {};
    const animDur = f.animationDuration;
    const animMode = f.animationMode;
    // 只检测字段存在的情况（新格式 dump），旧 dump 无此字段则跳过
    const issues = [];
    if (animDur !== undefined && animDur !== null) {
      if (animDur === '0' || animDur === 0) {
        issues.push(`animationDuration=${animDur}（动画系统仍激活）`);
      }
    }
    if (animMode !== undefined && animMode !== null) {
      const modeStr = String(animMode).toUpperCase();
      if (!modeStr.includes('NO_ANIMATION')) {
        issues.push(`animationMode=${animMode}（未设为 NO_ANIMATION）`);
      }
    }
    if (issues.length > 0) {
      const id = f.ID || tabs.uid;
      findings.push({
        hotspot_type: 'tabs_animation_midpage',
        severity: 'medium',
        location: `${buildNodeLocation(tabs)} (${issues.join(', ')})`,
        description: `Tabs 节点动画未完全禁用：${issues.join('；')}。动画切换会滑过中间页签触发冗余加载，增加内存开销`,
        suggestion: '设置 .animationMode(AnimationMode.NO_ANIMATION) 完全禁用动画，改为直跳模式，避免滑过中间页触发加载',
        evidence: { animationDuration: animDur, animationMode: animMode, issues, detectionSide: 'dump' }
      });
    }
  }
  return findings;
}

// ── H-19: 缓存池清空使能未设置（MemOpt/ReusableMemOpt/RepeatMemOpt）──
function detectCachePoolOptNotSet(root) {
  const findings = [];
  // 遍历所有节点，检查缓存池清空使能字段
  function walk(node) {
    const f = node.facts || {};
    const issues = [];
    // 只检测字段存在但未启用的情况（字段不存在=旧 dump 格式，跳过）
    if (f.MemOpt !== undefined) {
      const val = String(f.MemOpt).toLowerCase();
      if (val === 'false' || val === '0' || val === 'disabled' || val === 'off') {
        issues.push(`MemOpt=${f.MemOpt}（通用内存优化未启用）`);
      }
    }
    if (f.ReusableMemOpt !== undefined) {
      const val = String(f.ReusableMemOpt).toLowerCase();
      if (val === 'false' || val === '0' || val === 'disabled' || val === 'off') {
        issues.push(`ReusableMemOpt=${f.ReusableMemOpt}（Reusable 缓存清空未启用）`);
      }
    }
    if (f.RepeatMemOpt !== undefined) {
      const val = String(f.RepeatMemOpt).toLowerCase();
      if (val === 'false' || val === '0' || val === 'disabled' || val === 'off') {
        issues.push(`RepeatMemOpt=${f.RepeatMemOpt}（Repeat 缓存清空未启用）`);
      }
    }
    if (issues.length > 0) {
      const id = f.ID || node.uid;
      findings.push({
        hotspot_type: 'cache_pool_opt_not_set',
        severity: 'medium',
        location: `${buildNodeLocation(node)} (${issues.join(', ')})`,
        description: `节点缓存池清空使能未设置：${issues.join('；')}。未启用清空会导致缓存池在页面离开后不释放，内存持续占用`,
        suggestion: '启用缓存池清空使能（MemOpt/ReusableMemOpt/RepeatMemOpt 设为 true），确保页面离开时缓存池被清空释放',
        evidence: { tag: node.tag, id, MemOpt: f.MemOpt, ReusableMemOpt: f.ReusableMemOpt, RepeatMemOpt: f.RepeatMemOpt }
      });
    }
    for (const child of (node.children || [])) walk(child);
  }
  walk(root);
  return findings;
}

// ─── 主分析流程 ─────────────────────────────────────────────────

async function analyzeDump(dumpPath, memoryCsvPath) {
  const { parseDump, parseJsonDump } = await loadParser();

  const text = readFileSync(dumpPath, 'utf8');
  const ext = extname(dumpPath).toLowerCase();
  const tree = ext === '.json' ? parseJsonDump(text) : parseDump(text);
  setParents(tree.root);  // 设置 parent 链供 buildNodeLocation 使用

  // Load memory baseline
  let memMap = new Map();
  const csvPath = memoryCsvPath || findMemoryCsv();
  if (csvPath) {
    try {
      memMap = loadMemoryCsv(csvPath);
    } catch {
      // Continue without memory map
    }
  }

  // Run all detection rules
  const allFindings = [
    ...detectHiddenPageSubtrees(tree.root, memMap),
    ...detectTabsCacheNotReleased(tree.root, memMap),
    ...detectPreloadedInvisibleTabs(tree.root, memMap),
    ...detectListNonLazy(tree.root),
    ...detectListCachedCountTooLarge(tree.root),
    ...detectDeepNesting(tree.root),
    ...detectCanvasFullsreen(tree.root),
    ...detectImageAnimatorExcessive(tree.root),
    ...detectVideoResident(tree.root),
    ...detectLargeImages(tree.root, memMap),
    ...detectDetachedCaches(tree.root),
    ...detectNavStackTooDeep(tree.root),
    ...detectXComponentLeak(tree.root),
    ...detectImperativeNodes(tree.root),
    ...detectGridSwiperNotLazy(tree.root),
    ...detectDeepTreeDepth(tree.root),
    ...detectHeavyDetachedRoots(tree.root),
    ...detectImageAutoSizeMismatch(tree.root),
    ...detectForEachRatio(tree.root),
    ...detectArkWebExcessive(tree.root),
    ...detectTabsAnimationEnabled(tree.root),
    ...detectCachePoolOptNotSet(tree.root),
  ];

  // Deduplicate by location+type
  const seen = new Set();
  const findings = allFindings.filter(f => {
    const key = `${f.hotspot_type}|${f.location}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Add file and line fields to each finding
  const findingsWithFile = findings.map(f => ({
    ...f,
    file: dumpPath,
    line: 0, // dump findings don't have line numbers, node info is in location
  }));

  // Build summary stats
  const stats = {
    node_count: tree.stats.nodeCount,
    max_depth: tree.stats.maxDepth,
    tag_types: Object.keys(tree.stats.tagCounts).length,
    total_findings: findingsWithFile.length,
    by_severity: {
      high: findingsWithFile.filter(f => f.severity === 'high').length,
      medium: findingsWithFile.filter(f => f.severity === 'medium').length,
      low: findingsWithFile.filter(f => f.severity === 'low').length,
    },
    by_type: findingsWithFile.reduce((acc, f) => {
      acc[f.hotspot_type] = (acc[f.hotspot_type] || 0) + 1;
      return acc;
    }, {}),
  };

  return {
    schema_version: '1.0',
    analysis_type: 'dump',
    input_file: dumpPath,
    timestamp: new Date().toISOString(),
    stats,
    findings: findingsWithFile,
  };
}

// ─── CLI ────────────────────────────────────────────────────────

if (process.argv[1] && process.argv[1].endsWith('analyze-arkui-dump.mjs')) {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: node analyze-arkui-dump.mjs <dump-file> [--memory-csv <path>]');
    process.exit(1);
  }
  const dumpFile = args[0];
  let csvPath = null;
  const csvIdx = args.indexOf('--memory-csv');
  if (csvIdx !== -1 && args[csvIdx + 1]) {
    csvPath = args[csvIdx + 1];
  }

  analyzeDump(dumpFile, csvPath).then(result => {
    console.log(JSON.stringify(result, null, 2));
  }).catch(err => {
    console.error('Analysis failed:', err.message);
    process.exit(1);
  });
}

export { analyzeDump };
