"""
ArkUI Knowledge Base - Search CLI
"""

import os
import sys
import argparse
import json

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(SCRIPTS_DIR)
sys.path.insert(0, SCRIPTS_DIR)

DEFAULT_KNOWLEDGE_DIR = os.path.join(SKILL_DIR, "references", "knowledges")  # ArkTS 库
NDK_KNOWLEDGE_DIR = os.path.join(SKILL_DIR, "references", "ndk-knowledges")  # NDK 库

# 技术栈 → 知识库目录列表(both 表示两库都查)
DOMAIN_KB_DIRS = {
    "arkts": [DEFAULT_KNOWLEDGE_DIR],
    "ndk": [NDK_KNOWLEDGE_DIR],
    "both": [DEFAULT_KNOWLEDGE_DIR, NDK_KNOWLEDGE_DIR],
}


def search_interactive(args):
    from retriever import ArkUIRetriever

    retriever = ArkUIRetriever(knowledge_dir=args.knowledge_dir or DEFAULT_KNOWLEDGE_DIR)

    print(f"\n{'='*60}")
    print("ArkUI Knowledge Base - Interactive Search")
    print("Type your query and press Enter. Type 'quit' to exit.")
    print(f"{'='*60}\n")

    while True:
        try:
            query = input("\nQuery: ").strip()

            if query.lower() in ["quit", "exit", "q"]:
                print("Goodbye!")
                break

            if not query:
                continue

            result = retriever.retrieve(query, k=args.top_k)

            print(f"\n{'='*50}")
            print(f"Results for: {query}")
            print(f"{'='*50}")

            for i, doc in enumerate(result.documents, 1):
                print(f"\n[{i}] {doc.title}")
                print(f"    Source: {doc.source}")
                print(f"    Category: {doc.category}")
                print(f"    Score: {doc.score:.3f}")
                print(f"    Preview: {doc.content[:150]}...")

            if result.code_examples:
                print(f"\n{'='*50}")
                print("Code Examples:")
                print(f"{'='*50}")
                for ex in result.code_examples[:2]:
                    print(f"\n[{ex['language']}] from {ex['title']}")
                    print(f"  {ex['code'][:200]}...")

            if result.suggested_queries:
                print(f"\nSuggested follow-ups:")
                for sq in result.suggested_queries[:3]:
                    print(f"  - {sq}")

        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")


def query_once(args):
    from retriever import ArkUIRetriever, detect_domain

    # 确定要检索的知识库目录列表 + 路由说明
    if args.knowledge_dir:
        kb_dirs = [args.knowledge_dir]
        route = "manual: " + os.path.basename(args.knowledge_dir.rstrip(os.sep))
    elif args.domain:
        kb_dirs = DOMAIN_KB_DIRS[args.domain]
        route = "--domain " + args.domain
    elif args.category:
        # 指定分类时跨库查询再过滤(分类名可能属于任一库)
        kb_dirs = DOMAIN_KB_DIRS["both"]
        route = "auto: both (category filter)"
    else:
        domain = detect_domain(args.query)
        kb_dirs = DOMAIN_KB_DIRS[domain]
        route = "auto: " + domain

    filters = {"category": args.category} if args.category else None
    rerank_weights = {
        "direct_hit": args.rerank_direct_hit,
        "keyword_coverage": args.rerank_keyword_coverage,
        "title_phrase": args.rerank_title_phrase,
        "source_phrase": args.rerank_source_phrase,
    }

    documents_output = []
    code_examples = []
    seen_sources = set()
    for kb_dir in kb_dirs:
        retriever = ArkUIRetriever(knowledge_dir=kb_dir)
        result = retriever.retrieve(
            args.query,
            k=args.top_k,
            filters=filters,
            rerank_weights=rerank_weights,
            max_content_chars=999999 if args.full_content else args.max_content_chars,
            max_total_chars=999999 if args.full_content else args.max_total_chars,
            dedup=not args.no_dedup,
            compact=not args.no_compact,
        )
        kb_name = os.path.basename(kb_dir.rstrip(os.sep))
        for doc in result.documents:
            if doc.source in seen_sources:
                continue
            seen_sources.add(doc.source)
            doc_out = {
                "id": doc.id,
                "title": doc.title,
                "source": doc.source,
                "category": doc.category,
                "knowledge_base": kb_name,
                "content": doc.content,
                "_score": doc.score,
            }
            if args.debug:
                doc_out["score"] = round(doc.score, 4)
                doc_out["debug"] = {
                    "rerank_score": doc.metadata.get("rerank_score"),
                    "base_score": doc.metadata.get("base_score"),
                    "direct_hit": doc.metadata.get("direct_hit"),
                    "keyword_hits": doc.metadata.get("keyword_hits"),
                }
            documents_output.append(doc_out)
        for ex in result.code_examples:
            ex_out = dict(ex)
            ex_out["knowledge_base"] = kb_name
            code_examples.append(ex_out)

    documents_output.sort(key=lambda d: d["_score"], reverse=True)
    documents_output = documents_output[: args.top_k]
    if not args.debug:
        for d in documents_output:
            d.pop("_score", None)

    output = {
        "query": args.query,
        "routed_to": route,
        "total": len(documents_output),
        "documents": documents_output,
    }
    if args.include_code:
        output["code_examples"] = code_examples

    if args.format == "json":
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return

    print(f"Query: {args.query}")
    print(f"Routed to: {route}")
    print(f"Total: {len(documents_output)}")
    print("-" * 60)
    for i, doc in enumerate(documents_output, 1):
        print(f"[{i}] {doc['title']}")
        print(f"  KB: {doc['knowledge_base']}  |  Source: {doc['source']}")
        print(f"  Category: {doc['category']}")
        print(f"  Content: {doc['content']}")
        print()


