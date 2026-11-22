import { existsSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { ROOT, INDEX_DIR, INDEX_FILES, defaultCorpus, loadGzipJson } from './storage.js';
export { ROOT, INDEX_DIR, INDEX_FILES, loadGzipJson } from './storage.js';
export function readIndex(directory = INDEX_DIR, autoBuild = true) {
    const lock = resolve(directory) + '.build.lock';
    if (existsSync(lock))
        throw new Error('索引正在构建，请稍后重试: ' + lock);
    if (!INDEX_FILES.every(name => existsSync(resolve(directory, name))) && autoBuild) {
        let source = defaultCorpus();
        const metaFile = resolve(directory, 'meta.json');
        if (existsSync(metaFile) && !process.env.HMOS_CORPUS_PATH) {
            const indexedSource = JSON.parse(readFileSync(metaFile, 'utf8')).source?.path;
            if (typeof indexedSource === 'string' && indexedSource) {
                const candidate = resolve(ROOT, indexedSource);
                if (existsSync(candidate))
                    source = candidate;
            }
        }
        const builder = resolve(import.meta.dirname, import.meta.filename.endsWith('.ts') ? 'build_index.ts' : 'build_index.js');
        const run = spawnSync(process.execPath, [builder,
            '--source', source, '--output', resolve(directory), '--force'], { encoding: 'utf8', timeout: 300_000 });
        if (run.error || run.status !== 0)
            throw new Error('自动建库失败: ' + (run.stderr || run.error?.message));
    }
    const metaFile = resolve(directory, 'meta.json');
    const before = readFileSync(metaFile, 'utf8');
    let index;
    try {
        index = {
            documents: loadGzipJson(resolve(directory, 'docs.json.gz')),
            inverted: loadGzipJson(resolve(directory, 'inverted.json.gz')),
            meta: JSON.parse(before),
            lexicon: loadGzipJson(resolve(directory, 'query_lexicon.json.gz')),
        };
    }
    catch (error) {
        throw new Error('无法加载检索索引；请运行 node scripts/build_index.js --force 重建。', { cause: error });
    }
    if (existsSync(lock) || readFileSync(metaFile, 'utf8') !== before)
        throw new Error('读取过程中索引已更新，请重试');
    if (index.meta.tokenizer !== 'jieba_api' || index.documents.length !== index.meta.total_docs
        || !Number.isFinite(index.meta.avg_doc_length) || index.meta.avg_doc_length <= 0) {
        throw new Error('Jieba 索引元数据不一致');
    }
    if (index.documents.some((doc, id) => doc.id !== id || !Number.isFinite(doc.length) || doc.length <= 0)) {
        throw new Error('文档编号或长度无效');
    }
    return index;
}
