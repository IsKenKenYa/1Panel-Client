import { resolve } from 'node:path';
import { existsSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import { randomUUID } from 'node:crypto';
import { readCorpus } from './corpus_source.js';
import { defaultCorpus, INDEX_DIR, ROOT, SNAPSHOT_FILE, loadGzipJson } from './storage.js';
let sourceInfo;
let corpus;
export function clearSnippetCache() { sourceInfo = undefined; corpus = undefined; }
function snippetSource() {
    if (sourceInfo)
        return sourceInfo;
    let indexedPath, sha256;
    try {
        const meta = JSON.parse(readFileSync(resolve(INDEX_DIR, 'meta.json'), 'utf8'));
        if (typeof meta.source?.path === 'string' && meta.source.path)
            indexedPath = meta.source.path;
        if (typeof meta.source?.sha256 === 'string' && meta.source.sha256)
            sha256 = meta.source.sha256;
    }
    catch { }
    const indexedSource = indexedPath ? resolve(ROOT, indexedPath) : undefined;
    const path = indexedSource && existsSync(indexedSource) && !process.env.HMOS_CORPUS_PATH
        ? indexedSource : defaultCorpus();
    return sourceInfo = { path, sha256 };
}
function safeKey(path) {
    const key = path.replaceAll('\\', '/').replace(/^(\.\/)+/, '');
    if (!key || key.startsWith('/') || /^[a-z]:/i.test(key)
        || key.split('/').some(part => !part || part === '.' || part === '..'))
        return undefined;
    return key;
}
function ensureSnapshot() {
    const snapshot = resolve(INDEX_DIR, SNAPSHOT_FILE);
    if (existsSync(snapshot))
        return snapshot;
    const selected = snippetSource(), source = readCorpus(selected.path);
    if (selected.sha256 && source.sha256 !== selected.sha256) {
        throw new Error('正文来源已变化，拒绝为旧索引生成不一致的摘要快照；请先重建索引');
    }
    const bytes = gzipSync(Buffer.from(JSON.stringify({
        documents: Object.fromEntries(source.documents.map(doc => [doc.path, doc.content])),
    })), { level: 9 });
    const temporary = snapshot + '.tmp-' + process.pid + '-' + randomUUID();
    writeFileSync(temporary, bytes, { flag: 'wx' });
    try {
        if (existsSync(snapshot))
            unlinkSync(temporary);
        else
            renameSync(temporary, snapshot);
    }
    catch (error) {
        if (existsSync(temporary))
            unlinkSync(temporary);
        if (!existsSync(snapshot))
            throw error;
    }
    return snapshot;
}
function markdownFor(path) {
    const key = safeKey(path);
    if (!key)
        return undefined;
    if (!corpus) {
        const payload = loadGzipJson(ensureSnapshot());
        if (!payload || typeof payload !== 'object' || !('documents' in payload)
            || !payload.documents || typeof payload.documents !== 'object' || Array.isArray(payload.documents)) {
            throw new Error('摘要快照格式无效');
        }
        corpus = payload.documents;
    }
    return Object.hasOwn(corpus, key) && typeof corpus[key] === 'string' ? corpus[key] : undefined;
}
export function parseFrontmatter(content) {
    const match = /^---\s*\n(.*?\n)---\s*\n/s.exec(content);
    if (!match)
        return [{}, content];
    const meta = Object.create(null);
    for (const line of match[1].split('\n')) {
        const split = line.indexOf(':');
        if (split < 0)
            continue;
        const key = line.slice(0, split).trim(), value = line.slice(split + 1).trim().replace(/^["']+|["']+$/g, '');
        if (key && value)
            meta[key] = value;
    }
    return [meta, content.slice(match[0].length)];
}
export function makeSnippet(relPath, queryTerms, maxLen = 240) {
    if (!Number.isInteger(maxLen) || maxLen < 1)
        throw new Error('maxLen 必须是正整数');
    const content = markdownFor(relPath);
    if (content === undefined)
        return '';
    const [, markdown] = parseFrontmatter(content);
    const body = markdown.replace(/!\[[^\]]*\]\([^)]*\)/g, '').replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
        .replace(/[\x60*_>#|]+/g, ' ').replace(/\s+/g, ' ').trim();
    const lower = body.toLowerCase();
    const positions = queryTerms.filter(Boolean).map(term => lower.indexOf(term.toLowerCase())).filter(p => p >= 0);
    if (!positions.length)
        return body.slice(0, maxLen) + (body.length > maxLen ? '...' : '');
    const center = Math.min(...positions), half = Math.floor(maxLen / 2);
    const start = Math.max(0, center - half), end = Math.min(body.length, center + half);
    return (start > 0 ? '...' : '') + body.slice(start, end) + (end < body.length ? '...' : '');
}
