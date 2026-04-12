import json
import re

with open('coverage_round5.json', 'r') as f:
    content = f.read()

# Find the first {
start_idx = content.find('{')
if start_idx != -1:
    content = content[start_idx:]
    
    # Try parsing by finding the balancing }
    bracket_count = 0
    for i, char in enumerate(content):
        if char == '{':
            bracket_count += 1
        elif char == '}':
            bracket_count -= 1
            if bracket_count == 0:
                json_str = content[:i+1]
                try:
                    coverage = json.loads(json_str)
                    print("=== Remaining Endpoints Missing in Client ===")
                    for result in coverage.get('results', []):
                        if result.get('status') == 'missing_in_client':
                            module_name = result.get('module')
                            for ep in result.get('missingInClient', []):
                                path = ep['path']
                                method = ep['method'].upper()
                                print(f"[{module_name}] Missing: {method} {path}")
                    break
                except Exception as e:
                    print(f"Error parsing JSON: {e}")
                    break
