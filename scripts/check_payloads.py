import os
import glob
import re

def check_files():
    api_dir = 'lib/api/v2'
    files = glob.glob(f'{api_dir}/*.dart')
    
    issues = []
    
    for file in files:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Find method definitions returning Future<Response> or Future<Response<dynamic>>
            matches = re.finditer(r'Future<(Response(?:<dynamic>|))>\s+(\w+)\s*\(', content)
            for match in matches:
                issues.append(f"{file}: Method '{match.group(2)}' returns {match.group(1)} instead of a strong type.")
                
            # Find post/put using queryParameters
            post_put_matches = re.finditer(r'_client\.(post|put)(?:<[^>]+>)?\([^;]+queryParameters\s*:', content, re.DOTALL)
            for match in post_put_matches:
                # We need to find the method name this belongs to, or just the line
                snippet = match.group(0)[:50]
                issues.append(f"{file}: post/put uses queryParameters instead of data: {snippet}...")
                
    if issues:
        print("Issues found:")
        for issue in issues:
            print(issue)
    else:
        print("No issues found!")

if __name__ == '__main__':
    check_files()
