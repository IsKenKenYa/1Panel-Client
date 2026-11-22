#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { copyFile, mkdir, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const FILES = [
  {
    source: 'HuaweiIDCustomLoginButton.ets',
    target: path.join(
      'entry', 'src', 'main', 'ets', 'HuaweiIDCustomLogin', 'HuaweiIDCustomLoginButton.ets'
    )
  },
  {
    source: 'huaweilogo_red_black.svg',
    target: path.join(
      'entry', 'src', 'main', 'resources', 'base', 'media', 'huaweilogo_red_black.svg'
    )
  },
  {
    source: 'huaweilogo_white.svg',
    target: path.join('entry', 'src', 'main', 'resources', 'base', 'media', 'huaweilogo_white.svg')
  }
];

function parseArgs(argv) {
  const options = { project: '', dryRun: false };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--project') {
      index += 1;
      options.project = argv[index] ?? '';
    } else if (argument === '--dry-run') {
      options.dryRun = true;
    } else if (argument === '--help' || argument === '-h') {
      process.stdout.write(
        'Usage: node copy-huawei-id-custom-login.mjs --project <PROJECT_ROOT> [--dry-run]\n'
      );
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${argument}`);
    }
  }
  if (!options.project) {
    throw new Error('Missing --project');
  }
  options.project = path.resolve(options.project);
  return options;
}

async function inspect(target) {
  try {
    const information = await stat(target);
    return information.isFile() ? 'file' : information.isDirectory() ? 'directory' : 'other';
  } catch (error) {
    if (error.code === 'ENOENT') {
      return 'missing';
    }
    throw error;
  }
}

async function sha256(file) {
  return createHash('sha256').update(await readFile(file)).digest('hex');
}

function output(value) {
  process.stdout.write(`${JSON.stringify(value)}\n`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
  const assetRoot = path.resolve(scriptDirectory, '..', 'assets');
  const etsRoot = path.join(options.project, 'entry', 'src', 'main', 'ets');

  if (await inspect(options.project) !== 'directory') {
    throw new Error(`Project directory does not exist: ${options.project}`);
  }
  if (await inspect(etsRoot) !== 'directory') {
    throw new Error(`ArkTS source directory does not exist: ${etsRoot}`);
  }

  const plan = [];
  const conflicts = [];
  for (const item of FILES) {
    const source = path.join(assetRoot, item.source);
    const target = path.join(options.project, item.target);
    if (await inspect(source) !== 'file') {
      throw new Error(`Fixed asset is missing: ${source}`);
    }
    if (await inspect(target) !== 'missing') {
      conflicts.push(target);
    }
    plan.push({ source, target, sourceHash: await sha256(source) });
  }

  if (conflicts.length > 0) {
    output({
      status: 'blocked',
      reason: 'target_exists',
      plannedFiles: FILES.length,
      verifiedFiles: 0,
      failedFiles: conflicts
    });
    process.exitCode = 2;
    return;
  }

  if (options.dryRun) {
    output({
      status: 'ready',
      files: plan,
      plannedFiles: FILES.length,
      verifiedFiles: 0,
      failedFiles: []
    });
    return;
  }

  for (const item of plan) {
    await mkdir(path.dirname(item.target), { recursive: true });
    await copyFile(item.source, item.target);
  }

  const failedFiles = [];
  for (const item of plan) {
    if (item.sourceHash !== await sha256(item.target)) {
      failedFiles.push(item.target);
    }
  }
  const verifiedFiles = FILES.length - failedFiles.length;
  output({
    status: failedFiles.length === 0 ? 'copied' : 'failed',
    files: plan,
    plannedFiles: FILES.length,
    verifiedFiles,
    failedFiles
  });
  if (failedFiles.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  output({
    status: 'failed',
    reason: error.message,
    plannedFiles: FILES.length,
    verifiedFiles: 0,
    failedFiles: []
  });
  process.exitCode = 1;
});
