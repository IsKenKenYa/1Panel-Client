import os
import sys
import argparse
import json
from pathlib import Path

def search_api_documents(api_name, search_dir, language=None, module=False, verify=False, limit=50, verbose=False):
    results = []
    
    search_path = Path(search_dir)
    if not search_path.exists():
        print(f"Error: Search directory '{search_dir}' does not exist")
        return results
    
    if language:
        lang_map = {
            'arkts': 'ArkTS',
            'c': 'C',
            'rest': 'REST'
        }
        lang_dir = lang_map.get(language.lower(), language)
        search_path = search_path / lang_dir
    
    if verbose:
        print(f"Searching for '{api_name}' in '{search_path}'")
    
    for file_path in search_path.rglob('*.md'):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
                if module:
                    if api_name.lower() in content.lower() or api_name in content:
                        results.append(str(file_path))
                else:
                    if api_name in content:
                        if verify:
                            if f'OH_{api_name}' in content or f'{api_name}(' in content or f'{api_name}<' in content:
                                results.append(str(file_path))
                        else:
                            results.append(str(file_path))
                
                if len(results) >= limit:
                    break
                    
        except Exception as e:
            if verbose:
                print(f"Error reading file '{file_path}': {e}")
            continue
    
    return results

def main():
    parser = argparse.ArgumentParser(
        description='Search HarmonyOS API reference documentation paths',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python search_api.py OH_NetConn_GetDefaultNet
    python search_api.py OH_NetConn_GetDefaultNet -L c
    python search_api.py OH_NetConn_GetDefaultNet --verify
    python search_api.py OH_NetConn_GetDefaultNet -d D:\\code\\APIDevice\\output\\md_output\\harmonyos-references
        """
    )
    
    parser.add_argument('api_name', help='API name to search')
    parser.add_argument('-d', '--dir', default='D:\\code\\APIDevice\\output\\md_output\\harmonyos-references',
                       help='Search directory (default: harmonyos-references)')
    parser.add_argument('-k', '--kit-name', help='Filter by Kit name')
    parser.add_argument('-L', '--language', choices=['ArkTS', 'C', 'REST'],
                       help='Filter API language classification directory')
    parser.add_argument('-m', '--module', action='store_true',
                       help='Search by module name (e.g., @ohos.ability.ability)')
    parser.add_argument('--verify', action='store_true',
                       help='Verify file contains API definition (reduces false positives, slower)')
    parser.add_argument('-l', '--limit', type=int, default=50,
                       help='Limit number of results (default: 50)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Show detailed output')
    
    args = parser.parse_args()
    
    results = search_api_documents(
        api_name=args.api_name,
        search_dir=args.dir,
        language=args.language,
        module=args.module,
        verify=args.verify,
        limit=args.limit,
        verbose=args.verbose
    )
    
    if results:
        print(f"\nFound {len(results)} matching documents for '{args.api_name}':")
        for i, result in enumerate(results, 1):
            print(f"{i}. {result}")
    else:
        print(f"\nNo matching files found for '{args.api_name}'")

if __name__ == '__main__':
    main()