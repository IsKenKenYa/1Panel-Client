#!/usr/bin/env node
'use strict';

/**
 * DevEco Studio CodeLinter 入口路径探测脚本
 *
 * 用法：
 *   node detect-codelinter.js                 // 自动探测，输出路径
 *   node detect-codelinter.js --json          // JSON 格式输出
 *   node detect-codelinter.js --custom "path" // 指定自定义 DevEco 安装目录
 *
 * 探测策略（按优先级）：
 *   1. --custom 参数指定的路径
 *   2. DEVECO_STUDIO_HOME 环境变量
 *   3. 平台标准安装位置（精确路径，支持 Windows/macOS/Linux/HarmonyOS）
 *   4. 在已知父目录中递归搜索（深度 3 层），匹配含 "deveco" 的目录名
 *   5. 在所有盘符根目录浅层搜索（仅 Windows）
 *
 * 支持的 DevEco Studio 目录命名模式：
 *   - "DevEco Studio"           （标准命名，含空格）
 *   - "DevEco-Studio"           （连字符命名）
 *   - "DevEco Studio865"        （版本号后缀）
 *   - "deveco-studio-26.0.1.272"           （版本化命名）
 *   - "deveco-studio-26.0.1.272(.win)"     （带平台标识）
 *   - "DevEco-Studio-26.0.1.272(.win)"     （大小写混合）
 *   以及其他含 "deveco" 关键词的变体
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Windows 控制台中文编码修复：切换代码页为 UTF-8（65001）
// 避免 console.log 中文输出乱码（PowerShell/cmd 默认代码页可能为 GBK/936）
if (process.platform === 'win32') {
  try {
    require('child_process').execSync('chcp 65001', { stdio: 'ignore' });
  } catch (e) {
    // 忽略：无法切换代码页时不影响功能，仅中文输出可能乱码
  }
}

const CODELINTER_RELATIVE = path.join('plugins', 'codelinter', 'run', 'index.js');

// DevEco Studio 目录名匹配：含 "deveco" 关键词（不区分大小写）
// 覆盖 "DevEco Studio"、"deveco-studio-26.0.1.272(.win)" 等各种命名
const DEVECO_DIR_REGEX = /deveco/i;

// 递归搜索时跳过的目录名（小写），避免遍历无关的系统/项目目录
const SKIP_DIRS = new Set([
  // Windows 系统目录
  'windows', 'system32', 'syswow64', 'winsxs', 'assembly', 'driverstore',
  'servicing', 'win32', 'sysnative', 'drivers', 'etc',
  '$recycle.bin', 'system volume information', 'recovery',
  'programdata', 'temp', 'tmp', 'cache', 'cached',
  // macOS 系统目录
  'library', 'system', 'private', 'var', 'etc', 'opt',
  // 项目/构建目录
  'node_modules', 'oh_modules', 'build', '.git', '.svn', '.hg',
  'src', 'test', 'tests', '__tests__', 'fixtures', 'mocks',
  '.gradle', '.hvigor', '.idea', '.vscode', '.cxx',
  'common', 'features', 'products', 'entry', 'appscope',
  'hvigor', 'oh_modules', 'dist', 'out', 'bin',
  // 其他
  'music', 'videos', 'pictures', 'documents', 'desktop',
  'downloads', 'games', 'movies', 'media',
]);

/**
 * 判断目录名是否应跳过（递归搜索时）
 */
function shouldSkipDir(name) {
  const lower = name.toLowerCase();
  if (SKIP_DIRS.has(lower)) return true;
  // 跳过隐藏目录（macOS .app 除外，由上层单独处理）
  if (lower.startsWith('.') && !lower.endsWith('.app')) return true;
  return false;
}

/**
 * 获取当前平台的候选 DevEco Studio 安装路径
 * @returns {string[]} - 候选路径数组（精确路径 + 需搜索的父目录）
 */
