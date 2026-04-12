import re

text = """
  Future<Response> getBackupClient(String type) async {
    return await _client.get(
      ApiConstants.buildApiPath('/core/backups/client/$type'),
    );
  }
"""
pattern = re.compile(r"_client\s*\.\s*(get|post|put|delete|patch)(?:<[^\(]*>)?\s*\(\s*ApiConstants\.buildApiPath\(\s*['\"]([^'\"]*\$[^'\"]*)['\"]\s*\)", re.IGNORECASE | re.MULTILINE | re.DOTALL)
print(pattern.findall(text))
