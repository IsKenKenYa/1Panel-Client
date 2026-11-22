#!/usr/bin/env node

import { createHash } from 'node:crypto';
import {
  chmod,
  copyFile,
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  utimes,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HUAWEI_ID_LOGIN_PAGE_PATHS = [
  'HuaweiIDLogin/HuaweiIDLoginPage',
  'HuaweiIDLogin/ProtocolWebView',
];

const HUAWEI_ID_LOGIN_PAGE_FILES = [
  'HuaweiIDLoginPage.ets',
  'ProtocolWebView.ets',
];

class CopyBlocked extends Error {
  constructor(message, details = {}) {
    super(message);
    this.name = 'CopyBlocked';
    this.details = details;
  }
}

class BatchOperationError extends Error {
  constructor(message, failedFiles = []) {
    super(message);
    this.name = 'BatchOperationError';
    this.failedFiles = failedFiles;
  }
}

class ExecutionFailed extends Error {
  constructor(error, rolledBack, rollbackErrors = []) {
    super(`${error.name}: ${error.message}`);
    this.name = 'ExecutionFailed';
    this.rolledBack = rolledBack;
    this.rollbackErrors = rollbackErrors;
    this.failedFiles = error instanceof BatchOperationError ? error.failedFiles : [];
  }
}

function printHelp() {
  process.stdout.write(`Usage:
  node copy-huawei-id-login-assets.mjs --project <PROJECT_ROOT>

Options:
  --project <path>      HarmonyOS project root
  --asset-root <path>   Override assets/HuaweiIDLogin
  --workers <number>    Maximum parallel writes (default: 8)
  --dry-run             Validate and print the plan without writing
  --help                Show this help
`);
}

function parseArgs(argv) {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  const options = {
    project: undefined,
    assetRoot: path.resolve(scriptDir, '..', 'assets', 'HuaweiIDLogin'),
    workers: 8,
    dryRun: false,
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    const nextValue = () => {
      index += 1;
      if (index >= argv.length) {
        throw new Error(`参数缺少值：${argument}`);
      }
      return argv[index];
    };

    switch (argument) {
      case '--project':
        options.project = nextValue();
        break;
      case '--asset-root':
        options.assetRoot = nextValue();
        break;
      case '--workers':
        options.workers = Number.parseInt(nextValue(), 10);
        break;
      case '--dry-run':
        options.dryRun = true;
        break;
      case '--help':
      case '-h':
        options.help = true;
        break;
      default:
        throw new Error(`未知参数：${argument}`);
    }
  }

  if (options.help) {
    return options;
  }
  if (!options.project) {
    throw new Error('缺少 --project');
  }
  if (!Number.isInteger(options.workers) || options.workers < 1) {
    throw new Error('--workers 必须是正整数');
  }

  options.project = path.resolve(options.project);
  options.assetRoot = path.resolve(options.assetRoot);
  options.workers = Math.min(options.workers, 32);
  return options;
}

async function inspectPath(target) {
  try {
    const information = await lstat(target);
    if (information.isSymbolicLink()) {
      return { kind: 'symlink', information };
    }
    if (information.isFile()) {
      return { kind: 'file', information };
    }
    if (information.isDirectory()) {
      return { kind: 'directory', information };
    }
    return { kind: 'other', information };
  } catch (error) {
    if (error.code === 'ENOENT') {
      return { kind: 'missing' };
    }
    throw error;
  }
}

async function requireFile(file, label) {
  const inspected = await inspectPath(file);
  if (inspected.kind !== 'file') {
    throw new CopyBlocked(`${label}文件缺失：${file}`);
  }
}

async function requireDirectory(directory, label) {
  const inspected = await inspectPath(directory);
  if (inspected.kind !== 'directory') {
    throw new CopyBlocked(`${label}目录缺失或不是普通目录：${directory}`);
  }
}

async function collectFiles(root) {
  const files = [];

  async function visit(directory) {
    const entries = await readdir(directory, { withFileTypes: true });
    entries.sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
      const entryPath = path.join(directory, entry.name);
      if (entry.isSymbolicLink()) {
        throw new CopyBlocked(`资源库不允许符号链接：${entryPath}`);
      }
      if (entry.isDirectory()) {
        await visit(entryPath);
      } else if (entry.isFile()) {
        files.push(entryPath);
      }
    }
  }

  await visit(root);
  return files;
}

