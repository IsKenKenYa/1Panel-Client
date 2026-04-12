import os
import glob
import re

def fix_responses():
    files = glob.glob('lib/api/v2/*.dart')
    
    for file in files:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original = content
        
        # Regex to find Future<Response> methodName(...) async { return await _client.post(...); }
        # We need to be careful. Let's find blocks like:
        # Future<Response(?:<dynamic>)?>\s+(\w+)\s*\([^)]*\)\s*(?:async\s*)?\{\s*return\s+(?:await\s+)?_client\.(post|put|delete|get)\((.*?)\s*;\s*\}
        
        pattern = re.compile(r'(Future<Response(?:<dynamic>)?>\s+\w+\s*\([^)]*\)\s*(?:async\s*)?\{\s*return\s+(?:await\s+)?_client\.(post|put|delete|get))\((.*?)\s*;\s*\}', re.DOTALL)
        
        def replacer(match):
            prefix = match.group(1)
            method = match.group(2)
            rest = match.group(3)
            
            # Replace Future<Response> or Future<Response<dynamic>> with Future<Response<void>>
            prefix = re.sub(r'Future<Response(?:<dynamic>)?>', 'Future<Response<void>>', prefix)
            
            # Replace _client.post( with _client.post<void>(
            prefix = prefix.replace(f'_client.{method}', f'_client.{method}<void>')
            
            return f'{prefix}({rest};' + '\n  }'
            
        content = pattern.sub(replacer, content)
        
        # There might be some with expression bodies: Future<Response> method() => _client.post(...);
        pattern_expr = re.compile(r'(Future<Response(?:<dynamic>)?>\s+\w+\s*\([^)]*\)\s*(?:async\s*)?=>\s*(?:await\s+)?_client\.(post|put|delete|get))\((.*?)\s*;', re.DOTALL)
        def replacer_expr(match):
            prefix = match.group(1)
            method = match.group(2)
            rest = match.group(3)
            prefix = re.sub(r'Future<Response(?:<dynamic>)?>', 'Future<Response<void>>', prefix)
            prefix = prefix.replace(f'_client.{method}', f'_client.{method}<void>')
            return f'{prefix}({rest};'
            
        content = pattern_expr.sub(replacer_expr, content)
        
        if content != original:
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed simple void returns in {file}")

if __name__ == '__main__':
    fix_responses()
