import json
import re
import os
import glob

SWAGGER_PATH = 'docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json'
DART_API_DIR = 'lib/api/v2'

with open(SWAGGER_PATH, 'r', encoding='utf-8') as f:
    swagger = json.load(f)

swagger_endpoints = set()
for path, methods in swagger.get('paths', {}).items():
    for method in methods.keys():
        if method.lower() in ['get', 'post', 'put', 'delete', 'patch']:
            swagger_endpoints.add((path, method.lower()))

dart_endpoints = set()
dart_files = glob.glob(os.path.join(DART_API_DIR, '*.dart'))

for file_path in dart_files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    path_pattern = re.compile(r"ApiConstants\.buildApiPath\(\s*['\"]([^'\"]+)['\"]\s*\)")
    for path_match in path_pattern.finditer(content):
        raw_path = path_match.group(1)
        start_idx = path_match.start()
        
        lookback_str = content[max(0, start_idx-200):start_idx]
        method_match = re.search(r'_client\s*\.\s*(get|post|put|delete|patch)', lookback_str, re.IGNORECASE)
        
        if method_match:
            method = method_match.group(1).lower()
        else:
            continue
            
        clean_path = re.sub(r'\$([a-zA-Z0-9_]+)', r':\1', raw_path)
        clean_path = re.sub(r'\$\{([a-zA-Z0-9_]+)\}', r':\1', clean_path)
        
        dart_endpoints.add((clean_path, method))

missing_endpoints = []
for s_path, s_method in swagger_endpoints:
    found = False
    norm_s_path = s_path.rstrip('/')
    
    for d_path, d_method in dart_endpoints:
        norm_d_path = d_path.rstrip('/')
        
        s_generic = re.sub(r'\{[a-zA-Z0-9_]+\}', ':var', norm_s_path)
        s_generic = re.sub(r':[a-zA-Z0-9_]+', ':var', s_generic)
        
        d_generic = re.sub(r'\{[a-zA-Z0-9_]+\}', ':var', norm_d_path)
        d_generic = re.sub(r':[a-zA-Z0-9_]+', ':var', d_generic)
        
        s_generic = s_generic.replace('/core/', '/')
        d_generic = d_generic.replace('/core/', '/')
        
        if s_method == d_method and s_generic == d_generic:
            found = True
            break
            
    if not found:
        missing_endpoints.append((s_path, s_method))

print(f"\nTotal Swagger Endpoints: {len(swagger_endpoints)}")
print(f"Total Dart Endpoints Found: {len(dart_endpoints)}")
print(f"Missing Endpoints: {len(missing_endpoints)}")

if missing_endpoints:
    print("\n--- Top 30 Missing Endpoints ---")
    for p, m in sorted(missing_endpoints)[:30]:
        info = swagger['paths'][p][m]
        tags = info.get('tags', ['Unknown'])
        summary = info.get('summary', '')
        print(f"[{tags[0]}] {m.upper()} {p} - {summary}")

