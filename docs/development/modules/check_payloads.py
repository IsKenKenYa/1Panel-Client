import json
import re
import os
import glob

with open('../../OpenSource/1Panel/core/cmd/server/docs/swagger.json', 'r') as f:
    swagger = json.load(f)

api_files = glob.glob('../../../lib/api/v2/*_v2.dart')

print("=== API Payload & Return Type Anomalies ===")
anomalies = []

for file_path in api_files:
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Simple regex to find Future<Response<T>> methodName(...) { ... ApiConstants.buildApiPath('path')
    # It might not catch everything, but it's good for a quick scan
    pattern = re.compile(r'Future<Response(?:<([^>]+)>)?>\s+(\w+)\s*\([^\)]*\)[\s\S]*?ApiConstants\.buildApiPath\([\'"]([^\'"]+)[\'"]\)', re.MULTILINE)
    
    for match in pattern.finditer(content):
        dart_return_type = match.group(1)
        method_name = match.group(2)
        api_path = match.group(3)
        
        clean_path = re.sub(r'\$[a-zA-Z0-9_]+', '{var}', api_path)
        clean_path = re.sub(r'\$\{[^}]+\}', '{var}', clean_path)
        
        # Check swagger
        found_swagger_resp = None
        if clean_path in swagger.get('paths', {}):
            for http_method, info in swagger['paths'][clean_path].items():
                resp_200 = info.get('responses', {}).get('200', {})
                schema = resp_200.get('schema', {})
                
                # Unwrap 1Panel standard response wrapper if it exists (usually data is inside)
                # But Swagger might just document the direct return or standard wrapper
                if '$ref' in schema:
                    found_swagger_resp = schema['$ref'].split('/')[-1]
                elif schema.get('type') == 'array' and '$ref' in schema.get('items', {}):
                    found_swagger_resp = 'List[' + schema['items']['$ref'].split('/')[-1] + ']'
                elif schema.get('type') == 'object':
                    found_swagger_resp = 'Object'
                    
        if found_swagger_resp and found_swagger_resp not in ['None', 'Object']:
            # If swagger specifies a specific DTO, but Dart returns generic/void/dynamic
            if not dart_return_type or dart_return_type in ['dynamic', 'void', 'Map<String, dynamic>', 'Response']:
                anomalies.append({
                    'file': os.path.basename(file_path),
                    'method': method_name,
                    'path': clean_path,
                    'swagger': found_swagger_resp,
                    'dart': dart_return_type or 'Raw Response'
                })

for a in anomalies:
    print(f"[{a['file']}] {a['method']} ({a['path']})")
    print(f"   Swagger expects: {a['swagger']}")
    print(f"   Dart returns:    {a['dart']}\n")

if not anomalies:
    print("No obvious return type anomalies found.")

