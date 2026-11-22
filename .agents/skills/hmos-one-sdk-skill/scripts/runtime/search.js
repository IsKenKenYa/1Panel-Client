#!/usr/bin/env node
import { getRuntime } from './retrieval.js';
import { validateMode } from './rejection.js';
import { makeSnippet } from './corpus.js';
import { isMain } from './program.js';
export { makeSnippet } from './corpus.js';
export function loadIndex() {
    const { documents, inverted, meta } = getRuntime().index;
    return [documents, inverted, meta];
}
export function search(query, top = 10, category, withSnippet = false, mode = 'default') {
    if (typeof withSnippet !== 'boolean')
        throw new Error('withSnippet 必须是布尔值');
    const runtime = getRuntime();
    const result = runtime.explain(query, { top, category, mode });
    return [result.accepted.map(hit => [hit.doc_id, hit.score]), runtime.index.documents,
        result.query_terms, result.elapsed_sec, result.total_searched];
}
export function formatJson(query, hits, documents, queryTerms, elapsed, totalSearched, withSnippet) {
    const results = hits.map(([id, score], rank) => {
        const doc = documents[id];
        const item = { rank: rank + 1, score: Math.round(score * 10000) / 10000, path: doc.path || '',
            title: doc.title || '', breadcrumb: doc.breadcrumb || '', category: doc.category || '', url: doc.url || '' };
        if (withSnippet)
            item.snippet = makeSnippet(doc.path || '', queryTerms);
        return item;
    });
    const payload = { query, query_terms: queryTerms, total_searched: totalSearched,
        elapsed_sec: Math.round(elapsed * 10000) / 10000, count: results.length, results };
    return JSON.stringify(payload, null, 2);
}
export function searchJson(query, options = {}) {
    const [hits, documents, terms, elapsed, total] = search(query, options.top, options.category, options.withSnippet, options.mode);
    return JSON.parse(formatJson(query, hits, documents, terms, elapsed, total, options.withSnippet ?? false));
}
export function formatResults(query, hits, documents, queryTerms, elapsed, totalSearched, withSnippet) {
    const lines = ['Top ' + hits.length + ' results for "' + query + '" (searched ' + totalSearched + ' docs in ' + elapsed.toFixed(3) + 's)', ''];
    if (!hits.length) {
        lines.push('建议选择其他检索方法');
        return lines.join('\n');
    }
    hits.forEach(([id, score], offset) => {
        const doc = documents[id], idx = doc.category.indexOf('(');
        const category = idx > 0 ? doc.category.slice(0, idx).trim() : doc.category.slice(0, 20);
        lines.push('[' + (offset + 1) + '] score=' + score.toFixed(2) + '  ' + category + '  ' + doc.path);
        if (doc.title)
            lines.push('    Title: ' + doc.title);
        if (doc.breadcrumb)
            lines.push('    Breadcrumb: ' + doc.breadcrumb);
        if (withSnippet) {
            const snippet = makeSnippet(doc.path, queryTerms);
            if (snippet)
                lines.push('    Snippet: ' + snippet);
        }
        lines.push('');
    });
    return lines.join('\n').trimEnd() + '\n';
}
export function main(args = process.argv.slice(2)) {
    if (!args.length || args[0] === '--help') {
        console.error('用法: node scripts/search.js "查询字符串" [--top N] [--category CAT] [--snippet] [--json] [--mode default|conservative|aggressive]');
        return args[0] === '--help' ? 0 : 1;
    }
    try {
        const query = args[0];
        let top = 10, category, withSnippet = false, asJson = false, mode = 'default';
        for (let i = 1; i < args.length; i++) {
            const argument = args[i];
            if (argument === '--top' || argument === '--category' || argument === '--mode') {
                const value = args[++i];
                if (value === undefined || value.startsWith('--'))
                    throw new Error(argument + ' 缺少参数');
                if (argument === '--top')
                    top = Number(value);
                else if (argument === '--category')
                    category = value;
                else
                    mode = validateMode(value);
            }
            else if (argument === '--snippet')
                withSnippet = true;
            else if (argument === '--json')
                asJson = true;
            else
                throw new Error('未知参数: ' + argument);
        }
        const [hits, docs, terms, elapsed, total] = search(query, top, category, withSnippet, mode);
        console.log((asJson ? formatJson : formatResults)(query, hits, docs, terms, elapsed, total, withSnippet));
        return 0;
    }
    catch (error) {
        console.error(error instanceof Error ? error.message : String(error));
        return 1;
    }
}
if (isMain(import.meta.url))
    process.exitCode = main();
