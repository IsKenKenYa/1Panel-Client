import re
import os

def convert_md_links(content, base_dir):
    """
    转换markdown文件中的链接格式
    - harmonyos-guides路径转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}
    - harmonyos-references路径转换为: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}
    - 去掉.md后缀
    """
    
    pattern = r'\[([^\]]+)\]\(([^\)]+\.md)\)'
    
    def replace_link(match):
        text = match.group(1)
        path = match.group(2)
        
        # 提取文件名（去掉.md后缀）
        filename = os.path.basename(path).replace('.md', '')
        
        # 根据路径判断URL前缀
        if 'harmonyos-guides' in path:
            new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}"
        elif 'harmonyos-references' in path:
            new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}"
        else:
            # 如果不是这两个路径，保持原样
            new_url = path
        
        return f'[{text}]({new_url})'
    
    # 替换所有匹配的链接
    converted_content = re.sub(pattern, replace_link, content)
    
    return converted_content

def process_file(file_path):
    """处理单个文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 转换链接
    converted_content = convert_md_links(content, os.path.dirname(file_path))
    
    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(converted_content)
    
    print(f"Processed: {file_path}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        process_file(file_path)
    else:
        print("Usage: python convert_links.py <file_path>")