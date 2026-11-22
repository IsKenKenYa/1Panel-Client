import { mkdirSync, writeFileSync, renameSync } from 'node:fs';
import { dirname } from 'node:path';

export function atomicWrite(file, content) {
  mkdirSync(dirname(file), { recursive: true });
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}
