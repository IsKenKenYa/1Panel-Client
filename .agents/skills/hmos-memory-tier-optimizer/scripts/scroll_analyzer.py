#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HarmonyOS Scroll Component Memory Optimizer Analyzer

分析鸿蒙 ArkTS 代码中的滚动组件（List/Grid/WaterFlow）的 cacheCount 设置，
检测内存优化空间并生成优化建议。

Usage:
    python scroll_analyzer.py <path> [options]

Arguments:
    path                    要分析的文件或目录路径

Options:
    --output, -o <file>     输出报告文件路径（JSON格式）
    --verbose, -v           输出详细信息
    --help, -h              显示帮助信息

Examples:
    # 分析单个文件
    python scroll_analyzer.py ./NoteListComp.ets

    # 分析整个项目
    python scroll_analyzer.py ./src --output ./report.json

    # 详细输出
    python scroll_analyzer.py ./src -v
"""

import re
import os
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Dict, Optional, Tuple
from enum import Enum


class ComponentType(Enum):
    """滚动组件类型"""
    LIST = "List"
    GRID = "Grid"
    WATERFLOW = "WaterFlow"


class IssueSeverity(Enum):
    """问题严重程度"""
    HIGH = "high"       # 必须优化
    MEDIUM = "medium"   # 建议优化
    LOW = "low"         # 可选优化
    INFO = "info"       # 信息提示


@dataclass
class ScrollComponent:
    """滚动组件信息"""
    component_type: str
    line_number: int
    column_number: int
    code_snippet: str
    cache_count: Optional[int] = None
    has_cache_count: bool = False


@dataclass
class OptimizationIssue:
    """优化问题"""
    severity: str
    component_type: str
    line_number: int
    message: str
    suggestion: str
    current_value: Optional[int] = None
    recommended_value: Optional[str] = None
    code_snippet: str = ""


@dataclass
class FileReport:
    """单个文件的报告"""
    file_path: str
    components_found: int
    components: List[Dict]
    issues: List[Dict]
    needs_optimization: bool


@dataclass
class AnalysisReport:
    """完整分析报告"""
    total_files: int
    total_components: int
    files_with_issues: int
    high_severity_issues: int
    medium_severity_issues: int
    low_severity_issues: int
    files: List[Dict]
    summary: str


class ScrollComponentAnalyzer:
    """滚动组件分析器"""

    # 匹配滚动组件的正则表达式
    # 使用 \b 单词边界确保匹配独立组件名，避免误匹配函数名如 updateList()
    # 支持带参数的组件声明，如 List({ initialIndex: 0 }) {
    COMPONENT_PATTERNS = {
        ComponentType.LIST: re.compile(
            r'\bList\s*\([^)]*\)\s*\{', re.MULTILINE | re.DOTALL
        ),
        ComponentType.GRID: re.compile(
            r'\bGrid\s*\([^)]*\)\s*\{', re.MULTILINE | re.DOTALL
        ),
        ComponentType.WATERFLOW: re.compile(
            r'\bWaterFlow\s*\([^)]*\)\s*\{', re.MULTILINE | re.DOTALL
        ),
    }

    # 匹配 cacheCount 设置
    CACHE_COUNT_PATTERN = re.compile(
        r'\.cacheCount\s*\(\s*(\d+)\s*\)', re.IGNORECASE
    )

    # 匹配 LazyForEach（用于评估 item 复杂度）
    LAZY_FOR_EACH_PATTERN = re.compile(
        r'LazyForEach\s*\(\s*([^,]+)', re.MULTILINE | re.DOTALL
    )

    # 复杂 Item 的特征（用于评估 item 复杂度）
    COMPLEX_ITEM_INDICATORS = [
        r'Image\s*\(',           # 图片
        r'Web\s*\(',             # Web组件
        r'WebView',              # WebView
        r'RichText',             # 富文本
        r'Video\s*\(',           # 视频
        r'Canvas\s*\(',          # 画布
        r'LazyForEach',          # 懒加载（本身说明数据量大）
    ]

    def __init__(self):
        self.verbose = False

    def log(self, message: str):
        """打印日志"""
        if self.verbose:
            print(f"[INFO] {message}")

    def find_component_block(self, content: str, start_pos: int) -> Tuple[str, int, int]:
        """
        找到组件的完整代码块
        返回: (代码块, 结束位置, 行号)
        """
        brace_count = 0
        in_string = False
        string_char = None
        i = start_pos
        
        # 计算行号
        line_number = content[:start_pos].count('\n') + 1
        
        while i < len(content):
            char = content[i]
            
            # 处理字符串
            if char in ['"', "'", '`'] and (i == 0 or content[i-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif string_char == char:
                    in_string = False
                    string_char = None
            
            # 处理花括号
            elif not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        block = content[start_pos:i+1]
                        return block, i, line_number
            
            i += 1
        
        return content[start_pos:], i, line_number

    def analyze_file(self, file_path: str) -> FileReport:
        """分析单个文件"""
        self.log(f"Analyzing: {file_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return FileReport(
                file_path=file_path,
                components_found=0,
                components=[],
                issues=[{
                    "severity": "error",
                    "message": f"Failed to read file: {str(e)}"
                }],
                needs_optimization=False
            )

        components: List[ScrollComponent] = []
        issues: List[OptimizationIssue] = []

        # 查找所有滚动组件
        for comp_type, pattern in self.COMPONENT_PATTERNS.items():
            for match in pattern.finditer(content):
                start_pos = match.start()
                
                # 获取组件代码块
                block, end_pos, line_number = self.find_component_block(content, start_pos)
                
                # 提取代码片段（前200字符用于展示）
                snippet = block[:200].replace('\n', ' ').strip()
                if len(block) > 200:
                    snippet += " ..."
                
                # 检查是否有 cacheCount 设置
                cache_match = self.CACHE_COUNT_PATTERN.search(block)
                has_cache_count = cache_match is not None
                cache_value = int(cache_match.group(1)) if cache_match else None
                
                component = ScrollComponent(
                    component_type=comp_type.value,
                    line_number=line_number,
                    column_number=start_pos - content.rfind('\n', 0, start_pos),
                    code_snippet=snippet,
                    cache_count=cache_value,
                    has_cache_count=has_cache_count
                )
                components.append(component)
                
                # 分析问题
                file_issues = self._analyze_component_issues(component, block)
                issues.extend(file_issues)

        # 转换为字典
        component_dicts = [asdict(c) for c in components]
        issue_dicts = [asdict(i) for i in issues]

        return FileReport(
            file_path=file_path,
            components_found=len(components),
            components=component_dicts,
            issues=issue_dicts,
            needs_optimization=len([i for i in issues if i.severity in ['high', 'medium']]) > 0
        )

    def _analyze_component_issues(self, component: ScrollComponent, block: str) -> List[OptimizationIssue]:
        """分析组件的优化问题"""
        issues = []
        
        # 1. 检查是否设置了 cacheCount
        if not component.has_cache_count:
            issues.append(OptimizationIssue(
                severity=IssueSeverity.MEDIUM.value,
                component_type=component.component_type,
                line_number=component.line_number,
                message=f"{component.component_type} 组件未设置 cacheCount 属性",
                suggestion="建议添加 cacheCount 属性，并根据设备内存动态设置推荐值",
                current_value=None,
                recommended_value="动态计算：低内存=0-1, 中内存=1-2, 高内存=2-3",
                code_snippet=component.code_snippet
            ))
        else:
            # 2. 检查 cacheCount 值是否过大
            cache_value = component.cache_count
            
            if cache_value > 5:
                issues.append(OptimizationIssue(
                    severity=IssueSeverity.HIGH.value,
                    component_type=component.component_type,
                    line_number=component.line_number,
                    message=f"{component.component_type} 组件的 cacheCount ({cache_value}) 过大，可能导致内存占用过高",
                    suggestion="cacheCount 最大值建议不超过 5，请根据设备内存调整",
                    current_value=cache_value,
                    recommended_value="5 或更低",
                    code_snippet=component.code_snippet
                ))
            elif cache_value >= 3:
                issues.append(OptimizationIssue(
                    severity=IssueSeverity.MEDIUM.value,
                    component_type=component.component_type,
                    line_number=component.line_number,
                    message=f"{component.component_type} 组件的 cacheCount ({cache_value}) 较大，建议优化",
                    suggestion="建议根据设备内存等级动态调整，复杂 Item 可适当降低",
                    current_value=cache_value,
                    recommended_value="低内存=0-1, 中内存=1-2, 高内存=2-3",
                    code_snippet=component.code_snippet
                ))
            
            # 3. 检查是否是静态硬编码
            if not self._has_dynamic_cache_count(block):
                issues.append(OptimizationIssue(
                    severity=IssueSeverity.MEDIUM.value,
                    component_type=component.component_type,
                    line_number=component.line_number,
                    message=f"{component.component_type} 组件使用静态硬编码 cacheCount ({cache_value})",
                    suggestion="建议使用 MemoryOptimizer 工具类根据设备内存动态设置 cacheCount",
                    current_value=cache_value,
                    recommended_value="动态计算值",
                    code_snippet=component.code_snippet
                ))
        
        # 4. 评估 Item 复杂度
        complexity = self._assess_item_complexity(block)
        if complexity == "complex" and (not component.has_cache_count or (component.cache_count and component.cache_count > 2)):
            issues.append(OptimizationIssue(
                severity=IssueSeverity.LOW.value,
                component_type=component.component_type,
                line_number=component.line_number,
                message=f"{component.component_type} 组件包含复杂 Item 布局，当前 cacheCount 可能过高",
                suggestion="复杂 Item（含图片、嵌套组件）建议降低 cacheCount 以减少内存占用",
                current_value=component.cache_count,
                recommended_value="复杂 Item 推荐：低内存=0, 中内存=0-1, 高内存=1-2",
                code_snippet=component.code_snippet
            ))
        
        return issues

    def _has_dynamic_cache_count(self, block: str) -> bool:
        """检查是否使用了动态 cacheCount 设置"""
        # 检查是否使用了变量或函数调用
        dynamic_patterns = [
            r'\.cacheCount\s*\(\s*this\.',      # this.xxx
            r'\.cacheCount\s*\(\s*MemoryOptimizer',  # MemoryOptimizer
            r'\.cacheCount\s*\(\s*\w+\s*\)',    # 变量
            r'\.cacheCount\s*\(\s*getRecommended',  # 函数调用
        ]
        
        for pattern in dynamic_patterns:
            if re.search(pattern, block):
                return True
        return False

    def _assess_item_complexity(self, block: str) -> str:
        """评估 Item 复杂度"""
        complexity_score = 0
        
        for indicator in self.COMPLEX_ITEM_INDICATORS:
            if re.search(indicator, block):
                complexity_score += 1
        
        # 根据嵌套层级判断
        nested_levels = block.count('{') - block.count('}')
        if nested_levels > 10:
            complexity_score += 2
        
        if complexity_score >= 3:
            return "complex"
        elif complexity_score >= 1:
            return "medium"
        return "simple"

    def analyze_project(self, project_path: str) -> AnalysisReport:
        """分析整个项目"""
        self.log(f"Scanning project: {project_path}")
        
        # 收集所有 .ets 文件
        ets_files = []
        path = Path(project_path)
        
        if path.is_file():
            if path.suffix == '.ets':
                ets_files.append(path)
        else:
            ets_files = list(path.rglob('*.ets'))
        
        self.log(f"Found {len(ets_files)} .ets files")
        
        # 分析每个文件
        file_reports = []
        total_components = 0
        files_with_issues = 0
        high_count = 0
        medium_count = 0
        low_count = 0
        
        for file_path in ets_files:
            report = self.analyze_file(str(file_path))
            file_reports.append(asdict(report))
            
            total_components += report.components_found
            if report.needs_optimization:
                files_with_issues += 1
            
            for issue in report.issues:
                if isinstance(issue, dict):
                    severity = issue.get('severity', '')
                else:
                    severity = issue.severity
                
                if severity == 'high':
                    high_count += 1
                elif severity == 'medium':
                    medium_count += 1
                elif severity == 'low':
                    low_count += 1
        
        # 生成总结
        summary = self._generate_summary(
            len(ets_files), total_components, files_with_issues,
            high_count, medium_count, low_count
        )
        
        return AnalysisReport(
            total_files=len(ets_files),
            total_components=total_components,
            files_with_issues=files_with_issues,
            high_severity_issues=high_count,
            medium_severity_issues=medium_count,
            low_severity_issues=low_count,
            files=file_reports,
            summary=summary
        )

    def _generate_summary(self, total_files: int, total_components: int,
                          files_with_issues: int, high: int, medium: int, low: int) -> str:
        """生成报告总结"""
        lines = [
            f"分析了 {total_files} 个文件，发现 {total_components} 个滚动组件",
            f"其中 {files_with_issues} 个文件存在优化空间",
            f"问题分布: 严重 {high} 个, 中等 {medium} 个, 轻微 {low} 个",
        ]
        
        if high > 0:
            lines.append("建议优先处理严重级别的问题，以避免内存占用过高导致 OOM")
        elif medium > 0:
            lines.append("建议处理中等级别的问题，以提升应用内存效率")
        elif low > 0:
            lines.append("应用整体内存优化良好，可考虑进一步优化轻微问题")
        else:
            lines.append("未发现明显内存优化问题，代码质量良好")
        
        return "; ".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='HarmonyOS Scroll Component Memory Optimizer Analyzer',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # 分析单个文件
    python scroll_analyzer.py ./NoteListComp.ets

    # 分析整个项目
    python scroll_analyzer.py ./src --output ./report.json

    # 详细输出
    python scroll_analyzer.py ./src -v
        """
    )
    
    parser.add_argument('path', help='要分析的文件或目录路径')
    parser.add_argument('-o', '--output', help='输出报告文件路径（JSON格式）')
    parser.add_argument('-v', '--verbose', action='store_true', help='输出详细信息')
    
    args = parser.parse_args()
    
    # 检查路径是否存在
    if not os.path.exists(args.path):
        print(f"Error: Path does not exist: {args.path}")
        sys.exit(1)
    
    # 创建分析器
    analyzer = ScrollComponentAnalyzer()
    analyzer.verbose = args.verbose
    
    # 执行分析
    report = analyzer.analyze_project(args.path)
    
    # 转换为 JSON
    report_dict = asdict(report)
    json_output = json.dumps(report_dict, indent=2, ensure_ascii=False)
    
    # 输出结果
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(json_output)
        print(f"Report saved to: {args.output}")
    else:
        print(json_output)


if __name__ == '__main__':
    main()
