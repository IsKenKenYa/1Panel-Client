import { performance } from 'node:perf_hooks';
import { readIndex } from './index_store.js';
import { clearSnippetCache } from './corpus.js';
import { JiebaTokenizer } from './tokenizer.js';
import { buildTokenWeights, decide, roundEvidence, THRESHOLDS, validateMode } from './rejection.js';
export function normalizePath(value) { return value.replaceAll('\\', '/').toLowerCase().replace(/^[./]+/, ''); }
export function documentKit(doc) {
    const parts = doc.path.replaceAll('\\', '/').split('/');
    return parts[0] === 'hmos-sdk-basic-skill' ? (parts[1] || doc.category) : doc.category;
}
function resolveCategory(category, known) {
    const normalize = (s) => s.toLowerCase().replace(/[\s_-]/g, '');
    const requested = normalize(category);
    return known.find(name => name === category)
        ?? known.find(name => normalize(name.split('(')[0]) === requested)
        ?? known.find(name => name.includes('(') && name.slice(name.indexOf('(') + 1, name.indexOf(')')).includes(category))
        ?? known.find(name => normalize(name.split('(')[0]).includes(requested))
        ?? category;
}
export class JiebaRuntime {
    index;
    tokenizer;
    scores;
    seen;
    norms;
    topSlots;
    matched = new Float64Array(10);
    numerators = new Float64Array(10);
    touched = [];
    kits;
    categories;
    constructor(index = readIndex()) {
        this.index = index;
        this.tokenizer = new JiebaTokenizer(index.inverted, index.lexicon);
        const { documents, meta } = index;
        this.scores = new Float64Array(documents.length);
        this.seen = new Uint8Array(documents.length);
        this.topSlots = new Int32Array(documents.length);
        const k1 = meta.k1 || 1.5, b = meta.b || .75, avgdl = meta.avg_doc_length || 1;
        this.norms = Float64Array.from(documents, doc => k1 * (1 - b + b * doc.length / avgdl));
        this.kits = documents.map(documentKit);
        this.categories = [...new Set(documents.flatMap((doc, id) => [doc.category, this.kits[id]]))];
    }
    explain(query, options = {}) {
        if (typeof query !== 'string')
            throw new Error('query 必须是字符串');
        const mode = validateMode(options.mode ?? 'default');
        const top = options.top ?? 10;
        if (!Number.isInteger(top) || top < 1)
            throw new Error('top 必须是正整数');
        if (options.category !== undefined && typeof options.category !== 'string')
            throw new Error('category 必须是字符串');
        const started = performance.now();
        const terms = this.tokenizer.tokenize(query);
        const counts = new Map();
        for (const term of terms)
            counts.set(term, (counts.get(term) || 0) + 1);
        const weights = buildTokenWeights(terms);
        const { documents, inverted, meta } = this.index;
        const nDocs = documents.length, k1 = meta.k1 || 1.5;
        this.scores.fill(0);
        this.seen.fill(0);
        this.touched.length = 0;
        for (const [term, query_tf] of counts) {
            const postings = Object.hasOwn(inverted, term) ? inverted[term] : undefined;
            if (!postings?.length)
                continue;
            const df = postings.length / 2;
            const idf = Math.log(1 + (nDocs - df + 0.5) / (df + 0.5));
            for (let offset = 0; offset < postings.length; offset += 2) {
                const doc_id = postings[offset], doc_tf = postings[offset + 1];
                const single = idf * doc_tf * (k1 + 1) / (doc_tf + this.norms[doc_id]);
                this.scores[doc_id] += single * query_tf;
                if (!this.seen[doc_id]) {
                    this.seen[doc_id] = 1;
                    this.touched.push(doc_id);
                }
            }
        }
        const target = options.category ? resolveCategory(options.category, this.categories) : undefined;
        const ranked = (target === undefined ? this.touched
            : this.touched.filter(id => documents[id].category === target || this.kits[id] === target))
            .sort((a, b) => this.scores[b] - this.scores[a] || a - b).slice(0, 10);
        this.topSlots.fill(-1);
        this.matched.fill(0);
        this.numerators.fill(0);
        ranked.forEach((id, slot) => { this.topSlots[id] = slot; });
        let total = 0;
        for (const [term, weight] of weights) {
            total += weight;
            const postings = Object.hasOwn(inverted, term) ? inverted[term] : undefined;
            if (!postings?.length)
                continue;
            const query_tf = counts.get(term);
            const df = postings.length / 2, idf = Math.log(1 + (nDocs - df + .5) / (df + .5));
            for (let offset = 0; offset < postings.length; offset += 2) {
                const doc_id = postings[offset], slot = this.topSlots[doc_id];
                if (slot < 0)
                    continue;
                const doc_tf = postings[offset + 1];
                const single = idf * doc_tf * (k1 + 1) / (doc_tf + this.norms[doc_id]);
                this.matched[slot] += weight;
                this.numerators[slot] += weight * (roundEvidence(single * query_tf) / Math.max(1, query_tf));
            }
        }
        const candidates = ranked.map((doc_id, offset) => {
            const matched = this.matched[offset], numerator = this.numerators[offset];
            const features = { weighted_bm25: total ? numerator / total : 0,
                weighted_query_coverage: total ? matched / total : 0, matched_weight: matched, total_weight: total };
            return { doc_id, path: documents[doc_id].path, score: this.scores[doc_id], raw_rank: offset + 1,
                ...features, ...decide(features, mode) };
        });
        const accepted = candidates.filter(item => item.accepted).slice(0, top);
        return { query, query_terms: terms, mode, thresholds: { ...THRESHOLDS[mode] }, candidates, accepted,
            abstained: accepted.length === 0, elapsed_sec: (performance.now() - started) / 1000, total_searched: documents.length };
    }
}
let singleton;
export function getRuntime() { return singleton ??= new JiebaRuntime(); }
export function reloadRuntime() {
    const next = new JiebaRuntime();
    singleton = next;
    clearSnippetCache();
    return next;
}
