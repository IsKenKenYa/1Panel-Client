import re
import sys

def process_markdown_links(input_file, output_file):
    """
    Process markdown file and convert local file links to online URLs.
    
    Rules:
    - harmonyos-guides links: convert to https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}
    - harmonyos-references links: convert to https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}
    - Remove .md suffix from filenames
    """
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Process harmonyos-guides links
        pattern_guides = r'D:/code/APIDevice/output/md_output/harmonyos-guides/(.*?)\.md'
        content = re.sub(pattern_guides, 
                        r'https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/\1', 
                        content)
        
        # Process harmonyos-references links
        pattern_references = r'D:/code/APIDevice/output/md_output/harmonyos-references/(.*?)\.md'
        content = re.sub(pattern_references, 
                        r'https://developer.huawei.com/consumer/cn/doc/harmonyos-references/\1', 
                        content)
        
        # Write processed content
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Successfully processed {input_file}")
        print(f"Output saved to {output_file}")
        
    except Exception as e:
        print(f"Error processing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python process_links.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    process_markdown_links(input_file, output_file)