function getCandidates() {
  const platform = process.platform;
  const candidates = [];
  const home = os.homedir();

  if (platform === 'darwin') {
    // macOS: .app bundle，可能命名为 DevEco-Studio.app 或 DevEco-Studio-26.0.1.272.app
    candidates.push('/Applications/DevEco-Studio.app/Contents');
    candidates.push(path.join(home, 'Applications', 'DevEco-Studio.app', 'Contents'));
    // 父目录递归搜索（覆盖版本化 .app 命名）
    candidates.push('/Applications');
    candidates.push(path.join(home, 'Applications'));
    candidates.push('/opt');
  } else if (platform === 'win32') {
    const localAppData = process.env.LOCALAPPDATA;
    if (localAppData) {
      // 精确路径
      candidates.push(path.join(localAppData, 'Huawei', 'DevEco Studio'));
      // 父目录递归搜索
      candidates.push(path.join(localAppData, 'Huawei'));
    }
    // C 盘标准安装位置
    candidates.push('C:\\Program Files\\Huawei\\DevEco Studio');
    candidates.push('C:\\Program Files (x86)\\Huawei\\DevEco Studio');
    candidates.push('C:\\Program Files\\Huawei');
    candidates.push('C:\\Program Files (x86)\\Huawei');
    candidates.push(path.join(home, 'AppData', 'Local', 'Huawei', 'DevEco Studio'));
    candidates.push(path.join(home, 'AppData', 'Local', 'Huawei'));
    // 用户常见自定义位置
    candidates.push(path.join(home, 'Tools'));
    candidates.push(path.join(home, 'Software'));
    candidates.push(path.join(home, 'DevEcoStudio'));
    candidates.push(path.join(home, 'DevEco Studio'));
    // D 盘
    if (fs.existsSync('D:\\')) {
      candidates.push('D:\\Huawei');
      candidates.push('D:\\Tools');
      candidates.push('D:\\Software');
      candidates.push('D:\\Program Files');
      candidates.push('D:\\Program Files (x86)');
      candidates.push('D:\\DevEco Studio');
      candidates.push('D:\\DevEcoStudio');
      candidates.push('D:\\');
    }
    // E 盘
    if (fs.existsSync('E:\\')) {
      candidates.push('E:\\Huawei');
      candidates.push('E:\\Tools');
      candidates.push('E:\\Software');
      candidates.push('E:\\');
    }
    // 其他盘符（F、G）浅层搜索
    for (const drive of ['F', 'G']) {
      if (fs.existsSync(drive + ':\\')) {
        candidates.push(drive + ':\\');
      }
    }
  } else if (platform === 'linux') {
    candidates.push('/opt/DevEco-Studio');
    candidates.push(path.join(home, '.local', 'share', 'Huawei', 'DevEco Studio'));
    candidates.push(path.join(home, '.local', 'share', 'Huawei'));
    candidates.push('/opt');
    candidates.push(path.join(home, 'opt'));
  } else if (platform === 'ohos') {
    // HarmonyOS / OpenHarmony
    candidates.push('/opt/deveco-studio');
    candidates.push(path.join(home, 'deveco-studio'));
    candidates.push(path.join(home, '.local', 'share', 'deveco-studio'));
    candidates.push('/opt');
    candidates.push('/data/opt');
    candidates.push('/data/local/tmp');
  }

  return candidates;
}

/**
 * 在指定目录下查找 codelinter 入口
 * 步骤 1：检查 <dir>/plugins/codelinter 目录是否存在（快速路径，存在则直接用）
 * 步骤 2：检查入口文件 run/index.js
 * @param {string} baseDir - DevEco Studio 安装根目录
 * @returns {string|null}
 */