async function validateTargetPath(target, project) {
  const relative = path.relative(project, target);
  if (relative.startsWith(`..${path.sep}`) || relative === '..' || path.isAbsolute(relative)) {
    throw new CopyBlocked(`目标路径超出项目目录：${target}`);
  }

  const targetInfo = await inspectPath(target);
  if (!['missing', 'file'].includes(targetInfo.kind)) {
    throw new CopyBlocked(`目标文件路径不可写入：${target}`);
  }

  let parent = path.dirname(target);
  while (true) {
    const parentInfo = await inspectPath(parent);
    if (!['missing', 'directory'].includes(parentInfo.kind)) {
      throw new CopyBlocked(`目标父路径不是普通目录：${parent}`);
    }
    if (parent === project) {
      break;
    }
    parent = path.dirname(parent);
  }
}

async function readJson(file) {
  try {
    return JSON.parse(await readFile(file, 'utf8'));
  } catch (error) {
    throw new CopyBlocked(`无法解析 JSON：${file}: ${error.message}`);
  }
}

function cloneJson(value) {
  return JSON.parse(JSON.stringify(value));
}

function jsonKind(value) {
  if (value === null) {
    return 'null';
  }
  if (Array.isArray(value)) {
    return 'array';
  }
  return typeof value;
}

function isScalar(value) {
  return value === null || ['string', 'number', 'boolean'].includes(typeof value);
}

function mergeJsonValue(target, source, location) {
  const targetKind = jsonKind(target);
  const sourceKind = jsonKind(source);
  if (targetKind !== sourceKind) {
    throw new CopyBlocked(
      `JSON 类型冲突：${location}，目标为 ${targetKind}，模板为 ${sourceKind}`,
    );
  }

  if (targetKind === 'object') {
    const merged = cloneJson(target);
    for (const [key, sourceValue] of Object.entries(source)) {
      const childLocation = `${location}.${key}`;
      if (!Object.prototype.hasOwnProperty.call(merged, key)) {
        merged[key] = cloneJson(sourceValue);
      } else {
        merged[key] = mergeJsonValue(merged[key], sourceValue, childLocation);
      }
    }
    return merged;
  }

  if (targetKind === 'array') {
    const merged = cloneJson(target);
    const allItems = [...target, ...source];
    if (allItems.every(isScalar)) {
      const existing = new Set(merged.map((item) => JSON.stringify(item)));
      for (const item of source) {
        const key = JSON.stringify(item);
        if (!existing.has(key)) {
          merged.push(cloneJson(item));
          existing.add(key);
        }
      }
      return merged;
    }

    const allNamedObjects = allItems.every(
      (item) => item !== null
        && typeof item === 'object'
        && !Array.isArray(item)
        && Object.prototype.hasOwnProperty.call(item, 'name'),
    );
    if (allNamedObjects) {
      const existingNames = new Set(merged.map((item) => JSON.stringify(item.name)));
      for (const item of source) {
        const nameKey = JSON.stringify(item.name);
        if (!existingNames.has(nameKey)) {
          merged.push(cloneJson(item));
          existingNames.add(nameKey);
        }
      }
      return merged;
    }

    if (source.length === 0) {
      return merged;
    }
    throw new CopyBlocked(
      `JSON 数组无法可靠去重：${location}；仅支持标量数组或含 name 的对象数组`,
    );
  }

  return cloneJson(target);
}

async function planRequiredResourceTree(sourceRoot, targetRoot, project, plan, label) {
  await requireDirectory(sourceRoot, `资源库 ${label}`);

  const files = await collectFiles(sourceRoot);
  for (const source of files) {
    const relative = path.relative(sourceRoot, source);
    const normalized = relative.split(path.sep).join('/');
    if (label === 'entry/src/main/resources'
      && normalized === 'base/profile/main_pages.json') {
      plan.resourceFilesSkipped.push(`${label}/${normalized}`);
      continue;
    }

    const target = path.join(targetRoot, relative);
    let operation = 'copy';
    try {
      await validateTargetPath(target, project);
      const targetInfo = await inspectPath(target);
      if (path.extname(source).toLowerCase() === '.json' && targetInfo.kind === 'file') {
        operation = 'merge_json';
        const merged = mergeJsonValue(
          await readJson(target),
          await readJson(source),
          '$',
        );
        plan.jsonWrites.push({
          source,
          target,
          content: `${JSON.stringify(merged, null, 2)}\n`,
          category: 'resource',
        });
        plan.jsonMergedCount += 1;
      } else {
        plan.directCopies.push({
          source,
          target,
          category: 'resource',
          overwrites: targetInfo.kind === 'file',
        });
      }
    } catch (error) {
      plan.resourcePlanningFailures.push({
        source,
        target,
        operation,
        reason: error.message,
      });
    }
  }
}

