import { lstatSync, readFileSync, readdirSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { loadGzipJson } from './storage.js';
export function decodeEscapedPath(path) {
    return path.replace(/#U([0-9a-fA-F]{4})/g, (_match, hex) => String.fromCharCode(Number.parseInt(hex, 16)));
}
export function comparePaths(a, b) {
    const left = Array.from(a), right = Array.from(b);
    for (let i = 0; i < Math.min(left.length, right.length); i++) {
        const delta = left[i].codePointAt(0) - right[i].codePointAt(0);
        if (delta)
            return delta;
    }
    return left.length - right.length;
}
function safePath(path) {
    const clean = path.replaceAll('\\', '/').replace(/^(\.\/)+/, '');
    if (!clean || clean.startsWith('/') || /^[a-z]:/i.test(clean) || clean.split('/').some(part => !part || part === '..' || part === '.')) {
        throw new Error('语料包含不安全的相对路径: ' + path);
    }
    return clean;
}
export function compareDocumentPaths(a, b) {
    const left = a.toLowerCase().split('/'), right = b.toLowerCase().split('/');
    for (let i = 0; i < Math.min(left.length, right.length); i++) {
        const delta = comparePaths(left[i], right[i]);
        if (delta)
            return delta;
    }
    return left.length - right.length || comparePaths(a, b);
}
export function readCorpus(source) {
    const path = resolve(source), stat = lstatSync(path), documents = [];
    const add = (relPath, content) => {
        const clean = safePath(decodeEscapedPath(relPath));
        if (basename(clean) !== 'SUB_SKILL.md')
            return;
        if (typeof content !== 'string')
            throw new Error('语料正文必须为字符串: ' + clean);
        documents.push({ path: clean, content, fallbackTitle: 'SUB_SKILL' });
    };
    if (stat.isDirectory()) {
        const walk = (directory, prefix) => {
            for (const entry of readdirSync(directory, { withFileTypes: true })) {
                const relPath = prefix + entry.name, full = resolve(directory, entry.name);
                if (entry.isSymbolicLink())
                    throw new Error('语料目录不支持符号链接: ' + relPath);
                if (entry.isDirectory())
                    walk(full, relPath + '/');
                else if (entry.isFile() && entry.name === 'SUB_SKILL.md') {
                    const bytes = readFileSync(full);
                    add(relPath, new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes));
                }
            }
        };
        walk(path, '');
    }
    else if (stat.isFile() && /\.json(?:\.gz)?$/i.test(path)) {
        const payload = path.endsWith('.gz') ? loadGzipJson(path) : JSON.parse(readFileSync(path, 'utf8'));
        if (!payload || typeof payload !== 'object' || !('documents' in payload) ||
            !payload.documents || typeof payload.documents !== 'object' || Array.isArray(payload.documents)) {
            throw new Error('JSON 语料需要 documents: { 相对路径: Markdown正文 }');
        }
        for (const [key, value] of Object.entries(payload.documents))
            add(key, value);
    }
    else
        throw new Error('语料必须是目录或 .json/.json.gz 快照');
    documents.sort((a, b) => compareDocumentPaths(a.path, b.path));
    const seen = new Set(), hash = createHash('sha256');
    for (const doc of documents) {
        if (seen.has(doc.path))
            throw new Error('重复的文档路径: ' + doc.path);
        seen.add(doc.path);
        hash.update(JSON.stringify([doc.path, doc.content]) + '\n');
    }
    if (!documents.length)
        throw new Error('语料中没有 SUB_SKILL.md；原索引未改动');
    return { path, kind: stat.isDirectory() ? 'directory' : 'json', documents, sha256: hash.digest('hex') };
}
