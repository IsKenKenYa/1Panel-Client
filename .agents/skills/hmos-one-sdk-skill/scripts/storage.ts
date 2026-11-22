import { existsSync, readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const MODULE_ROOT = fileURLToPath(new URL('../', import.meta.url));
// Source modules live in ROOT/scripts. Compiled modules may live in
// ROOT/dist/scripts or in the standalone ROOT/scripts/runtime package.
export const ROOT = import.meta.filename.endsWith('.ts') ? MODULE_ROOT : resolve(MODULE_ROOT, '..');
export const INDEX_DIR = resolve(process.env.HMOS_INDEX_DIR || resolve(ROOT, 'scripts/index'));
export const BUNDLED_CORPUS = resolve(ROOT, 'data/corpus.json.gz');
export const DEFAULT_CORPUS = resolve(process.env.HMOS_CORPUS_PATH || BUNDLED_CORPUS);
export function defaultCorpus(): string {
  if (process.env.HMOS_CORPUS_PATH) return DEFAULT_CORPUS;
  return existsSync(BUNDLED_CORPUS) ? BUNDLED_CORPUS : ROOT;
}
// Build-only Jieba assets intentionally live under scripts/ so that scripts/ is a
// complete drop-in unit. Retrieval never imports or loads them.
export const JIEBA_ASSET_DIR = resolve(ROOT, 'scripts/data/jieba-0.42.1');
export const INDEX_FILES = ['docs.json.gz', 'inverted.json.gz', 'meta.json', 'query_lexicon.json.gz'] as const;
export const SNAPSHOT_FILE = 'corpus.json.gz';
export function loadGzipJson<T>(file: string): T {
  return JSON.parse(gunzipSync(readFileSync(file)).toString('utf8')) as T;
}
