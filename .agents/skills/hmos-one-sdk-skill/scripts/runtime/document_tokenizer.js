import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { resolve } from 'node:path';
import { JIEBA_ASSET_DIR, loadGzipJson } from './storage.js';
import { LATIN, STOPWORDS, expandSpecialTerm } from './tokenizer.js';
const MIN = -3.14e100;
const STATES = ['B', 'M', 'E', 'S'];
const PREVIOUS = { B: ['E', 'S'], M: ['M', 'B'], S: ['S', 'E'], E: ['B', 'M'] };
const HAN_BLOCK = /([\u4e00-\u9fd5a-zA-Z0-9+#&._%\-]+)/u;
const IS_HAN_BLOCK = /^[\u4e00-\u9fd5a-zA-Z0-9+#&._%\-]+$/u;
const HMM_HAN = /([\u4e00-\u9fd5]+)/u;
const HMM_IS_HAN = /^[\u4e00-\u9fd5]+$/u;
const CJK = /[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]/u;
const SPACE = /[\p{White_Space}\u001c-\u001f]/gu;
export class DocumentTokenizer {
    frequencies = new Map();
    totalFrequency;
    prefixes = new Set();
    model;
    folds;
    logTotal;
    constructor(assetDirectory = JIEBA_ASSET_DIR) {
        this.model = loadGzipJson(resolve(assetDirectory, 'hmm.json.gz'));
        this.folds = loadGzipJson(resolve(assetDirectory, 'casefold.json.gz'));
        let total = 0;
        for (const line of gunzipSync(readFileSync(resolve(assetDirectory, 'dict.txt.gz'))).toString('utf8').split('\n')) {
            if (!line.trim())
                continue;
            const [word, frequency] = line.trim().split(' '), freq = Number(frequency);
            if (!word || !Number.isInteger(freq) || freq < 0)
                throw new Error('无效 Jieba 词典行');
            this.frequencies.set(word, freq);
            total += freq;
            for (let end = 1; end <= word.length; end++)
                this.prefixes.add(word.slice(0, end));
        }
        if (!total)
            throw new Error('Jieba 词典为空');
        this.totalFrequency = total;
        this.logTotal = Math.log(total);
    }
    hmmChinese(sentence) {
        const chars = Array.from(sentence), size = chars.length;
        if (!size)
            return [];
        let scores = STATES.map(state => this.model.start[state] + (this.model.emit[state][chars[0]] ?? MIN));
        const back = new Uint8Array(size * 4);
        for (let i = 1; i < size; i++) {
            const next = new Array(4);
            for (const [s, state] of STATES.entries()) {
                const emit = this.model.emit[state][chars[i]] ?? MIN;
                let best = -Infinity, previous = 'B';
                for (const prev of PREVIOUS[state]) {
                    const score = scores[STATES.indexOf(prev)] + (this.model.trans[prev][state] ?? MIN) + emit;
                    if (score > best || (score === best && prev > previous)) {
                        best = score;
                        previous = prev;
                    }
                }
                next[s] = best;
                back[i * 4 + s] = STATES.indexOf(previous);
            }
            scores = next;
        }
        let state = scores[2] > scores[3] ? 2 : 3;
        const path = new Uint8Array(size);
        path[size - 1] = state;
        for (let i = size - 1; i > 0; i--) {
            state = back[i * 4 + state];
            path[i - 1] = state;
        }
        const result = [];
        let begin = 0, next = 0;
        for (let i = 0; i < size; i++) {
            if (path[i] === 0)
                begin = i;
            else if (path[i] === 2) {
                result.push(chars.slice(begin, i + 1).join(''));
                next = i + 1;
            }
            else if (path[i] === 3) {
                result.push(chars[i]);
                next = i + 1;
            }
        }
        if (next < size)
            result.push(chars.slice(next).join(''));
        return result;
    }
    hmm(sentence) {
        return sentence.split(HMM_HAN).flatMap(block => HMM_IS_HAN.test(block)
            ? this.hmmChinese(block) : block.split(/([a-zA-Z0-9]+(?:\.\d+)?%?)/u).filter(Boolean));
    }
    dag(sentence) {
        const size = sentence.length, scores = new Float64Array(size + 1), ends = new Int32Array(size);
        for (let start = size - 1; start >= 0; start--) {
            let best = -Infinity, bestEnd = start;
            for (let end = start; end < size; end++) {
                const word = sentence.slice(start, end + 1);
                if (!this.prefixes.has(word))
                    break;
                const freq = this.frequencies.get(word);
                if (!freq)
                    continue;
                const score = Math.log(freq) - this.logTotal + scores[end + 1];
                if (score >= best) {
                    best = score;
                    bestEnd = end;
                }
            }
            scores[start] = best === -Infinity ? -this.logTotal + scores[start + 1] : best;
            ends[start] = bestEnd + 1;
        }
        const result = [];
        let buffer = '';
        const flush = () => {
            if (buffer.length === 1)
                result.push(buffer);
            else if (buffer)
                result.push(...(this.frequencies.get(buffer) ? Array.from(buffer) : this.hmm(buffer)));
            buffer = '';
        };
        for (let start = 0; start < size;) {
            const end = ends[start], word = sentence.slice(start, end);
            if (word.length === 1)
                buffer += word;
            else {
                flush();
                result.push(word);
            }
            start = end;
        }
        flush();
        return result;
    }
    cut(text) {
        return text.split(HAN_BLOCK).flatMap(block => IS_HAN_BLOCK.test(block) ? this.dag(block)
            : block.split(/(\r\n|[\p{White_Space}\u001c-\u001f])/u).flatMap(piece => piece === '\r\n' ? [piece] : Array.from(piece)));
    }
    clean(input) {
        const normalized = input.normalize('NFKC');
        const token = Array.from(normalized, char => this.folds[char] ?? char.toLowerCase()).join('')
            .replace(/^[\p{White_Space}\u001c-\u001f]+|[\p{White_Space}\u001c-\u001f]+$/gu, '');
        if (!token || STOPWORDS.has(token) || /^[\p{Nd}._+\-]+$/u.test(token))
            return '';
        return !CJK.test(token) && Array.from(token).length < 2 ? '' : token;
    }
    tokenize(input) {
        const text = input.normalize('NFKC'), result = [];
        const other = (chunk) => {
            const cleaned = chunk.replace(/[\p{P}\p{S}]/gu, ' ').replace(SPACE, ' ').replace(/ +/g, ' ').trim();
            if (cleaned)
                for (const piece of this.cut(cleaned)) {
                    const token = this.clean(piece);
                    if (token)
                        result.push(token);
                }
        };
        let cursor = 0;
        for (const match of text.matchAll(LATIN)) {
            other(text.slice(cursor, match.index));
            result.push(...expandSpecialTerm(match[0]));
            cursor = match.index + match[0].length;
        }
        other(text.slice(cursor));
        return result;
    }
}
