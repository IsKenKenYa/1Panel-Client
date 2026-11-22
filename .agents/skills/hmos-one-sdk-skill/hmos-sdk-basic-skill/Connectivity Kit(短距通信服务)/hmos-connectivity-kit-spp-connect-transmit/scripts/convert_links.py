import re
import os

def convert_md_links(content, source_type):
    """
    转换MD文件中的链接格式
    
    Args:
        content: MD文件内容
        source_type: 'harmonyos-guides' 或 'harmonyos-references'
    
    Returns:
        转换后的内容
    """
    
    # 定义正则表达式匹配Markdown链接
    # 格式: [标题](路径)
    pattern = r'\[([^\]]+)\]\(([^\)]+\.md)\)'
    
    def replace_link(match):
        title = match.group(1)
        filepath = match.group(2)
        
        # 提取文件名(去掉路径和.md后缀)
        filename = os.path.basename(filepath)
        if filename.endswith('.md'):
            filename = filename[:-3]  # 去掉.md后缀
        
        # 根据source_type构建新URL
        # 首先判断链接指向的是guides还是references
        if 'harmonyos-guides' in filepath:
            new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}"
        elif 'harmonyos-references' in filepath:
            new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}"
        else:
            # 如果路径中没有明确的guides/references标识,根据source_type判断
            if source_type == 'harmonyos-guides':
                new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}"
            elif source_type == 'harmonyos-references':
                new_url = f"https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}"
            else:
                # 保持原样
                new_url = filepath
        
        return f"[{title}]({new_url})"
    
    # 执行替换
    converted_content = re.sub(pattern, replace_link, content)
    
    return converted_content

def process_file(filepath, source_type):
    """
    处理单个文件
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        converted_content = convert_md_links(content, source_type)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(converted_content)
        
        print(f"已处理文件: {filepath}")
        return True
    except Exception as e:
        print(f"处理文件失败: {filepath}, 错误: {str(e)}")
        return False

def main():
    references_dir = r"D:\code\APIDevice\output\skill\系统\网络\Connectivity Kit（短距通信服务）\蓝牙\传统蓝牙\连接和传输数据\hmos-connectivity-kit-spp-connect-transmit\references"
    
    # 处理spp-development-guide.md (来自harmonyos-guides)
    guide_file = os.path.join(references_dir, "spp-development-guide.md")
    if os.path.exists(guide_file):
        process_file(guide_file, 'harmonyos-guides')
    
    # 处理js-apis-bluetooth-socket.md (来自harmonyos-references)
    api_file = os.path.join(references_dir, "js-apis-bluetooth-socket.md")
    if os.path.exists(api_file):
        process_file(api_file, 'harmonyos-references')
    
    print("\n链接转换完成!")

if __name__ == "__main__":
    main()