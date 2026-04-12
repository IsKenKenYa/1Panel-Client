import json

with open('../../OpenSource/1Panel/core/cmd/server/docs/swagger.json', 'r') as f:
    swagger = json.load(f)

# The output from check_module_client_coverage.py might have text before the JSON array
with open('coverage_round3.json', 'r') as f:
    content = f.read()

# Find the start of the JSON object
start_idx = content.find('{')
if start_idx != -1:
    json_str = content[start_idx:]
    try:
        coverage = json.loads(json_str)
        
        print("=== Endpoints Missing in Client ===")
        for result in coverage.get('results', []):
            if result.get('status') == 'missing_in_client':
                module_name = result.get('module')
                for ep in result.get('missingInClient', []):
                    path = ep['path']
                    method = ep['method'].lower()
                    
                    info = swagger.get('paths', {}).get(path, {}).get(method, {})
                    req_schema = "None"
                    for param in info.get('parameters', []):
                        if param.get('in') == 'body':
                            req_schema = param.get('schema', {}).get('$ref', 'Unknown')
                    
                    resp_schema = "None"
                    responses = info.get('responses', {})
                    if '200' in responses:
                        schema = responses['200'].get('schema', {})
                        if '$ref' in schema:
                            resp_schema = schema['$ref']
                        elif 'items' in schema and '$ref' in schema['items']:
                            resp_schema = "List[" + schema['items']['$ref'] + "]"
                        else:
                            resp_schema = str(schema)
                            
                    print(f"[{module_name}] Missing: {method.upper()} {path}")
                    print(f"  Req:  {req_schema}")
                    print(f"  Resp: {resp_schema}")
                    print()
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
else:
    print("Could not find JSON in coverage_round3.json")
