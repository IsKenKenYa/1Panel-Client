import json

with open('coverage_new.json', 'r') as f:
    lines = f.readlines()

clean_lines = []
for line in lines:
    if line.strip() == '需要处理的模块:':
        break
    clean_lines.append(line)

with open('coverage_new.json', 'w') as f:
    f.writelines(clean_lines)

try:
    with open('coverage_new.json', 'r') as f:
        json.load(f)
    print("JSON is valid.")
except Exception as e:
    print(f"JSON invalid: {e}")
