import type { InvertedIndex, QueryLexicon } from './types.ts';

const CJK = /[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]/u;
export const CJK_WORD = /^[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]+$/u;
const CJK_SPANS = /[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]+/gu;
export const LATIN = /(?<![A-Za-z0-9_])(@[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+|[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+|[A-Za-z][A-Za-z0-9_]*(?:\+\+|#)|[A-Za-z0-9][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)+|(?=[A-Za-z0-9_]*[A-Za-z])[A-Za-z0-9_]+)(?![A-Za-z0-9_])/g;
export const STOPWORDS = new Set(('的 了 和 是 在 与 或 及 为 对 由 从 到 可 可以 能够 应 应当 需要 需 进行 通过 使用 用于 以及 等 其 其中 该 这个 这些 一个 一种 一些 上述 下述 如下 例如 比如 不 无 非 未 若 如果 则 那么 即 便 都 '
  + 'the a an is are was were be been being and or not but if then else for of to in on at by with from as into onto this that these those it its they them you your we our us i me my do does did done have has had will would can could should shall may might use used uses using example examples note notes').split(' '));

function cleanToken(input: string): string {
  const token = input.normalize('NFKC').toLowerCase().trim();
  if (!token || STOPWORDS.has(token) || /^[\p{Nd}._+\-]+$/u.test(token)) return '';
  return !CJK.test(token) && Array.from(token).length < 2 ? '' : token;
}
function splitCamel(token: string): string[] {
  const pieces = token.replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2').split(/[\s_-]+/).filter(Boolean).map(s => s.toLowerCase());
  const whole = token.toLowerCase();
  if (whole && !pieces.includes(whole)) pieces.push(whole);
  return pieces;
}
export function expandSpecialTerm(surface: string): string[] {
  const candidates = [cleanToken(surface)];
  for (const component of surface.replace(/^@+/, '').split(/[._\-]+/)) {
    if (!component) continue;
    candidates.push(cleanToken(component), ...splitCamel(component).map(cleanToken));
  }
  return [...new Set(candidates.filter(Boolean))];
}

/** Exact port of the shipped jieba_freq query DP, not native Jieba/HMM. */
export class JiebaTokenizer {
  private readonly vocabulary: InvertedIndex;
  private readonly frequencies: Record<string, number>;
  private readonly maxLength: number;
  private readonly logTotal: number;
  constructor(inverted: InvertedIndex, lexicon: QueryLexicon) {
    this.vocabulary = inverted;
    this.frequencies = lexicon.terms;
    let maxLength = 1;
    for (const term in inverted) if (Object.hasOwn(inverted, term) && CJK_WORD.test(term)) maxLength = Math.max(maxLength, term.length);
    this.maxLength = maxLength;
    this.logTotal = Math.log(Math.max(1, lexicon.total_frequency || Object.values(lexicon.terms).reduce((a, b) => a + b, 0)));
  }
  private segment(span: string): string[] {
    const size = span.length;
    const score = new Float64Array(size + 1);
    const ends = new Int32Array(size);
    for (let start = size - 1; start >= 0; start--) {
      let best = -Infinity;
      let bestEnd = start + 1;
      const upper = Math.min(size, start + this.maxLength);
      for (let end = start + 1; end <= upper; end++) {
        const candidate = span.slice(start, end);
        const frequency = Object.hasOwn(this.frequencies, candidate) ? this.frequencies[candidate] : undefined;
        if (frequency === undefined) continue;
        const candidateScore = Math.log(frequency) - this.logTotal + score[end];
        if (candidateScore > best) { best = candidateScore; bestEnd = end; }
      }
      score[start] = best === -Infinity ? -this.logTotal + score[start + 1] : best;
      ends[start] = bestEnd;
    }
    const tokens: string[] = [];
    for (let start = 0; start < size;) {
      const end = ends[start];
      const candidate = cleanToken(span.slice(start, end));
      if (candidate && Object.hasOwn(this.vocabulary, candidate)) tokens.push(candidate);
      start = end;
    }
    return tokens;
  }
  tokenize(input: string): string[] {
    const text = input.normalize('NFKC');
    const tokens: string[] = [];
    const nonLatin = (part: string) => {
      for (const match of part.matchAll(CJK_SPANS)) tokens.push(...this.segment(match[0]));
    };
    let cursor = 0;
    for (const match of text.matchAll(LATIN)) {
      nonLatin(text.slice(cursor, match.index));
      tokens.push(...expandSpecialTerm(match[0]));
      cursor = match.index + match[0].length;
    }
    nonLatin(text.slice(cursor));
    return tokens;
  }
}
