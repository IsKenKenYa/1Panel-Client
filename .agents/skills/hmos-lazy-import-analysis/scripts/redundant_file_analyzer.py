#!/usr/bin/env python3
"""
Redundant File Analyzer
解析鸿蒙应用的 redundant_file.txt，生成 Excel 报表。

用法:
  python3 redundant_file_analyzer.py <app_name>           # 拉取模式: 本地无 txt 时自动发现 hdc 并从设备拉取后分析
  python3 redundant_file_analyzer.py --file <文件路径>     # 直接分析指定的本地文件

文件结构:
  第1行: <----Summary----> 总体统计
  第2行起: <----used file start----> ... <----------used file end---------->
  接着:  <----unused file start----> ... <----------unused file end---------->
"""

import re
import sys
import os
import shutil
import glob as _glob
import subprocess

try:
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
except ImportError:
    print("缺少 openpyxl 库，正在安装...")
    os.system(f"{sys.executable} -m pip install openpyxl")
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side


def find_hdc():
    """定位 hdc 可执行文件: PATH 优先, 其次常见 DevEco/OpenHarmony SDK 安装位置。"""
    hdc = shutil.which('hdc')
    if hdc:
        return hdc
    home = os.path.expanduser('~')
    pats = []
    if sys.platform == 'darwin':
        pats += [
            '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc',
            os.path.join(home, 'Library/OpenHarmony/Sdk/*/toolchains/hdc'),
            os.path.join(home, 'Library/Huawei/Sdk/*/openharmony/toolchains/hdc'),
        ]
    elif sys.platform == 'win32':
        sdk = os.environ.get('DEVECO_SDK_HOME', '')
        if sdk:
            pats.append(os.path.join(sdk, 'default/openharmony/toolchains/hdc.exe'))
        pats += [
            os.path.join(home, 'AppData/Local/OpenHarmony/Sdk/*/toolchains/hdc.exe'),
            os.path.join(home, 'AppData/Local/Huawei/Sdk/*/openharmony/toolchains/hdc.exe'),
            'C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe',
        ]
    else:  # linux
        pats += [
            os.path.join(home, 'harmonyos/sdk/default/openharmony/toolchains/hdc'),
            os.path.join(home, 'Huawei/Sdk/*/openharmony/toolchains/hdc'),
            '/opt/harmonyos-sdk/default/openharmony/toolchains/hdc',
        ]
    for pat in pats:
        for p in sorted(_glob.glob(pat)):
            if os.path.isfile(p):
                return p
    return None


def pull_redundant_file(app_name, out_dir='.'):
    """从设备拉取 {app_name}_redundant_file.txt 到 out_dir。返回 (本地路径|None, 错误信息|None)。"""
    remote = f'/data/app/el2/100/base/{app_name}/files/{app_name}_redundant_file.txt'
    hdc = find_hdc()
    if not hdc:
        return None, '未找到 hdc (不在 PATH 且未扫描到常见 SDK 位置)'
    try:
        r = subprocess.run([hdc, 'file', 'recv', remote, out_dir],
                           capture_output=True, text=True, timeout=120)
    except Exception as e:
        return None, f'hdc 执行异常: {e}'
    if r.returncode != 0:
        detail = (r.stderr or r.stdout or '').strip()
        return None, f'hdc 返回 {r.returncode}: {detail[:200]}'
    local = os.path.join(out_dir, f'{app_name}_redundant_file.txt')
    if not os.path.isfile(local):
        detail = (r.stdout or r.stderr or '').strip().replace('\n', ' ')
        return None, f'hdc 未生成文件 (设备上可能不存在该路径): {detail[-160:]}' if detail \
            else 'hdc 未生成文件 (设备上可能不存在该路径)'
    return local, None


