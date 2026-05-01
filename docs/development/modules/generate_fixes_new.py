import json

with open('../../OpenSource/1Panel/core/cmd/server/docs/swagger.json', 'r') as f:
    swagger = json.load(f)

with open('coverage_new.json', 'r') as f:
    coverage = json.load(f)

print("=== Endpoints to Add/Fix ===")
for result in coverage['results']:
    if result.get('status') == 'missing_in_client':
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
            print(f"Missing: {method.upper()} {path} (Module: {result.get('module')})")
            print(f"  Req:  {req_schema}")
            print(f"  Resp: {resp_schema}")
            print()
