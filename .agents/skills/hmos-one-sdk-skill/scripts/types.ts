export interface Document {
  id: number; path: string; title: string; breadcrumb: string;
  category: string; url: string; length: number;
}
export type InvertedIndex = Record<string, number[]>;
export interface IndexMeta {
  total_docs: number; avg_doc_length: number; k1: number; b: number;
  tokenizer: string; [key: string]: unknown;
}
export interface QueryLexicon { terms: Record<string, number>; total_frequency: number }
export interface LoadedIndex {
  documents: Document[]; inverted: InvertedIndex; meta: IndexMeta; lexicon: QueryLexicon;
}
export type Mode = 'default' | 'conservative' | 'aggressive';
export interface Thresholds { bm25: number; coverage: number }
export interface TermMatch { term: string; query_tf: number; contribution: number; doc_tf: number }
export interface Features {
  weighted_bm25: number; weighted_query_coverage: number;
  matched_weight: number; total_weight: number;
}
export interface Candidate extends Features {
  doc_id: number; path: string; score: number; raw_rank: number;
  accepted: boolean; failed_gates: ('bm25' | 'coverage')[];
}
export interface SearchOptions { top?: number; category?: string; withSnippet?: boolean; mode?: Mode }
export type SearchTuple = [[number, number][], Document[], string[], number, number];
export interface ResultItem {
  rank: number; score: number; path: string; title: string;
  breadcrumb: string; category: string; url: string; snippet?: string;
}
export interface SearchPayload {
  query: string; query_terms: string[]; total_searched: number;
  elapsed_sec: number; count: number; results: ResultItem[];
}
export interface SearchExplanation {
  query: string; query_terms: string[]; mode: Mode; thresholds: Thresholds;
  candidates: Candidate[]; accepted: Candidate[]; abstained: boolean;
  elapsed_sec: number; total_searched: number;
}