def parse_summary(line):
    """解析 Summary 行，提取各项统计数据（仅耗时维度）。"""
    data = {}

    # Total file number: 2330, total time: 1707ms
    m = re.search(r'Total file number:\s*(\d+)', line)
    data['total_file_number'] = int(m.group(1)) if m else 0

    m = re.search(r'total time:\s*([\d.e+]+)ms', line)
    data['total_time_ms'] = float(m.group(1)) if m else 0.0

    # including used file:437, cost time: 203ms, ...
    m = re.search(r'including used file:\s*(\d+)', line)
    data['used_file_count'] = int(m.group(1)) if m else 0

    m = re.search(r'including used file:.*?cost time:\s*([\d.e+]+)ms', line)
    data['used_cost_time_ms'] = float(m.group(1)) if m else 0.0

    # and unused file: 1893, cost time: 1503ms, ...
    m = re.search(r'and unused file:\s*(\d+)', line)
    data['unused_file_count'] = int(m.group(1)) if m else 0

    m = re.search(r'and unused file:.*?cost time:\s*([\d.e+]+)ms', line)
    data['unused_cost_time_ms'] = float(m.group(1)) if m else 0.0

    return data


def parse_section_header(line, section_type):
    """解析 used/unused 区块头行（仅耗时维度）。

    例如: <----used file start----> used file: 437, cost time: 203ms, heap size: 12081144B, shared heap size: 1163256B rss Size:280944KB
    """
    data = {}
    m = re.search(rf'{section_type} file:\s*(\d+)', line)
    data[f'{section_type}_file_count'] = int(m.group(1)) if m else 0

    m = re.search(rf'{section_type} file:.*?cost time:\s*([\d.e+]+)ms', line)
    data[f'{section_type}_cost_time_ms'] = float(m.group(1)) if m else 0.0

    return data


def parse_file_entry(line, section_type):
    """解析单个 used/unused file 行（仅耗时维度）。

    例如: used file 1: @normalized:Y&&&libpb_log.so&, cost time: 59.6ms, heap size: 5243848B, shared heap size: 417792B rss Size:13144KB
    例如: used file 22: &modulename/src/main/ets/startup/FooEntry&, cost time: 1.14ms, heap size: 1024B, shared heap size: 0B rss Size:200KB
    """
    pattern = rf'{section_type} file\s+(\d+):\s*(.+?),\s*cost time:\s*([\d.e+]+)ms'
    m = re.match(pattern, line.strip())
    if not m:
        return None

    return {
        'id': int(m.group(1)),
        'file_path': m.group(2).strip(),
        'cost_time_ms': float(m.group(3)),
        'parent_modules': []
    }


def parse_parent_module(line):
    """解析 parentModule 行。

    例如:           parentModule 1: &login_launcher/src/main/ets/Launcher/chain/interceptors/AlreadyLoginInterceptor&1.0.0 LoginSourcePackage_Source
    """
    m = re.match(r'\s*parentModule\s+(\d+):\s*(.+)', line)
    if not m:
        return None
    return {
        'index': int(m.group(1)),
        'info': m.group(2).strip()
    }


def parse_redundant_file(filepath):
    """解析整个 redundant_file.txt 文件。"""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    result = {
        'summary': {},
        'used_header': {},
        'unused_header': {},
        'used_files': [],
        'unused_files': []
    }

    current_section = None  # 'used' or 'unused'
    current_file = None

    for line in lines:
        line = line.rstrip('\r\n')

        # Summary
        if line.startswith('<----Summary---->'):
            result['summary'] = parse_summary(line)
            continue

        # Section headers
        if '<----used file start---->' in line:
            result['used_header'] = parse_section_header(line, 'used')
            current_section = 'used'
            continue

        if '<----unused file start---->' in line:
            result['unused_header'] = parse_section_header(line, 'unused')
            current_section = 'unused'
            continue

        # Section ends
        if '<----------used file end---------->' in line or \
           '<----------unused file end---------->' in line:
            # 保存当前 file
            if current_file:
                if current_section == 'used':
                    result['used_files'].append(current_file)
                else:
                    result['unused_files'].append(current_file)
                current_file = None
            current_section = None
            continue

        # File entries
        if current_section:
            # 尝试匹配 file entry
            entry = parse_file_entry(line, current_section)
            if entry:
                # 保存之前的 file
                if current_file:
                    if current_section == 'used':
                        result['used_files'].append(current_file)
                    else:
                        result['unused_files'].append(current_file)
                current_file = entry
                continue

            # 尝试匹配 parentModule
            pm = parse_parent_module(line)
            if pm and current_file:
                current_file['parent_modules'].append(pm['info'])
                continue

    return result


