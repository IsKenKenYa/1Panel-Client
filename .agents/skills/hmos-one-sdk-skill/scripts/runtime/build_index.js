#!/usr/bin/env node
import { existsSync, lstatSync, mkdirSync, mkdtempSync, openSync, closeSync, readFileSync, readdirSync, renameSync, rmdirSync, unlinkSync, writeFileSync, statSync } from 'node:fs';
import { dirname, relative, resolve, sep } from 'node:path';
import { gzipSync } from 'node:zlib';
import { randomUUID } from 'node:crypto';
import { performance } from 'node:perf_hooks';
import { DocumentTokenizer } from './document_tokenizer.js';
import { readCorpus } from './corpus_source.js';
import { parseFrontmatter } from './corpus.js';
import { CJK_WORD, STOPWORDS } from './tokenizer.js';
import { defaultCorpus, INDEX_DIR, INDEX_FILES, SNAPSHOT_FILE } from './storage.js';
import { isMain } from './program.js';
export const BUILDER_VERSION = 'jieba-ts-dag-hmm-v1';
export const FIELD_WEIGHTS = { title: 5, description: 3, breadcrumb: 2, path: 1, body: 1 };
export function documentFields(path, content, fallbackTitle = 'SUB_SKILL') {
    const [meta, body] = parseFrontmatter(content);
    const title = meta.title || meta.name || fallbackTitle;
    const description = meta.description || '', breadcrumb = meta.breadcrumb || description;
    const pathText = path.replace(/\.[^/.]+$/, '').split(/[\\/]+/).filter(part => part && part !== '.').join(' ');
    return { title, description, breadcrumb, path: pathText, body };
}
export function buildMemory(source, tokenizer = new DocumentTokenizer()) {
    const documents = [], inverted = Object.create(null);
    let totalLength = 0, skipped = 0, maxTf = 0, postingEntries = 0;
    for (const entry of source.documents) {
        const [header] = parseFrontmatter(entry.content), fields = documentFields(entry.path, entry.content, entry.fallbackTitle);
        const tf = new Map();
        for (const field of Object.keys(FIELD_WEIGHTS)) {
            for (const term of tokenizer.tokenize(fields[field]))
                tf.set(term, (tf.get(term) || 0) + FIELD_WEIGHTS[field]);
        }
        const length = [...tf.values()].reduce((a, b) => a + b, 0);
        if (!length) {
            skipped++;
            continue;
        }
        const id = documents.length;
        documents.push({ id, path: entry.path, title: fields.title, breadcrumb: fields.breadcrumb,
            category: header.category || entry.path.split('/')[0], url: header.url || '', length });
        totalLength += length;
        for (const [term, count] of tf) {
            (inverted[term] ??= []).push(id, count);
            maxTf = Math.max(maxTf, count);
            postingEntries++;
        }
    }
    if (!documents.length)
        throw new Error('语料没有可索引 token；原索引未改动');
    const terms = Object.create(null), segmentationOnly = [];
    for (const [term, postings] of Object.entries(inverted)) {
        if (!CJK_WORD.test(term))
            continue;
        let sum = 0;
        for (let i = 1; i < postings.length; i += 2)
            sum += postings[i];
        terms[term] = Math.max(1, tokenizer.frequencies.get(term) || Math.max(1000, Math.trunc(sum)));
    }
    for (const term of STOPWORDS) {
        if (!CJK_WORD.test(term) || Object.hasOwn(terms, term))
            continue;
        terms[term] = Math.max(1, tokenizer.frequencies.get(term) || 1);
        segmentationOnly.push(term);
    }
    const meta = {
        built_at: new Date().toISOString(), total_docs: documents.length,
        avg_doc_length: Math.round(totalLength / documents.length * 100) / 100,
        vocabulary_size: Object.keys(inverted).length, posting_entries: postingEntries,
        postings_format: 'flat_number_array_interleaved', max_tf: maxTf, k1: 1.5, b: .75,
        title_weight: 5, description_weight: 3, breadcrumb_weight: 2, body_weight: 1, path_weight: 1,
        skipped, compression: 'gzip', tokenizer: 'jieba_api', builder_version: BUILDER_VERSION,
        document_order: 'windows-path-components-lowercase',
        generation: randomUUID(), source: { path: source.path, kind: source.kind, sha256: source.sha256,
            input_documents: source.documents.length },
    };
    const lexicon = { terms, total_frequency: tokenizer.totalFrequency, jieba_version: '0.42.1',
        oov_frequency_floor: 1000, segmentation_only_terms: segmentationOnly.sort(),
        source: 'TypeScript Jieba 0.42.1 DAG/HMM index; native dictionary frequencies + indexed OOV floor' };
    return { documents, inverted, meta, lexicon };
}
const ALLOWED = new Set([...INDEX_FILES, SNAPSHOT_FILE]);
function validateOutput(output) {
    if (!existsSync(output))
        return;
    if (!lstatSync(output).isDirectory() || lstatSync(output).isSymbolicLink())
        throw new Error('索引输出必须是普通目录');
    for (const entry of readdirSync(output, { withFileTypes: true })) {
        if (!ALLOWED.has(entry.name) || !entry.isFile())
            throw new Error('拒绝覆盖包含非索引文件的目录: ' + entry.name);
    }
}
function removeOwnedDirectory(directory) {
    validateOutput(directory);
    for (const name of readdirSync(directory))
        unlinkSync(resolve(directory, name));
    rmdirSync(directory);
}
export function buildIndex(options = {}) {
    const started = performance.now(), output = resolve(options.output || INDEX_DIR);
    const sourcePath = resolve(options.source || defaultCorpus());
    const relation = relative(output, sourcePath);
    if (!relation || (relation !== '..' && !relation.startsWith('..' + sep) && !relation.startsWith(sep))) {
        throw new Error('索引输出不能等于或包含语料来源');
    }
    validateOutput(output);
    if (existsSync(output) && readdirSync(output).length && !options.force) {
        throw new Error('输出目录已有索引；指定 --force 重建，或用 --output 选择新目录');
    }
    mkdirSync(dirname(output), { recursive: true });
    const lock = output + '.build.lock';
    let descriptor;
    try {
        descriptor = openSync(lock, 'wx');
    }
    catch (error) {
        throw new Error('建库锁已存在或无法创建: ' + lock + '；请等待其他构建结束，异常退出后需人工确认并清理锁', { cause: error });
    }
    let stage, backup;
    try {
        writeFileSync(descriptor, JSON.stringify({ pid: process.pid, started_at: new Date().toISOString() }));
        const source = readCorpus(sourcePath), index = buildMemory(source);
        stage = mkdtempSync(resolve(dirname(output), '.' + output.split(sep).at(-1) + '.stage-'));
        const zip = (name, value) => writeFileSync(resolve(stage, name), gzipSync(Buffer.from(JSON.stringify(value)), { level: 9 }));
        zip('docs.json.gz', index.documents);
        zip('inverted.json.gz', index.inverted);
        zip('query_lexicon.json.gz', index.lexicon);
        if (options.snapshot) {
            zip(SNAPSHOT_FILE, { documents: Object.fromEntries(source.documents.map(doc => [doc.path, doc.content])) });
        }
        writeFileSync(resolve(stage, 'meta.json'), JSON.stringify(index.meta, null, 2) + '\n');
        validateOutput(output);
        if (existsSync(output)) {
            backup = output + '.previous-' + randomUUID();
            renameSync(output, backup);
        }
        try {
            renameSync(stage, output);
            stage = undefined;
        }
        catch (error) {
            if (backup) {
                renameSync(backup, output);
                backup = undefined;
            }
            throw error;
        }
        if (backup) {
            removeOwnedDirectory(backup);
            backup = undefined;
        }
        return { output, meta: index.meta, elapsed_ms: performance.now() - started,
            peak_rss_mib: process.resourceUsage().maxRSS / 1024,
            core_index_bytes: INDEX_FILES.reduce((sum, name) => sum + statSync(resolve(output, name)).size, 0),
            corpus_snapshot_bytes: existsSync(resolve(output, SNAPSHOT_FILE)) ? statSync(resolve(output, SNAPSHOT_FILE)).size : 0 };
    }
    finally {
        if (stage && existsSync(stage))
            removeOwnedDirectory(stage);
        closeSync(descriptor);
        unlinkSync(lock);
    }
}
export function checkIndex(sourcePath = defaultCorpus(), output = INDEX_DIR) {
    const source = readCorpus(sourcePath);
    if (!INDEX_FILES.every(name => existsSync(resolve(output, name))))
        return false;
    const meta = JSON.parse(readFileSync(resolve(output, 'meta.json'), 'utf8'));
    return meta.builder_version === BUILDER_VERSION && meta.source?.sha256 === source.sha256;
}
export function main(args = process.argv.slice(2)) {
    const options = {};
    let check = false;
    try {
        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if (arg === '--help') {
                console.log('用法: node scripts/build_index.js [--source 语料目录或JSON.gz] [--output 索引目录] [--force] [--check] [--snapshot]');
                return 0;
            }
            if (arg === '--source' || arg === '--output') {
                const value = args[++i];
                if (!value || value.startsWith('--'))
                    throw new Error(arg + ' 缺少参数');
                options[arg === '--source' ? 'source' : 'output'] = value;
            }
            else if (arg === '--force' || arg === '-f')
                options.force = true;
            else if (arg === '--check')
                check = true;
            else if (arg === '--snapshot' || arg === '--with-snapshot')
                options.snapshot = true;
            else
                throw new Error('未知参数: ' + arg);
        }
        if (check) {
            const current = checkIndex(options.source, options.output);
            console.log(JSON.stringify({ current, source: options.source || defaultCorpus(), output: options.output || INDEX_DIR }));
            return current ? 0 : 2;
        }
        const output = resolve(options.output || INDEX_DIR);
        const current = existsSync(output) && INDEX_FILES.every(name => existsSync(resolve(output, name)))
            && checkIndex(options.source, output);
        const snapshotReady = existsSync(resolve(output, SNAPSHOT_FILE));
        if (!options.force && current && (!options.snapshot || snapshotReady)) {
            const meta = JSON.parse(readFileSync(resolve(output, 'meta.json'), 'utf8'));
            console.log(`[skip] 索引已是最新（built_at=${String(meta.built_at || 'unknown')}）。使用 --force 强制重建。`);
            return 0;
        }
        console.log(JSON.stringify(buildIndex(options), null, 2));
        return 0;
    }
    catch (error) {
        console.error(error instanceof Error ? error.message : String(error));
        return 1;
    }
}
if (isMain(import.meta.url))
    process.exitCode = main();
