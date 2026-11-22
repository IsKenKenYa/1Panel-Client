#!/usr/bin/env node
/**
 * ArkUI 源码内存热点分析脚本
 *
 * 扫描 .ets 源码文件，通过关键词/正则 + 示例库/反模式匹配，
 * 检测 5 类内存热点 + ArkUI 特定反模式（Canvas渐变/ImageAnimator/Tabs等），
 * 输出标准化 schema（JSON）供报告生成和 skill ④ 消费。
 *
 * 用法:
 *   node analyze-arkui-source.mjs <file-or-dir> [--output <path>]
 *
 * 输出: stdout JSON schema (findings 数组)
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';

// ─── 文件收集 ───────────────────────────────────────────────────

function collectEtsFiles(input) {
  const stats = statSync(input);
  if (stats.isFile()) {
    return [input];
  }
  if (stats.isDirectory()) {
    const results = [];
    function walk(dir) {
      const entries = readdirSync(dir, { withFileTypes: true });
      for (const ent of entries) {
        const full = join(dir, ent.name);
        if (ent.isDirectory()) {
          if (ent.name === 'node_modules' || ent.name === '.git' || ent.name === 'build' || ent.name === 'oh_modules') continue;
          walk(full);
        } else if (ent.isFile() && (ent.name.endsWith('.ets') || ent.name.endsWith('.ts'))) {
          results.push(full);
        }
      }
    }
    walk(input);
    return results;
  }
  return [];
}

// ─── 规则引擎 ───────────────────────────────────────────────────

/**
 * 每条规则:
 * { id, hotspot_type, severity, pattern (RegExp), check (fn), description, suggestion }
 * check(fileText, filePath) returns finding[] (empty if no match)
 */

