/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

export async function runDevecoCli(args) {
  const invocation = await resolveDevecoCli();
  return new Promise((resolve, reject) => {
    const child = spawn(invocation.command, [...invocation.args, ...args], {
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stdout.on('data', (chunk) => {
      stdout += chunk;
    });
    child.stderr.on('data', (chunk) => {
      stderr += chunk;
    });
    child.on('error', reject);
    child.on('close', (exitCode) => resolve({ stdout, stderr, exitCode: exitCode ?? 1 }));
  });
}

async function resolveDevecoCli() {
  if (process.platform !== 'win32') {
    return { command: 'devecocli', args: [] };
  }

  const directories = String(process.env.PATH || process.env.Path || '')
    .split(path.delimiter)
    .map((directory) => directory.trim().replace(/^"|"$/g, ''))
    .filter((directory) => directory.length > 0);

  for (const directory of directories) {
    const executable = path.join(directory, 'devecocli.exe');
    if (await exists(executable)) {
      return { command: executable, args: [] };
    }

    const shim = path.join(directory, 'devecocli.cmd');
    const pointer = path.join(directory, '.deveco-cli-path');
    if (!(await exists(shim)) || !(await exists(pointer))) {
      continue;
    }

    const entry = (await fs.readFile(pointer, 'utf8')).trim();
    if (entry && (await exists(entry))) {
      return { command: process.execPath, args: [entry] };
    }
  }

  throw new Error('devecocli executable was not found in PATH');
}

function exists(file) {
  return fs.access(file).then(
    () => true,
    () => false,
  );
}
