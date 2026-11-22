import type { Features, Mode, TermMatch, Thresholds } from './types.ts';
export const MODES: readonly Mode[] = ['default', 'conservative', 'aggressive'];
export const THRESHOLDS: Readonly<Record<Mode, Readonly<Thresholds>>> = Object.freeze({
  default: Object.freeze({ bm25: 0.9, coverage: 0.835585586 }),
  conservative: Object.freeze({ bm25: 1.7554734, coverage: 0.7520270274 }),
  aggressive: Object.freeze({ bm25: 1.97003126, coverage: 0.84394144186 }),
});
const evidenceView = new DataView(new ArrayBuffer(8));
export function validateMode(value: unknown): Mode {
  if (!MODES.includes(value as Mode)) throw new Error('mode 必须是 default、conservative 或 aggressive');
  return value as Mode;
}
export function compact(term: string): string {
  return Array.from(term.normalize('NFKC').toLowerCase()).filter(ch => /[\p{L}\p{N}\u3400-\ufaff]/u.test(ch)).join('');
}
export function buildTokenWeights(terms: string[]): Map<string, number> {
  const unique = [...new Set(terms)];
  const surfaces = new Map(unique.map(t => [t, compact(t)]));
  return new Map(unique.map(term => {
    const surface = surfaces.get(term)!;
    const containers = unique.filter(other => other !== term && surface
      && surface !== surfaces.get(other) && surfaces.get(other)!.includes(surface)).length;
    return [term, Math.max(1, Array.from(surface).length) / (1 + containers)];
  }));
}

/** Python round(x, 6) used by the original evidence layer, including binary ties. */
export function roundEvidence(value: number): number {
  if (!Number.isFinite(value)) throw new Error('non-finite BM25 contribution');
  if (value === 0) return 0;
  evidenceView.setFloat64(0, Math.abs(value), false);
  const bits = evidenceView.getBigUint64(0, false);
  const exponentBits = Number((bits >> 52n) & 2047n);
  const mantissa = (bits & ((1n << 52n) - 1n)) | (exponentBits === 0 ? 0n : 1n << 52n);
  const exponent = (exponentBits === 0 ? -1022 : exponentBits - 1023) - 52;
  let numerator = mantissa * 1000000n;
  let denominator = 1n;
  if (exponent >= 0) numerator <<= BigInt(exponent);
  else denominator <<= BigInt(-exponent);
  let rounded = numerator / denominator;
  const remainder = numerator % denominator;
  if (2n * remainder > denominator || (2n * remainder === denominator && rounded % 2n === 1n)) rounded++;
  return Math.sign(value) * Number(rounded) / 1e6;
}

export function computeFeatures(weights: Map<string, number>, matches: TermMatch[]): Features {
  const byTerm = new Map(matches.map(match => [match.term, match]));
  let total = 0, matched = 0, numerator = 0;
  for (const [term, weight] of weights) {
    total += weight;
    const detail = byTerm.get(term);
    if (detail) {
      matched += weight;
      numerator += weight * (roundEvidence(detail.contribution) / Math.max(1, detail.query_tf));
    }
  }
  return { weighted_bm25: total ? numerator / total : 0,
    weighted_query_coverage: total ? matched / total : 0, matched_weight: matched, total_weight: total };
}
export function decide(features: Features, mode: Mode = 'default') {
  const thresholds = THRESHOLDS[validateMode(mode)];
  const failed_gates: ('bm25' | 'coverage')[] = [];
  if (!(features.weighted_bm25 > thresholds.bm25)) failed_gates.push('bm25');
  if (!(features.weighted_query_coverage > thresholds.coverage)) failed_gates.push('coverage');
  return { accepted: failed_gates.length === 0, failed_gates };
}