const rules = [
  // ── H-01: 不可见页面条件渲染 ──
  {
    id: 'R-01',
    hotspot_type: 'invisible_page',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      // visibility(Visibility.Hidden) with complex component or custom component call
      const visPattern = /visibility\s*\(\s*Visibility\.Hidden\s*\)/g;
      let match;
      while ((match = visPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const context = text.substring(Math.max(0, match.index - 500), match.index + 500);
        const childCount = (context.match(/\.(?:Text|Image|Button|Column|Row|Stack|List|ForEach|LazyForEach)\s*\(/g) || []).length;
        // Also check if visibility(Hidden) is applied to a custom component (e.g., HiddenFeedPage({...}).visibility(Hidden))
        const beforeText = text.substring(Math.max(0, match.index - 200), match.index);
        const isCustomComponent = /\w+\s*\([^)]*\)\s*\.?\s*$/.test(beforeText.trim()) || beforeText.includes('HiddenFeedPage') || beforeText.match(/\)\s*$/);
        if (childCount > 3 || isCustomComponent) {
          findings.push({
            hotspot_type: 'invisible_page',
            severity: 'high',
            location: `${filePath}:${lineNum}`,
            description: `visibility(Visibility.Hidden) 隐藏了${isCustomComponent ? '自定义组件' : `包含 ${childCount} 个子组件的复杂页面`}, 隐藏页面被构建但用户看不到, 内存 100% 浪费`,
            suggestion: '使用条件渲染 if(visible){Page()} 替代 visibility(Hidden); 不构建时零成本',
            evidence: { line: lineNum, childCount, isCustomComponent, pattern: 'visibility(Visibility.Hidden)' }
          });
        }
      }
      return findings;
    }
  },

  // ── H-02: Tabs cachedMaxCount 未设或过大 ──
  {
    id: 'R-02',
    hotspot_type: 'tabs_cache_not_released',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      const tabsPattern = /Tabs\s*\(/g;
      let match;
      while ((match = tabsPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const after = text.substring(match.index, match.index + 2000);
        const tabContentCount = (after.match(/TabContent\s*\(/g) || []).length;
        if (tabContentCount < 3) continue;

        // Check cachedMaxCount
        const cmcMatch = after.match(/cachedMaxCount\s*\(\s*([^,)]+)/);
        if (!cmcMatch) {
          // No cachedMaxCount
          findings.push({
            hotspot_type: 'tabs_cache_not_released',
            severity: 'high',
            location: `${filePath}:${lineNum}`,
            description: `Tabs 组件有 ${tabContentCount} 个 TabContent 但未设置 cachedMaxCount, 所有已访问页签默认全缓存不释放`,
            suggestion: '设置 .cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE) 限制缓存数量',
            evidence: { line: lineNum, tabCount: tabContentCount }
          });
        } else {
          // Has cachedMaxCount, check if value is too large (>= tab count or constant reference)
          const cmcValue = cmcMatch[1].trim();
          let cmcNum = 0;
          if (/^\d+$/.test(cmcValue)) {
            cmcNum = parseInt(cmcValue);
          } else {
            // Constant reference, try resolve
            const shortName = cmcValue.split('.').pop();
            const allMatches = [...text.matchAll(new RegExp(shortName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*(?::\\s*\\w+\\s*)?=(?!=)\\s*(\\d+)', 'g'))].map(m => parseInt(m[1])).filter(v => !isNaN(v));
            if (allMatches.length > 0) cmcNum = Math.max(...allMatches);
          }
          // cachedMaxCount >= tab count means equivalent to no limit
          if (cmcNum >= tabContentCount) {
            findings.push({
              hotspot_type: 'tabs_cache_not_released',
              severity: 'high',
              location: `${filePath}:${lineNum}`,
              description: `Tabs 组件有 ${tabContentCount} 个 TabContent, cachedMaxCount=${cmcValue}(${cmcNum}) 等效不设上限, 全部缓存不释放`,
              suggestion: `将 cachedMaxCount 设为 1-2（当前页+两侧各1页=3页缓存），超出自动释放`,
              evidence: { line: lineNum, tabCount: tabContentCount, cachedMaxCount: cmcNum }
            });
          }
        }
      }
      return findings;
    }
  },

  // ── H-03: preloadItems 预加载 ──
  {
    id: 'R-03',
    hotspot_type: 'tabs_preload_invisible',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      const pattern = /\.preloadItems\s*\(/g;
      let match;
      while ((match = pattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        // Check if called in onAppear
        const before = text.substring(Math.max(0, match.index - 500), match.index);
        const inOnAppear = before.includes('.onAppear') || before.includes('onAppear');
        findings.push({
          hotspot_type: 'tabs_preload_invisible',
          severity: inOnAppear ? 'high' : 'medium',
          location: `${filePath}:${lineNum}`,
          description: `调用 preloadItems() 预加载页签${inOnAppear ? ' (在 onAppear 中调用, 进入即预加载)' : ''}, 未访问页会被构建并常驻内存`,
          suggestion: '仅在用户有明确意图时预加载相邻页; 不要在 Tabs.onAppear 预加载非相邻页签',
          evidence: { line: lineNum, inOnAppear }
        });
      }
      return findings;
    }
  },

  // ── H-04: Tabs 动画未关闭 ──
  {
    id: 'R-04',
    hotspot_type: 'tabs_animation_midpage',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      const tabsPattern = /Tabs\s*\(/g;
      let match;
      while ((match = tabsPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const after = text.substring(match.index, match.index + 2000);
        const tabCount = (after.match(/TabContent\s*\(/g) || []).length;
        if (tabCount >= 3) {
          // Check if animationMode is controlled by a Service constant (ternary)
          const hasAnimationModeTernary = /animationMode\s*\([^)]*\?\s*[^:]*:\s*[^)]*\)/.test(after) ||
                                          /animationMode\s*\(\s*\w+\.\w+/.test(after);
          // No animationMode at all, or controlled by constant (not fixed NO_ANIMATION)
          const hasFixedNoAnimation = after.includes('NO_ANIMATION') && !hasAnimationModeTernary;
          if (!hasFixedNoAnimation) {
            findings.push({
              hotspot_type: 'tabs_animation_midpage',
              severity: 'medium',
              location: `${filePath}:${lineNum}`,
              description: `Tabs 有 ${tabCount} 个页签${hasAnimationModeTernary ? '，animationMode 由 Service 常量控制（B 版可能启用滑动动画）' : '且未设 animationMode(NO_ANIMATION)'}，默认滑动动画会滑过中间页触发加载`,
              suggestion: '设置 .animationMode(AnimationMode.NO_ANIMATION) 直跳, 避免滑过中间页触发加载',
              evidence: { line: lineNum, tabCount, constantControlled: hasAnimationModeTernary }
            });
          }
        }
      }
      return findings;
    }
  },

  // ── H-05: List ForEach 代替 LazyForEach ──
  {
    id: 'R-05',
    hotspot_type: 'list_non_lazy',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      // Find List blocks containing ForEach (not LazyForEach)
      // Find scrollable containers (List/Grid/Swiper/WaterFlow) containing ForEach
      const listPattern = /(?:List|Grid|Swiper|WaterFlow)\s*\(/g;
      let match;
      while ((match = listPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const body = text.substring(match.index, match.index + 3000);
        // Check for ForEach usage - detect even if LazyForEach also exists (conditional branch)
        if (body.includes('ForEach(')) {
          // Check if ForEach is in a conditional branch (if/else) that could be active
          const hasConditionalForEach = /if\s*\([^)]*\)\s*\{[^}]*ForEach\s*\(/.test(body) ||
                                          /\?\s*[^:]*ForEach/.test(body);
          // If both ForEach and LazyForEach exist, it's likely a conditional branch (A/B version)
          // Still report if ForEach is present (B version activates it)
          findings.push({
            hotspot_type: 'list_non_lazy',
            severity: 'high',
            location: `${filePath}:${lineNum}`,
            description: hasConditionalForEach
              ? 'List 内条件分支中使用 ForEach（B 版启用全量加载），一次性全量建好所有子组件，离屏不回收'
              : 'List 内使用 ForEach 而非 LazyForEach, 一次性全量建好所有子组件, 离屏不回收, 内存随 N 线性增长',
            suggestion: '将 ForEach 替换为 LazyForEach + IDataSource 实现, 仅建可见行+缓冲行',
            evidence: { line: lineNum, uses: 'ForEach', conditional: hasConditionalForEach }
          });
        }
      }
      return findings;
    }
  },

  // ── H-06: cachedCount 过大 ──
  {
    id: 'R-06',
    hotspot_type: 'list_cachedcount_too_large',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      // Match cachedCount with number literal OR constant reference (e.g., Service.CACHED_COUNT)
      const pattern = /\.cachedCount\s*\(\s*([^)]+)\s*\)/g;
      let match;
      while ((match = pattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const rawValue = match[1].trim();
        let count = 0;
        if (/^\d+$/.test(rawValue)) {
          count = parseInt(rawValue);
        } else {
          // Constant reference (e.g., ListCachedCountService.CACHED_COUNT)
          // Try to resolve from same file first
          const shortName = rawValue.split('.').pop();
          const constPattern = new RegExp(shortName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*(?::\\s*\\w+\\s*)?=(?!=)\\s*(\\d+)', 'g');
          const allConstMatches = [...text.matchAll(constPattern)].map(m => parseInt(m[1])).filter(v => !isNaN(v));
          if (allConstMatches.length > 0) count = Math.max(...allConstMatches); // take max value (B version is the larger one)
          // If not found, check if it's a Service constant (can't resolve cross-file, but flag as potential)
          if (count === 0 && rawValue.includes('.')) {
            // Can't resolve cross-file constant, but flag if pattern looks like a Service constant
            count = -1; // sentinel: constant reference, can't determine value
          }
        }
        if (count > 3 || count === -1) {
          findings.push({
            hotspot_type: 'list_cachedcount_too_large',
            severity: count > 30 || count === -1 ? 'high' : 'medium',
            location: `${filePath}:${lineNum}`,
            description: count > 0
              ? `cachedCount(${count}) 设置过大, 可见区外预建 ${count * 2} 项离屏组件常驻内存`
              : `cachedCount(${rawValue}) 使用常量引用, 可能在 B 版设置过大, 需检查 ${rawValue} 的实际值`,
            suggestion: 'cachedCount 设为 1-3, 一般不超过 5; 离屏节点应自动回收',
            evidence: { line: lineNum, cachedCount: count > 0 ? count : rawValue }
          });
        }
      }
      return findings;
    }
  },

  // ── H-07: 布局冗余深嵌套 ──
  {
    id: 'R-07',
    hotspot_type: 'layout_redundant_nesting',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      const lines = text.split('\n');
      // Detect deep nesting: count consecutive container components with increasing indent
      // All ArkUI container components: layout + scrollable + navigation + framework wrappers
      const containerRe = /^(Stack|Column|Row|Flex|Grid|GridItem|List|ListItem|Swiper|WaterFlow|Scroll|RelativeContainer|Navigation|NavDestination|Tabs|TabContent|__Common__|IfElse|ForEach|LazyForEach|Column|Row)\s*[\(\{]/;
      let maxChain = 0;
      let chainStart = 0;
      let currentChain = 0;
      let chainIndent = -1;

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const trimmed = line.trimStart();
        const indent = line.length - trimmed.length;

        if (containerRe.test(trimmed)) {
          if (chainIndent === -1 || indent > chainIndent) {
            if (currentChain === 0) chainStart = i + 1;
            currentChain++;
            chainIndent = indent;
            if (currentChain > maxChain) {
              maxChain = currentChain;
            }
          } else if (indent < chainIndent) {
            currentChain = Math.max(0, currentChain - 1);
            chainIndent = indent;
          }
        } else if (indent < chainIndent && !trimmed.startsWith('//') && trimmed.length > 0) {
          currentChain = 0;
          chainIndent = -1;
        }
      }

      if (maxChain > 8) {
        findings.push({
          hotspot_type: 'layout_redundant_nesting',
          severity: maxChain > 12 ? 'high' : 'medium',
          location: `${filePath}:${chainStart}`,
          description: `检测到 ${maxChain} 层连续容器嵌套, 冗余节点导致组件树膨胀`,
          suggestion: '扁平化布局: @Builder 分解各区域, 每区 2-4 层嵌套; 移除无内容空容器包裹',
          evidence: { maxChainDepth: maxChain, startLine: chainStart }
        });
      }

      // Detect three-layer ForEach
      const forEachCount = (text.match(/ForEach\s*\(/g) || []).length;
      const lazyForEachCount = (text.match(/LazyForEach\s*\(/g) || []).length;
      if (forEachCount >= 3) {
        // Check if nested (three-layer)
        const triplePattern = /ForEach\s*\([^}]*ForEach\s*\([^}]*ForEach\s*\(/s;
        if (triplePattern.test(text)) {
          const firstLine = text.substring(0, text.indexOf('ForEach')).split('\n').length;
          findings.push({
            hotspot_type: 'layout_redundant_nesting',
            severity: 'medium',
            location: `${filePath}:${firstLine}`,
            description: `检测到三层嵌套 ForEach (分组→分行→分单元格), 应拍平为单层遍历`,
            suggestion: 'ForEach 单层遍历, 不要分组→分行→分单元格三层嵌套',
            evidence: { nestedForEach: 3, line: firstLine }
          });
        }
      }

      return findings;
    }
  },

  // ── H-08: Canvas 替代原生渐变 ──
  {
    id: 'R-08',
    hotspot_type: 'canvas_gradient',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      // Detect Canvas component + gradient anywhere in file (including via Service)
      if (text.includes('Canvas') && (text.includes('createLinearGradient') || text.includes('createRadialGradient') || text.includes('Gradient'))) {
        // Find the Canvas( line
        const canvasMatch = text.match(/Canvas\s*\(/);
        const lineNum = canvasMatch ? text.substring(0, canvasMatch.index).split('\n').length : 1;
        findings.push({
          hotspot_type: 'canvas_gradient',
          severity: 'medium',
          location: `${filePath}:${lineNum}`,
          description: 'Canvas 组件用于绘制渐变 (createLinearGradient/fillRect), 会分配 GPU/DMA surface (全屏约数十 MiB)',
          suggestion: '静态渐变背景用 Column().linearGradient({ direction, colors }) 声明式接口, 走 shader 路径 O(1) 内存',
          evidence: { line: lineNum, uses: 'createLinearGradient', viaService: text.includes('USE_CANVAS') }
        });
      }
      return findings;
    }
  },

  // ── H-09: ImageAnimator 帧集过量 ──
  {
    id: 'R-09',
    hotspot_type: 'image_animator_excessive',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      // Detect ImageAnimator in file
      if (!text.includes('ImageAnimator')) return findings;

      // Search entire file for frameCount as class member or variable (supports type annotation)
      const frameCountMatch = text.match(/frameCount\s*(?::\s*\w+\s*)?=\s*(\d+)/);
      const frameCount = frameCountMatch ? parseInt(frameCountMatch[1]) : 0;
      const hasInfinite = text.includes('iterations(-1)') || text.includes('iterations: -1');

      if (frameCount > 10) {
        const lineNum = text.substring(0, text.indexOf('frameCount')).split('\n').length;
        findings.push({
          hotspot_type: 'image_animator_excessive',
          severity: frameCount > 20 ? 'high' : 'medium',
          location: `${filePath}:${lineNum}`,
          description: `ImageAnimator 有 ${frameCount} 帧${hasInfinite ? ', iterations(-1) 无限循环' : ''}, 全部帧预解码常驻 native heap`,
          suggestion: '控制帧数 ≤ 10; 对帧图下采样到展示尺寸; 用 string/Resource src 让组件按需解码; aboutToDisappear 释放 PixelMap',
          evidence: { line: lineNum, frameCount, hasInfinite }
        });
      }
      return findings;
    }
  },

  // ── H-10: GC 后对象未释放 ──
  {
    id: 'R-10',
    hotspot_type: 'gc_retention',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      // on() with arrow function (not extracted to member)
      const onPattern = /\.on\s*\(\s*['"]\w+['"]\s*,\s*\(/g;
      let match;
      while ((match = onPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const after = text.substring(match.index, match.index + 200);
        // Check if it's an arrow function directly passed (not a member variable)
        if (after.match(/\.on\s*\(\s*['"]\w+['"]\s*,\s*\(?[\w]*\)?\s*=>/)) {
          // Check if there's a corresponding off
          const before = text.substring(Math.max(0, match.index - 1000), match.index);
          const after200 = text.substring(match.index, match.index + 2000);
          if (!after200.includes('.off(') && !before.includes('.off(')) {
            findings.push({
              hotspot_type: 'gc_retention',
              severity: 'high',
              location: `${filePath}:${lineNum}`,
              description: '使用 .on() 注册箭头函数回调但未检测到对应 .off() 解注册, 回调持有页面上下文导致无法释放',
              suggestion: '把回调提取成成员变量, 保证 on/off 传同一函数对象; aboutToDisappear 中调用 off()',
              evidence: { line: lineNum, pattern: '.on() without .off()' }
            });
          }
        }
      }
      return findings;
    }
  },

  // ── H-11: Video autoplay + 循环 ──
  {
    id: 'R-11',
    hotspot_type: 'video_resident',
    severity: 'low',
    check(text, filePath) {
      const findings = [];
      const pattern = /Video\s*\(\s*\{/g;
      let match;
      while ((match = pattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const after = text.substring(match.index, match.index + 2000);
        const hasAutoplay = after.includes('controller.start()') && (text.substring(0, match.index).includes('aboutToAppear') || after.includes('aboutToAppear'));
        const hasLoop = after.includes('onFinish') && after.includes('controller.start()');
        if (hasAutoplay || hasLoop) {
          findings.push({
            hotspot_type: 'video_resident',
            severity: 'low',
            location: `${filePath}:${lineNum}`,
            description: `Video 组件${hasAutoplay ? ' autoplay' : ''}${hasLoop ? ' 循环播放' : ''}, 解码器与缓冲常驻, native 媒体内存增长`,
            suggestion: '页面离开时 controller.stop() 停止播放; 短动画用 ImageAnimator 替代',
            evidence: { line: lineNum, hasAutoplay, hasLoop }
          });
        }
      }
      return findings;
    }
  },

  // ── Extra: PixelMap 未 release ──
  {
    id: 'R-13',
    hotspot_type: 'pixelmap_not_released',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      const createPattern = /createPixelMap\s*\(/g;
      let match;
      while ((match = createPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        // Check if there's a release in the same file
        const hasRelease = text.includes('.release()') || text.includes('pixelMap.release');
        if (!hasRelease) {
          findings.push({
            hotspot_type: 'pixelmap_not_released',
            severity: 'high',
            location: `${filePath}:${lineNum}`,
            description: 'createPixelMap() 被调用但文件中未检测到 pixelMap.release(), PixelMap 常驻 native heap',
            suggestion: '在 aboutToDisappear 中调用 pixelMap.release() 释放; 使用 try-finally 确保释放',
            evidence: { line: lineNum }
          });
          break; // Only report once per file
        }
      }
      return findings;
    }
  },

  // ── H-08: 页面栈过深 ──
  {
    id: 'R-14',
    hotspot_type: 'nav_stack_too_deep',
    severity: 'high',
    check(text, filePath) {
      const findings = [];
      // 检测 NavPathStack 只 push 无 pop
      const pushPattern = /pushPath|pushName|pushDestination/g;
      const popPattern = /pop\(\)|removeName|removePath/g;
      const pushCount = (text.match(pushPattern) || []).length;
      const popCount = (text.match(popPattern) || []).length;
      if (pushCount >= 3 && popCount === 0) {
        const firstPush = text.indexOf('pushPath') >= 0 ? text.indexOf('pushPath') : text.indexOf('pushName');
        const lineNum = text.substring(0, firstPush >= 0 ? firstPush : 0).split('\n').length;
        findings.push({
          hotspot_type: 'nav_stack_too_deep',
          severity: 'high',
          location: `${filePath}:${lineNum}`,
          description: `NavPathStack 有 ${pushCount} 次 push 操作但无 pop，页面栈持续增长不回收，NavDestination 数量会爆炸`,
          suggestion: '限制 NavPathStack 深度；用 replacePath 替代 pushPath 避免栈增长；离开页面时调用 pop() 释放',
          evidence: { pushCount, popCount, line: lineNum }
        });
      }
      return findings;
    }
  },

  // ── H-10: XComponent 未释放 ──
  {
    id: 'R-15',
    hotspot_type: 'xcomponent_not_released',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      const xcPattern = /XComponent\s*\(/g;
      let match;
      while ((match = xcPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        const hasDestroy = text.includes('onDestroy') && text.includes('release');
        if (!hasDestroy) {
          findings.push({
            hotspot_type: 'xcomponent_not_released',
            severity: 'medium',
            location: `${filePath}:${lineNum}`,
            description: 'XComponent 创建了 nativeWindow/Surface 但未检测到 onDestroy 释放逻辑，可能导致延迟释放',
            suggestion: '在 XComponent onDestroy 回调中释放 nativeWindow；页面离开时主动调用释放接口；确保 Surface 引用置空',
            evidence: { line: lineNum }
          });
          break;
        }
      }
      return findings;
    }
  },

  // ── H-12: 命令式节点缓存 ──
  {
    id: 'R-16',
    hotspot_type: 'imperative_node_cached',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      // 检测所有命令式节点 API：ArkTS 侧 + CAPI 侧
      const imperativePatterns = [
        { re: /new\s+BuilderNode\s*\(/g, name: 'BuilderNode', dispose: 'dispose()' },
        { re: /new\s+NodeController\s*\(/g, name: 'NodeController', dispose: 'disposeNode()' },
        { re: /new\s+FrameNode\s*\(/g, name: 'FrameNode', dispose: 'dispose()' },
        { re: /ArkUI_NodeHandle/g, name: 'ArkUI_NodeHandle (CAPI)', dispose: 'ArkUI_NodeDispose' },
        { re: /OH_ArkUI_NodeContent/g, name: 'ArkUI_NodeContent (CAPI)', dispose: 'OH_ArkUI_NodeContent_Dispose' },
        { re: /ArkUI_NodeCreate/g, name: 'ArkUI_NodeCreate (CAPI)', dispose: 'ArkUI_NodeDispose' },
      ];
      const hasAnyDispose = text.includes('dispose()') || text.includes('disposeNode()') || text.includes('NodeDispose') || text.includes('NodeContent_Dispose');
      for (const { re, name, dispose } of imperativePatterns) {
        re.lastIndex = 0;
        const match = re.exec(text);
        if (match) {
          const lineNum = text.substring(0, match.index).split('\n').length;
          if (!hasAnyDispose) {
            findings.push({
              hotspot_type: 'imperative_node_cached',
              severity: 'medium',
              location: `${filePath}:${lineNum}`,
              description: `${name} 创建命令式节点但未检测到 ${dispose} 释放调用，节点脱离声明式树管理不释放`,
              suggestion: '命令式节点使用后调用对应 dispose/release 释放；优先使用声明式 @Builder/@Reusable；NodeController 在不可见时 disposeNode()',
              evidence: { line: lineNum, type: name }
            });
            break;
          }
        }
      }
      return findings;
    }
  },

  // ── ArkWeb: 预渲染/预热过多 ──
  {
    id: 'R-17',
    hotspot_type: 'arkweb_excessive',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      // Detect createNWeb calls (Web component creation)
      const nwebPattern = /createNWeb\s*\(/g;
      const matches = [];
      let match;
      while ((match = nwebPattern.exec(text)) !== null) {
        matches.push({ index: match.index, line: text.substring(0, match.index).split('\n').length });
      }
      if (matches.length >= 3) {
        const lineNum = matches[0].line;
        // Check if in aboutToAppear (no cleanup in aboutToDisappear)
        const hasCleanup = text.includes('aboutToDisappear') && (text.includes('destroyNWeb') || text.includes('disposeNode') || text.includes('release'));
        findings.push({
          hotspot_type: 'arkweb_excessive',
          severity: matches.length >= 5 ? 'high' : 'medium',
          location: `${filePath}:${lineNum}`,
          description: `aboutToAppear 中创建 ${matches.length} 个 Web 组件节点${!hasCleanup ? '，无 aboutToDisappear 释放' : ''}，每个 Web 节点含独立渲染进程，内存开销大`,
          suggestion: '减少预渲染/预热数量到 1 个；离开页面时释放未使用的 Web 节点；按需创建而非预创建',
          evidence: { webCount: matches.length, line: lineNum, hasCleanup }
        });
      }
      return findings;
    }
  },

  // ── H-17 BuilderNode 销毁流程检测：逐一匹配每个实例，按变量名关联 3 步 ──
  {
    id: 'R-18',
    hotspot_type: 'builder_node_dispose_flow',
    severity: 'medium',
    check(text, filePath) {
      const findings = [];
      const builderPattern = /new\s+BuilderNode\s*(?:<[^>]*>)?\s*\(/g;
      let match;
      while ((match = builderPattern.exec(text)) !== null) {
        const lineNum = text.substring(0, match.index).split('\n').length;
        // 提取变量名（this.xxx = new BuilderNode / let xxx: BuilderNode = new / private xxx: BuilderNode）
        const beforeText = text.substring(Math.max(0, match.index - 80), match.index);
        const varMatch = beforeText.match(/([\w.]+)\s*(?::|=)\s*$/);
        const varName = varMatch ? varMatch[1] : null;
        // 按变量名关联查找该实例的 3 步销毁
        const missingSteps = [];
        if (varName) {
          // Step 1: NodeContainer(undefined) — 全局检查（无法按变量名精确关联 NodeContainer）
          const hasRemoveFromTree = new RegExp(`NodeContainer\\s*\\(\\s*(?:undefined\\s*\\)|\\[\\s*\\])`).test(text)
            || new RegExp(`\\.children\\s*\\(\\s*\\[\\s*\\]\\s*\\)`).test(text);
          if (!hasRemoveFromTree) missingSteps.push('① NodeContainer(undefined) 下UI树');
          // Step 2: varName.update(undefined)
          const escVar = varName.replace(/\./g, '\\.');
          if (!new RegExp(`${escVar}\\.update\\s*\\(\\s*undefined\\s*\\)`).test(text)) {
            missingSteps.push(`② ${varName}.update(undefined)`);
          }
          // Step 3: varName.dispose()
          if (!new RegExp(`${escVar}\\.dispose\\s*\\(\\s*\\)`).test(text)) {
            missingSteps.push(`③ ${varName}.dispose()`);
          }
        } else {
          // 无法提取变量名，退化为全文检查
          if (!/NodeContainer\s*\(\s*undefined\s*\)/.test(text) && !/\.children\s*\(\s*\[\s*\]\s*\)/.test(text)) {
            missingSteps.push('① NodeContainer(undefined) 下UI树');
          }
          if (!/\.update\s*\(\s*undefined\s*\)/.test(text)) missingSteps.push('② update(undefined)');
          if (!/\.dispose\s*\(\s*\)/.test(text)) missingSteps.push('③ dispose()');
        }
        if (missingSteps.length > 0) {
          findings.push({
            hotspot_type: 'builder_node_dispose_flow',
            severity: missingSteps.some(s => s.includes('dispose()')) ? 'high' : 'medium',
            location: `${filePath}:${lineNum}`,
            description: `BuilderNode 实例（${varName || '未识别变量名'}）销毁流程不完整，缺失：${missingSteps.join('、')}。正确流程：①NodeContainer(undefined)下UI树 → ②update(undefined) → ③dispose()`,
            suggestion: `BuilderNode 销毁必须按 3 步顺序执行：1) NodeContainer(undefined) 从UI树移除关联节点；2) ${varName || 'builder'}.update(undefined) 清空构建内容；3) ${varName || 'builder'}.dispose() 释放底层资源。当前缺失 ${missingSteps.length} 步。`,
            evidence: { line: lineNum, variable: varName || 'unknown', missingSteps }
          });
        }
      }
      return findings;
    }
  },
];

// ─── 主分析流程 ─────────────────────────────────────────────────

function analyzeSource(inputPath) {
  const files = collectEtsFiles(inputPath);
  const allFindings = [];

  for (const file of files) {
    const text = readFileSync(file, 'utf8');
    for (const rule of rules) {
      try {
        const findings = rule.check(text, file);
        allFindings.push(...findings);
      } catch (e) {
        // Rule error, skip
      }
    }
  }

  // Deduplicate
  const seen = new Set();
  const findings = allFindings.filter(f => {
    const key = `${f.hotspot_type}|${f.location}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  }).map(f => {
    // Extract file and line from location ("path:lineNum")
    const locParts = f.location ? f.location.split(':') : [];
    const lineIdx = locParts.length - 1;
    return {
      ...f,
      file: locParts.slice(0, lineIdx).join(':') || '',
      line: parseInt(locParts[lineIdx]) || f.evidence?.line || 0,
    };
  });

  const stats = {
    files_scanned: files.length,
    total_findings: findings.length,
    by_severity: {
      high: findings.filter(f => f.severity === 'high').length,
      medium: findings.filter(f => f.severity === 'medium').length,
      low: findings.filter(f => f.severity === 'low').length,
    },
    by_type: findings.reduce((acc, f) => {
      acc[f.hotspot_type] = (acc[f.hotspot_type] || 0) + 1;
      return acc;
    }, {}),
  };

  return {
    schema_version: '1.0',
    analysis_type: 'source',
    input_path: inputPath,
    timestamp: new Date().toISOString(),
    stats,
    findings,
  };
}

// ─── CLI ────────────────────────────────────────────────────────

if (process.argv[1] && process.argv[1].endsWith('analyze-arkui-source.mjs')) {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: node analyze-arkui-source.mjs <file-or-dir> [--output <path>]');
    process.exit(1);
  }
  const inputPath = args[0];
  const result = analyzeSource(inputPath);
  console.log(JSON.stringify(result, null, 2));
}

export { analyzeSource };
