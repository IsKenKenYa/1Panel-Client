import re

with open('macos/Runner.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

content = re.sub(r'CODE_SIGN_IDENTITY = "Apple Development";', 'CODE_SIGN_IDENTITY = "-";', content)
content = re.sub(r'CODE_SIGN_STYLE = Automatic;', 'CODE_SIGN_STYLE = Manual;', content)

with open('macos/Runner.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
