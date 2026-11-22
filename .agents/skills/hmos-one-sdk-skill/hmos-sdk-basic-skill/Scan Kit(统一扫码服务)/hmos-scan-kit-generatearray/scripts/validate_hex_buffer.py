#!/usr/bin/env python3
"""
通过字节数组生成码图辅助脚本

功能：
1. 验证十六进制字符串格式
2. 计算字节数组长度
3. 推荐合适的纠错级别
4. 生成测试数据示例

使用方法：
python validate_hex_buffer.py --hex "0177C10DD10F..." --width 400 --height 400
"""

import argparse
import sys
import re
from typing import Tuple, Optional

class HexBufferValidator:
    """十六进制字节数组验证器"""
    
    # 纠错级别对应的字节数组长度限制
    ERROR_LEVEL_LIMITS = {
        'LEVEL_L': 2048,
        'LEVEL_M': 2048,
        'LEVEL_Q': 1536,
        'LEVEL_H': 1024
    }
    
    # 码图尺寸范围
    WIDTH_HEIGHT_RANGE = (200, 4096)
    
    def validate_hex_string(self, hex_string: str) -> Tuple[bool, str]:
        """验证十六进制字符串格式"""
        if not hex_string or len(hex_string) == 0:
            return False, "Empty hex string"
        
        hex_pattern = re.compile(r'^[0-9A-Fa-f]+$')
        if not hex_pattern.match(hex_string):
            return False, "Invalid hex format. Only 0-9, A-F, a-f allowed."
        
        if len(hex_string) % 2 != 0:
            return False, "Hex string length must be even (each byte = 2 hex chars)"
        
        return True, "Valid hex string"
    
    def calculate_buffer_size(self, hex_string: str) -> int:
        """计算字节数组长度"""
        return len(hex_string) // 2
    
    def recommend_error_level(self, buffer_size: int) -> str:
        """根据字节数组长度推荐纠错级别"""
        if buffer_size <= 1024:
            return 'LEVEL_H'
        elif buffer_size <= 1536:
            return 'LEVEL_Q'
        elif buffer_size <= 2048:
            return 'LEVEL_M'
        else:
            return 'EXCEED_LIMIT'
    
    def validate_dimensions(self, width: int, height: int) -> Tuple[bool, str]:
        """验证码图尺寸"""
        min_size, max_size = self.WIDTH_HEIGHT_RANGE
        
        if width < min_size or width > max_size:
            return False, f"Width {width} out of range [{min_size}, {max_size}]"
        
        if height < min_size or height > max_size:
            return False, f"Height {height} out of range [{min_size}, {max_size}]"
        
        return True, "Valid dimensions"
    
    def generate_validation_report(self, hex_string: str, width: int, height: int) -> dict:
        """生成验证报告"""
        report = {
            'hex_validation': self.validate_hex_string(hex_string),
            'buffer_size': self.calculate_buffer_size(hex_string),
            'recommended_level': None,
            'dimensions_validation': self.validate_dimensions(width, height),
            'can_generate': False,
            'warnings': [],
            'suggestions': []
        }
        
        if report['hex_validation'][0]:
            buffer_size = report['buffer_size']
            recommended_level = self.recommend_error_level(buffer_size)
            
            if recommended_level == 'EXCEED_LIMIT':
                report['warnings'].append(f"Buffer size {buffer_size} exceeds max limit 2048 bytes")
                report['suggestions'].append("Reduce content size or split into multiple QR codes")
            else:
                report['recommended_level'] = recommended_level
                report['can_generate'] = True
                
                if buffer_size > 1024:
                    report['suggestions'].append(f"Buffer size {buffer_size}. Recommended error level: {recommended_level}")
        
        if report['dimensions_validation'][0]:
            if width != height:
                report['suggestions'].append("Suggest width = height for QR code generation")
        else:
            report['can_generate'] = False
        
        return report
    
    def print_report(self, report: dict):
        """打印验证报告"""
        print("\n" + "="*60)
        print("HEX BUFFER VALIDATION REPORT")
        print("="*60)
        
        print(f"\nHex String Validation: {report['hex_validation'][1]}")
        if report['hex_validation'][0]:
            print(f"Buffer Size: {report['buffer_size']} bytes")
            print(f"Recommended Error Level: {report['recommended_level'] or 'N/A'}")
        
        print(f"\nDimensions Validation: {report['dimensions_validation'][1]}")
        
        print(f"\nCan Generate QR Code: {report['can_generate']}")
        
        if report['warnings']:
            print("\nWarnings:")
            for warning in report['warnings']:
                print(f"  - {warning}")
        
        if report['suggestions']:
            print("\nSuggestions:")
            for suggestion in report['suggestions']:
                print(f"  - {suggestion}")
        
        print("\n" + "="*60)

def generate_sample_hex_data():
    """生成示例十六进制数据"""
    samples = {
        'small': '48656C6C6F20576F726C64',  # "Hello World"
        'medium': '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da',
        'traffic_card': '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da'
    }
    return samples

def main():
    parser = argparse.ArgumentParser(
        description='Validate hex buffer for QR code generation',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python validate_hex_buffer.py --hex "48656C6C6F" --width 400 --height 400
  python validate_hex_buffer.py --sample traffic_card
  python validate_hex_buffer.py --generate-samples
"""
    )
    
    parser.add_argument('--hex', type=str, help='Hex string to validate')
    parser.add_argument('--width', type=int, default=400, help='QR code width (200-4096)')
    parser.add_argument('--height', type=int, default=400, help='QR code height (200-4096)')
    parser.add_argument('--sample', type=str, choices=['small', 'medium', 'traffic_card'], 
                       help='Use sample hex data')
    parser.add_argument('--generate-samples', action='store_true', 
                       help='Generate and display sample hex data')
    
    args = parser.parse_args()
    
    validator = HexBufferValidator()
    
    if args.generate_samples:
        samples = generate_sample_hex_data()
        print("\nSample Hex Data:")
        for name, data in samples.items():
            size = len(data) // 2
            level = validator.recommend_error_level(size)
            print(f"\n{name}:")
            print(f"  Hex: {data}")
            print(f"  Size: {size} bytes")
            print(f"  Recommended Level: {level}")
        sys.exit(0)
    
    hex_string = args.hex
    if args.sample:
        samples = generate_sample_hex_data()
        hex_string = samples[args.sample]
    
    if not hex_string:
        parser.print_help()
        sys.exit(1)
    
    report = validator.generate_validation_report(hex_string, args.width, args.height)
    validator.print_report(report)
    
    if report['can_generate']:
        print("\n✓ Ready to generate QR code")
        print(f"  Use level: {report['recommended_level']}")
        print(f"  Dimensions: {args.width}x{args.height}")
        sys.exit(0)
    else:
        print("\n✗ Cannot generate QR code")
        print("  Please fix the issues above")
        sys.exit(1)

if __name__ == '__main__':
    main()