async function planMainPages(project, plan) {
  const target = path.join(
    project,
    'entry',
    'src',
    'main',
    'resources',
    'base',
    'profile',
    'main_pages.json',
  );
  await requireFile(target, '项目 main_pages.json');
  const content = await readJson(target);
  if (!content || typeof content !== 'object' || !Array.isArray(content.src)) {
    throw new CopyBlocked(`main_pages.json 缺少 src 数组：${target}`);
  }

  const existing = new Set(content.src);
  const added = [];
  for (const page of HUAWEI_ID_LOGIN_PAGE_PATHS) {
    if (!existing.has(page)) {
      content.src.push(page);
      existing.add(page);
      added.push(page);
    }
  }
  plan.mainPagesAdded = added;
  plan.jsonWrites.push({
    target,
    content: `${JSON.stringify(content, null, 2)}\n`,
    category: 'main_pages',
  });
}

export async function buildPlan(project, assetRoot) {
  const sourceEtsRoot = path.join(
    assetRoot,
    'entry',
    'src',
    'main',
    'ets',
    'HuaweiIDLogin',
  );
  const targetEtsRoot = path.join(
    project,
    'entry',
    'src',
    'main',
    'ets',
    'HuaweiIDLogin',
  );
  const sourceAppScopeResources = path.join(assetRoot, 'AppScope', 'resources');
  const targetAppScopeResources = path.join(project, 'AppScope', 'resources');
  const sourceEntryResources = path.join(assetRoot, 'entry', 'src', 'main', 'resources');
  const targetEntryResources = path.join(project, 'entry', 'src', 'main', 'resources');

  await requireFile(path.join(project, 'AppScope', 'app.json5'), '项目 app.json5');
  await requireFile(
    path.join(project, 'entry', 'src', 'main', 'module.json5'),
    '项目 module.json5',
  );
  await requireDirectory(sourceAppScopeResources, '资源库 AppScope/resources');
  await requireDirectory(sourceEntryResources, '资源库 entry/src/main/resources');

  const plan = {
    assetRoot,
    directCopies: [],
    jsonWrites: [],
    templatePairs: [],
    jsonMergedCount: 0,
    resourceFilesSkipped: [],
    resourcePlanningFailures: [],
    mainPagesAdded: [],
  };

  const conflicts = [];
  for (const filename of HUAWEI_ID_LOGIN_PAGE_FILES) {
    const source = path.join(sourceEtsRoot, filename);
    const target = path.join(targetEtsRoot, filename);
    await requireFile(source, '模板 ets');
    await validateTargetPath(target, project);
    if ((await inspectPath(target)).kind === 'file') {
      conflicts.push({ source, target });
    }
    plan.templatePairs.push({ source, target });
  }
  if (conflicts.length > 0) {
    throw new CopyBlocked('检测到固定 ets 目标路径冲突', { conflicts });
  }

  for (const pair of plan.templatePairs) {
    plan.directCopies.push({
      ...pair,
      category: 'ets',
      overwrites: false,
    });
  }

  await planRequiredResourceTree(
    sourceAppScopeResources,
    targetAppScopeResources,
    project,
    plan,
    'AppScope/resources',
  );
  await planRequiredResourceTree(
    sourceEntryResources,
    targetEntryResources,
    project,
    plan,
    'entry/src/main/resources',
  );
  if (plan.resourcePlanningFailures.length > 0) {
    throw new CopyBlocked(
      `检测到 ${plan.resourcePlanningFailures.length} 个无法处理的资源文件`,
      { failed_files: plan.resourcePlanningFailures },
    );
  }
  await planMainPages(project, plan);
  return plan;
}