function findCodelinterInDir(baseDir) {
  if (!baseDir || !fs.existsSync(baseDir)) {
    return null;
  }
  // 步骤 1：检查 <dir>/plugins/codelinter 目录是否存在
  const codelinterDir = path.join(baseDir, 'plugins', 'codelinter');
  try {
    if (!fs.existsSync(codelinterDir) || !fs.statSync(codelinterDir).isDirectory()) {
      return null;
    }
  } catch (e) {
    return null;
  }
  // 步骤 2：目录存在，检查入口文件
  const entry = path.join(codelinterDir, 'run', 'index.js');
  try {
    if (fs.existsSync(entry) && fs.statSync(entry).isFile()) {
      return entry;
    }
  } catch (e) {
    // ignore
  }
  return null;
}

/**
 * 递归搜索父目录下的 DevEco Studio 安装目录
 * 匹配含 "deveco" 关键词的目录名（覆盖各种命名变体）
 * @param {string} dir - 当前搜索目录
 * @param {number} depth - 当前递归深度
 * @param {number} maxDepth - 最大递归深度
 * @param {Set<string>} visited - 已访问目录（防符号链接循环）
 * @returns {string|null}
 */
function searchRecursive(dir, depth, maxDepth, visited) {
  if (depth >= maxDepth) return null;

  // 规范化路径用于去重
  let realDir;
  try {
    realDir = fs.realpathSync(dir);
  } catch (e) {
    return null;
  }
  if (visited.has(realDir)) return null;
  visited.add(realDir);

  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    return null;
  }

  for (const entry of entries) {
    if (!entry.isDirectory() && !entry.isSymbolicLink()) continue;

    const name = entry.name;
    if (shouldSkipDir(name)) continue;

    const childPath = path.join(dir, name);

    // macOS .app bundle 特殊处理
    if (name.toLowerCase().endsWith('.app') && /deveco/i.test(name)) {
      const contentsDir = path.join(childPath, 'Contents');
      const found = findCodelinterInDir(contentsDir);
      if (found) return found;
      continue;
    }

    // 匹配 DevEco 目录名（含 "deveco" 关键词）
    if (DEVECO_DIR_REGEX.test(name)) {
      const found = findCodelinterInDir(childPath);
      if (found) return found;
      // 在 DevEco 目录内继续搜索一层（处理嵌套安装）
      const deep = searchRecursive(childPath, depth + 1, maxDepth, visited);
      if (deep) return deep;
      continue;
    }

    // 非 DevEco 目录：继续递归（寻找嵌套路径如 D:\Tools\Huawei\deveco-studio-...）
    const found = searchRecursive(childPath, depth + 1, maxDepth, visited);
    if (found) return found;
  }

  return null;
}

/**
 * 在指定父目录中搜索 DevEco Studio（含递归）
 * @param {string} parentDir - 父目录
 * @param {number} [maxDepth=3] - 最大递归深度
 * @returns {string|null}
 */
function searchInParent(parentDir, maxDepth) {
  if (maxDepth === undefined) maxDepth = 3;
  if (!parentDir || !fs.existsSync(parentDir)) {
    return null;
  }

  // 先检查 <dir>/plugins/codelinter 是否存在（存在直接用）
  const direct = findCodelinterInDir(parentDir);
  if (direct) return direct;

  // 不存在则往子目录递归搜索
  return searchRecursive(parentDir, 0, maxDepth, new Set());
}

/**
 * 在所有盘符根目录浅层搜索（仅 Windows）
 * 深度限制为 2 层，避免遍历全盘
 * @returns {string|null}
 */
function searchAllDrives() {
  if (process.platform !== 'win32') return null;

  // 枚举所有可用盘符
  for (let code = 67; code <= 90; code++) { // C(67) ~ Z(90)
    const drive = String.fromCharCode(code);
    const driveRoot = drive + ':\\';
    if (!fs.existsSync(driveRoot)) continue;

    // 盘符根目录用浅层搜索（深度 2）
    const found = searchInParent(driveRoot, 2);
    if (found) return found;
  }
  return null;
}