def write_excel(data, output_path):
    """将解析结果写入 Excel 文件。"""
    wb = openpyxl.Workbook()

    # 样式
    header_font = Font(bold=True, size=11)
    header_fill = PatternFill(start_color='4472C4', end_color='4472C4', fill_type='solid')
    header_font_white = Font(bold=True, size=11, color='FFFFFF')
    border = Border(
        left=Side(style='thin'),
        right=Side(style='thin'),
        top=Side(style='thin'),
        bottom=Side(style='thin')
    )

    # ===== Sheet 1: Summary =====
    ws_summary = wb.active
    ws_summary.title = 'Summary'

    summary = data['summary']
    used_header = data['used_header']
    unused_header = data['unused_header']

    summary_rows = [
        ['指标', '数值'],
        ['总文件数', summary.get('total_file_number', 0)],
        ['总加载时间 (ms)', summary.get('total_time_ms', 0)],
        ['', ''],
        ['--- Used Files ---', ''],
        ['Used 文件数', summary.get('used_file_count', 0)],
        ['Used 加载时间 (ms)', summary.get('used_cost_time_ms', 0)],
        ['', ''],
        ['--- Unused Files ---', ''],
        ['Unused 文件数', summary.get('unused_file_count', 0)],
        ['Unused 加载时间 (ms)', summary.get('unused_cost_time_ms', 0)],
        ['', ''],
        ['--- 分析 ---', ''],
        ['Unused 占比 (文件数)', f"{summary.get('unused_file_count', 0) / max(summary.get('total_file_number', 1), 1) * 100:.1f}%"],
        ['Unused 占比 (加载时间)', f"{summary.get('unused_cost_time_ms', 0) / max(summary.get('total_time_ms', 1), 1) * 100:.1f}%"],
    ]

    for row_idx, row_data in enumerate(summary_rows, 1):
        for col_idx, value in enumerate(row_data, 1):
            cell = ws_summary.cell(row=row_idx, column=col_idx, value=value)
            cell.border = border
            if row_idx == 1:
                cell.font = header_font_white
                cell.fill = header_fill
            elif row_data[0].startswith('---'):
                cell.font = header_font

    ws_summary.column_dimensions['A'].width = 30
    ws_summary.column_dimensions['B'].width = 20

    # ===== Sheet 2: Used Files =====
    ws_used = wb.create_sheet('Used Files')
    used_headers = ['ID', 'File Path', 'Cost Time (ms)', 'Parent Modules']

    for col_idx, header in enumerate(used_headers, 1):
        cell = ws_used.cell(row=1, column=col_idx, value=header)
        cell.font = header_font_white
        cell.fill = header_fill
        cell.border = border
        cell.alignment = Alignment(horizontal='center')

    for row_idx, f in enumerate(data['used_files'], 2):
        parents = '\n'.join(f['parent_modules']) if f['parent_modules'] else ''
        row = [
            f['id'],
            f['file_path'],
            f['cost_time_ms'],
            parents
        ]
        for col_idx, value in enumerate(row, 1):
            cell = ws_used.cell(row=row_idx, column=col_idx, value=value)
            cell.border = border
            if col_idx == 4:
                cell.alignment = Alignment(wrap_text=True)

    ws_used.column_dimensions['A'].width = 6
    ws_used.column_dimensions['B'].width = 60
    ws_used.column_dimensions['C'].width = 15
    ws_used.column_dimensions['D'].width = 80

    # 冻结首行
    ws_used.freeze_panes = 'A2'

    # ===== Sheet 3: Unused Files =====
    ws_unused = wb.create_sheet('Unused Files')

    for col_idx, header in enumerate(used_headers, 1):
        cell = ws_unused.cell(row=1, column=col_idx, value=header)
        cell.font = header_font_white
        cell.fill = header_fill
        cell.border = border
        cell.alignment = Alignment(horizontal='center')

    for row_idx, f in enumerate(data['unused_files'], 2):
        parents = '\n'.join(f['parent_modules']) if f['parent_modules'] else ''
        row = [
            f['id'],
            f['file_path'],
            f['cost_time_ms'],
            parents
        ]
        for col_idx, value in enumerate(row, 1):
            cell = ws_unused.cell(row=row_idx, column=col_idx, value=value)
            cell.border = border
            if col_idx == 4:
                cell.alignment = Alignment(wrap_text=True)

    ws_unused.column_dimensions['A'].width = 6
    ws_unused.column_dimensions['B'].width = 60
    ws_unused.column_dimensions['C'].width = 15
    ws_unused.column_dimensions['D'].width = 80

    ws_unused.freeze_panes = 'A2'

    wb.save(output_path)
    print(f'Excel 报表已生成: {output_path}')


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='解析鸿蒙应用 redundant_file.txt，生成 Excel 报表'
    )
    parser.add_argument(
        'app_name', nargs='?', default=None,
        help='应用包名，脚本在当前目录查找 {app_name}_redundant_file.txt'
    )
    parser.add_argument(
        '--file', '-f', dest='file_path', default=None,
        help='直接指定本地 redundant file 文件路径进行分析'
    )
    args = parser.parse_args()

    if args.file_path:
        # 本地文件模式
        input_file = args.file_path
        if not os.path.exists(input_file):
            print(f'错误: 文件不存在: {input_file}')
            sys.exit(1)
        # 输出到输入文件同目录，文件名加 _report 后缀
        base = os.path.splitext(os.path.basename(input_file))[0]
        output_file = os.path.join(os.path.dirname(os.path.abspath(input_file)), f'{base}_report.xlsx')
    elif args.app_name:
        # app_name 模式（通常配合 hdc 拉取）
        app_name = args.app_name
        input_file = f'{app_name}_redundant_file.txt'
        output_file = f'{app_name}_redundant_file_report.xlsx'

        if not os.path.exists(input_file):
            # 本地缺失 -> 自动发现 hdc 并拉取 (PATH 优先, 其次常见 SDK 位置)
            print(f'本地不存在 {input_file}, 尝试自动从设备拉取...')
            local, err = pull_redundant_file(app_name)
            if err or not local:
                print(f'自动拉取失败: {err}')
                print('请手动执行 (hdc 不在 PATH 时用完整路径):')
                print(f'  hdc file recv /data/app/el2/100/base/{app_name}/files/{app_name}_redundant_file.txt ./')
                print('或使用 --file 参数直接指定本地文件路径')
                sys.exit(1)
            print(f'已从设备拉取: {input_file}')
    else:
        parser.print_help()
        sys.exit(1)

    print(f'正在解析: {input_file}')
    data = parse_redundant_file(input_file)

    print(f'解析完成:')
    print(f'  总文件数: {data["summary"].get("total_file_number", 0)}')
    print(f'  Used 文件数: {len(data["used_files"])}')
    print(f'  Unused 文件数: {len(data["unused_files"])}')
    print(f'  Unused 加载时间占比: {data["summary"].get("unused_cost_time_ms", 0) / max(data["summary"].get("total_time_ms", 1), 1) * 100:.1f}%')

    write_excel(data, output_file)


if __name__ == '__main__':
    main()
