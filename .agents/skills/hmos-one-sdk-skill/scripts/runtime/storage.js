import { existsSync, readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const MODULE_ROOT = fileURLToPath(new URL('../', import.meta.url));
export const ROOT = import.meta.filename.endsWith('.ts') ? MODULE_ROOT : resolve(MODULE_ROOT, '..');
export const INDEX_DIR = resolve(process.env.HMOS_INDEX_DIR || resolve(ROOT, 'scripts/index'));
export const BUNDLED_CORPUS = resolve(ROOT, 'data/corpus.json.gz');
export const DEFAULT_CORPUS = resolve(process.env.HMOS_CORPUS_PATH || BUNDLED_CORPUS);
export function defaultCorpus() {
    if (process.env.HMOS_CORPUS_PATH)
        return DEFAULT_CORPUS;
    return existsSync(BUNDLED_CORPUS) ? BUNDLED_CORPUS : ROOT;
}
export const JIEBA_ASSET_DIR = resolve(ROOT, 'scripts/data/jieba-0.42.1');
export const INDEX_FILES = ['docs.json.gz', 'inverted.json.gz', 'meta.json', 'query_lexicon.json.gz'];
export const SNAPSHOT_FILE = 'corpus.json.gz';
export function loadGzipJson(file) {
    return JSON.parse(gunzipSync(readFileSync(file)).toString('utf8'));
}