def assess_search(args):
    from retriever import ArkUIRetriever

    retriever = ArkUIRetriever(knowledge_dir=args.knowledge_dir or DEFAULT_KNOWLEDGE_DIR)
    result = retriever.assess_search_necessity(args.query)

    if args.format == "json":
        print(json.dumps({"query": args.query, **result}, ensure_ascii=False, indent=2))
        return

    level_labels = {"must": "MUST", "should": "SHOULD", "skip": "SKIP"}
    print(f"Query: {args.query}")
    print(f"Level: {level_labels.get(result['level'], result['level'])}")
    print(f"Reason: {result['reason']}")
    print(f"Action: {result['action']}")


def main():
    parser = argparse.ArgumentParser(description="ArkUI Knowledge Base CLI")
    parser.add_argument(
        "--knowledge-dir",
        default=None,
        help="Knowledge base directory (指定则关闭自动路由)",
    )

    subparsers = parser.add_subparsers(dest="command", help="Command")

    search_parser = subparsers.add_parser("search", help="Interactive search")
    search_parser.add_argument("--top-k", type=int, default=3)

    query_parser = subparsers.add_parser("query", help="Single query (non-interactive)")
    query_parser.add_argument("query", help="Search query")
    query_parser.add_argument("--top-k", type=int, default=3)
    query_parser.add_argument("--category", action="append", help="Filter by category")
    query_parser.add_argument("--domain", choices=["ndk", "arkts", "both"], help="手动指定技术栈,覆盖自动路由")
    query_parser.add_argument("--format", choices=["json", "text"], default="json")
    query_parser.add_argument("--max-content-chars", type=int, default=1000, help="Max chars per document content")
    query_parser.add_argument("--max-total-chars", type=int, default=6000, help="Max total chars across all documents")
    query_parser.add_argument("--include-code", action="store_true")
    query_parser.add_argument("--full-content", action="store_true", help="Return full document content (no truncation)")
    query_parser.add_argument("--no-dedup", action="store_true", help="Disable cross-query deduplication")
    query_parser.add_argument("--no-compact", action="store_true", help="Disable compact extraction (use simple truncation)")
    query_parser.add_argument("--debug", action="store_true", help="Include debug metadata (scores, match details)")
    query_parser.add_argument("--rerank-direct-hit", type=float, default=0.20)
    query_parser.add_argument("--rerank-keyword-coverage", type=float, default=0.30)
    query_parser.add_argument("--rerank-title-phrase", type=float, default=0.15)
    query_parser.add_argument("--rerank-source-phrase", type=float, default=0.10)

    assess_parser = subparsers.add_parser("assess", help="Assess whether search is needed")
    assess_parser.add_argument("query", help="Query to assess")
    assess_parser.add_argument("--format", choices=["json", "text"], default="json")

    args = parser.parse_args()

    if args.command == "search":
        search_interactive(args)
    elif args.command == "query":
        query_once(args)
    elif args.command == "assess":
        assess_search(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