/**
 * 探测 CodeLinter 入口路径
 * @param {string} [customPath] - 可选的自定义 DevEco 安装目录
 * @returns {{path: string|null, source: string, searched: string[]}}
 */
function detect(customPath) {
  const searched = [];

  // 1. 自定义路径优先
  if (customPath) {
    searched.push(customPath);
    const found = findCodelinterInDir(customPath) || searchInParent(customPath);
    if (found) {
      return { path: found, source: 'custom', searched };
    }
  }

  // 2. 环境变量
  const envPath = process.env.DEVECO_STUDIO_HOME;
  if (envPath) {
    searched.push(envPath);
    const found = findCodelinterInDir(envPath) || searchInParent(envPath);
    if (found) {
      return { path: found, source: 'env', searched };
    }
  }

  // 3. 候选路径（精确 + 递归搜索）
  const candidates = getCandidates();
  for (const candidate of candidates) {
    searched.push(candidate);
    const found = findCodelinterInDir(candidate) || searchInParent(candidate);
    if (found) {
      return { path: found, source: 'auto', searched };
    }
  }

  // 4. 全盘浅层搜索（最后手段，仅 Windows）
  if (process.platform === 'win32') {
    const found = searchAllDrives();
    if (found) {
      searched.push('(全盘搜索)');
      return { path: found, source: 'drive-scan', searched };
    }
  }

  return { path: null, source: 'not-found', searched };
}

/**
 * 格式化输出
 * @param {{path: string|null, source: string, searched: string[]}} result
 * @param {boolean} json - 是否 JSON 格式
 */
function output(result, json) {
  if (json) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (result.path) {
    console.log('CODELINTER=' + result.path);
    console.log('SOURCE=' + result.source);
  } else {
    console.error('未找到 DevEco Studio CodeLinter 入口');
    console.error('');
    console.error('已搜索以下路径：');
    for (const p of result.searched) {
      console.error('  - ' + p);
    }
    console.error('');
    console.error('请提供 DevEco Studio 的安装目录，');
    console.error('该目录下应包含子路径: plugins/codelinter/run/index.js');
    console.error('');
    console.error('常见安装目录名称：');
    console.error('  - DevEco Studio');
    console.error('  - DevEco-Studio');
    console.error('  - deveco-studio-<版本号>');
    console.error('  - deveco-studio-<版本号>(.win)');
    console.error('');
    console.error('指定方式：');
    console.error('  1. 设置环境变量 DEVECO_STUDIO_HOME');
    console.error('  2. 运行时传参: node detect-codelinter.js --custom "DevEco安装目录"');
    process.exit(1);
  }
}

// CLI 入口
if (require.main === module) {
  const args = process.argv.slice(2);
  let json = false;
  let customPath = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--json') {
      json = true;
    } else if (args[i] === '--custom' && i + 1 < args.length) {
      customPath = args[i + 1];
      i++;
    } else if (args[i] === '-h' || args[i] === '--help') {
      console.log('用法: node detect-codelinter.js [--json] [--custom <path>]');
      console.log('');
      console.log('选项:');
      console.log('  --json          JSON 格式输出结果');
      console.log('  --custom <path> 指定 DevEco Studio 安装目录');
      console.log('  -h, --help      显示帮助');
      console.log('');
      console.log('探测顺序:');
      console.log('  1. --custom 参数');
      console.log('  2. DEVECO_STUDIO_HOME 环境变量');
      console.log('  3. 平台标准安装位置（Win/Mac/Linux/HarmonyOS）');
      console.log('  4. 已知父目录递归搜索（深度 3 层）');
      console.log('  5. 全盘浅层搜索（仅 Windows）');
      console.log('');
      console.log('支持的目录命名:');
      console.log('  DevEco Studio / DevEco-Studio / deveco-studio-*');
      process.exit(0);
    }
  }

  const result = detect(customPath);
  output(result, json);
}

module.exports = { detect, getCandidates, findCodelinterInDir, searchInParent, CODELINTER_RELATIVE };