async function runWithConcurrency(items, workerCount, operation) {
  let nextIndex = 0;
  const results = new Array(items.length);
  const failures = [];

  async function worker() {
    while (true) {
      const currentIndex = nextIndex;
      nextIndex += 1;
      if (currentIndex >= items.length) {
        return;
      }
      try {
        results[currentIndex] = await operation(items[currentIndex]);
      } catch (error) {
        failures.push({
          index: currentIndex,
          item: items[currentIndex],
          error,
        });
      }
    }
  }

  const count = Math.max(1, Math.min(workerCount, items.length || 1));
  await Promise.all(Array.from({ length: count }, () => worker()));
  return { results, failures };
}

async function writeJsonAtomic(item) {
  await mkdir(path.dirname(item.target), { recursive: true });
  const temporary = path.join(
    path.dirname(item.target),
    `.${path.basename(item.target)}.${process.pid}.${Math.random().toString(16).slice(2)}.tmp`,
  );
  try {
    await writeFile(temporary, item.content, 'utf8');
    await rm(item.target, { force: true });
    await rename(temporary, item.target);
  } finally {
    await rm(temporary, { force: true });
  }
}

async function backupTargets(targets) {
  const backupRoot = await mkdtemp(path.join(os.tmpdir(), 'hmos-login-copy-'));
  const entries = [];
  for (let index = 0; index < targets.length; index += 1) {
    const target = targets[index];
    const targetInfo = await inspectPath(target);
    if (targetInfo.kind === 'file') {
      const backup = path.join(backupRoot, String(index));
      const metadata = await stat(target);
      await copyFile(target, backup);
      entries.push({
        target,
        existed: true,
        backup,
        mode: metadata.mode,
        atime: metadata.atime,
        mtime: metadata.mtime,
      });
    } else {
      entries.push({ target, existed: false });
    }
  }
  return { backupRoot, entries };
}

async function restoreTargets(backup) {
  const errors = [];
  for (const entry of [...backup.entries].reverse()) {
    try {
      if (entry.existed) {
        await mkdir(path.dirname(entry.target), { recursive: true });
        await copyFile(entry.backup, entry.target);
        await chmod(entry.target, entry.mode);
        await utimes(entry.target, entry.atime, entry.mtime);
      } else {
        await rm(entry.target, { force: true });
      }
    } catch (error) {
      errors.push(`${entry.target}: ${error.message}`);
    }
  }
  return errors;
}

async function fileHash(file) {
  return createHash('sha256').update(await readFile(file)).digest('hex');
}

function taskOperation(task) {
  if (task.type === 'copy') {
    return 'copy';
  }
  return task.item.category === 'main_pages' ? 'register_pages' : 'merge_json';
}

function failedFile(task, error) {
  return {
    source: task.item.source,
    target: task.item.target,
    operation: taskOperation(task),
    reason: error.message,
  };
}

async function verifyTask(task) {
  await requireFile(task.item.target, '复制结果');

  if (task.type === 'copy') {
    const sourceHash = await fileHash(task.item.source);
    const targetHash = await fileHash(task.item.target);
    if (sourceHash !== targetHash) {
      throw new Error('源文件与目标文件内容不一致');
    }
    return {
      source: task.item.source,
      target: task.item.target,
      operation: taskOperation(task),
      sha256: targetHash,
    };
  }

  const actual = await readFile(task.item.target, 'utf8');
  if (actual !== task.item.content) {
    throw new Error('目标 JSON 与计划合并结果不一致');
  }

  return {
    source: task.item.source,
    target: task.item.target,
    operation: taskOperation(task),
    sha256: createHash('sha256').update(actual).digest('hex'),
  };
}

