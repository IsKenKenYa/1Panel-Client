import os
import glob
import re

def fix_files():
    api_dir = 'lib/api/v2'
    files = glob.glob(f'{api_dir}/*.dart')
    
    for file in files:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original = content
        
        # 1. Replace Future<Response> with Future<Response<void>>
        # But wait, what if it actually returns data? 
        # If it's `Future<Response> methodName`, and the method just does `return await _client.post(`, 
        # we change to `Future<Response<void>> methodName` and `_client.post<void>(`
        
        # Let's find all methods returning Future<Response>
        # and change them to Future<Response<void>>
        content = re.sub(r'Future<Response>\s+(\w+)\s*\(', r'Future<Response<void>> \1(', content)
        
        # Also change Future<Response<dynamic>> to Future<Response<void>>
        content = re.sub(r'Future<Response<dynamic>>\s+(\w+)\s*\(', r'Future<Response<void>> \1(', content)
        
        # Change `_client.post(` to `_client.post<void>(` in those methods? 
        # Actually, let's just globally replace `await _client.post(` with `await _client.post<void>(` 
        # IF it doesn't already have `<...>`
        content = re.sub(r'_client\.post\(([^<])', r'_client.post<void>(\1', content)
        content = re.sub(r'_client\.put\(([^<])', r'_client.put<void>(\1', content)
        content = re.sub(r'_client\.delete\(([^<])', r'_client.delete<void>(\1', content)

        # For _client.get without generic, it's harder, maybe change to _client.get<dynamic>
        content = re.sub(r'_client\.get\(([^<])', r'_client.get<dynamic>(\1', content)
        
        # Now fix queryParameters in POST/PUT
        # If we have `queryParameters: <String, dynamic>{...}` in a post, change it to `data: ...`
        # This is tricky because `data` already exists. 
        # E.g. data: request.toJson(), queryParameters: <String, dynamic>{'operateNode': operateNode},
        # Should become data: request.toJson()..addAll({'operateNode': operateNode})
        # Let's just fix backup_account_v2.dart manually.
        
        if content != original:
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed {file}")

if __name__ == '__main__':
    fix_files()