export async function executePlan(plan, workers = 8) {
  const tasks = [
    ...plan.directCopies.map((item) => ({ type: 'copy', item })),
    ...plan.jsonWrites.map((item) => ({ type: 'json', item })),
  ];
  const uniqueTargets = [...new Set(tasks.map((task) => task.item.target))];
  const backup = await backupTargets(uniqueTargets);

  try {
    const writeResult = await runWithConcurrency(tasks, workers, async (task) => {
      if (task.type === 'copy') {
        await mkdir(path.dirname(task.item.target), { recursive: true });
        await copyFile(task.item.source, task.item.target);
      } else {
        await writeJsonAtomic(task.item);
      }
    });
    if (writeResult.failures.length > 0) {
      throw new BatchOperationError(
        '部分文件写入失败',
        writeResult.failures.map((failure) => failedFile(failure.item, failure.error)),
      );
    }

    const verificationResult = await runWithConcurrency(
      tasks,
      workers,
      verifyTask,
    );
    if (verificationResult.failures.length > 0) {
      throw new BatchOperationError(
        '部分文件复制后校验失败',
        verificationResult.failures.map(
          (failure) => failedFile(failure.item, failure.error),
        ),
      );
    }

    const verifiedFiles = verificationResult.results;
    const templateHashes = {};
    for (const verified of verifiedFiles) {
      if (verified.operation === 'copy'
        && plan.templatePairs.some((pair) => pair.target === verified.target)) {
        templateHashes[path.basename(verified.target)] = verified.sha256;
      }
    }

    await rm(backup.backupRoot, { recursive: true, force: true });
    return {
      templateHashes,
      verifiedFiles,
    };
  } catch (error) {
    const rollbackErrors = await restoreTargets(backup);
    await rm(backup.backupRoot, { recursive: true, force: true });
    throw new ExecutionFailed(error, rollbackErrors.length === 0, rollbackErrors);
  }
}

function makeSummary(plan, status, verification = {}) {
  const resourceCopies = plan.directCopies.filter(
    (item) => item.category === 'resource',
  );
  const plannedMappings = [
    ...plan.directCopies.map((item) => ({
      source: item.source,
      target: item.target,
      operation: 'copy',
    })),
    ...plan.jsonWrites.map((item) => ({
      source: item.source,
      target: item.target,
      operation: item.category === 'main_pages' ? 'register_pages' : 'merge_json',
    })),
  ];
  return {
    status,
    asset_root: plan.assetRoot,
    ets_copied: status === 'copied' ? HUAWEI_ID_LOGIN_PAGE_FILES.length : 0,
    template_hashes: verification.templateHashes ?? {},
    resource_files_copied: status === 'copied' ? resourceCopies.length : 0,
    resource_files_overwritten: status === 'copied'
      ? resourceCopies.filter((item) => item.overwrites).length
      : 0,
    json_files_merged: status === 'copied' ? plan.jsonMergedCount : 0,
    main_pages_added: plan.mainPagesAdded,
    resource_files_skipped: plan.resourceFilesSkipped,
    planned_file_writes: plan.directCopies.length + plan.jsonWrites.length,
    planned_mappings: plannedMappings,
    verification: {
      planned_files: plan.directCopies.length + plan.jsonWrites.length,
      verified_files: status === 'copied' ? verification.verifiedFiles.length : 0,
      failed_files: [],
    },
  };
}

export async function main(argv = process.argv.slice(2)) {
  try {
    const options = parseArgs(argv);
    if (options.help) {
      printHelp();
      return 0;
    }

    const plan = await buildPlan(options.project, options.assetRoot);
    if (options.dryRun) {
      process.stdout.write(`${JSON.stringify(makeSummary(plan, 'ready'), null, 2)}\n`);
      return 0;
    }

    const verification = await executePlan(plan, options.workers);
    process.stdout.write(
      `${JSON.stringify(makeSummary(plan, 'copied', verification), null, 2)}\n`,
    );
    return 0;
  } catch (error) {
    if (error instanceof CopyBlocked) {
      process.stderr.write(
        `${JSON.stringify({
          status: 'blocked',
          reason: error.message,
          ...error.details,
        }, null, 2)}\n`,
      );
      return 2;
    }

    process.stderr.write(
      `${JSON.stringify({
        status: 'failed',
        reason: `${error.name}: ${error.message}`,
        rolled_back: error instanceof ExecutionFailed ? error.rolledBack : true,
        failed_files: error instanceof ExecutionFailed ? error.failedFiles : [],
        rollback_errors: error instanceof ExecutionFailed
          ? error.rollbackErrors
          : [],
      }, null, 2)}\n`,
    );
    return 1;
  }
}

const invokedAsScript = process.argv[1]
  && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url;
if (invokedAsScript) {
  process.exitCode = await main();
}
