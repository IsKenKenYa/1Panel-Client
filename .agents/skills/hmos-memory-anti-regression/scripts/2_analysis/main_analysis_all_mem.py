
import sys
from pathlib import Path
import argparse
import concurrent.futures

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import DEFAULT_TYPES, config_data
from statistic_htrace_analysis import process_data

PATH = ""
SN = ""
VERSION = ""
TEST_MODEL = ""
OSS_PATH = ""
DATE = ""
empty_service = 35
hiprofiler_noise = 42
arkts_empty_service = 10
MAX_THREADS = 4
detail = False

_CATEGORY_MAP = {"GL": "gpu", "Graph": "dma"}

def parse_arg_list(s):
    return s.split(",")


def set_config():
    parser = argparse.ArgumentParser(description='compare')
    parser.add_argument('-p', '--path', type=str,
                        help='hitrace路径', nargs='?', default=PATH)
    parser.add_argument('-s', '--sn', type=str,
                        help='hitrace路径', nargs='?', default=SN)
    parser.add_argument('-v', '--version', type=str,
                        help='hitrace路径', nargs='?', default=VERSION)
    parser.add_argument('-m', '--model', type=str,
                        help='hitrace路径', nargs='?', default=TEST_MODEL)
    parser.add_argument('--oss', type=str,
                        help='hitrace路径', nargs='?', default=OSS_PATH)
    parser.add_argument(
        '-t', '--type',
        type=lambda x: set(map(int, x.split(','))),
        default=DEFAULT_TYPES
    )
    parser.add_argument(
        "-k", "--kinds",
        type=parse_arg_list,
        help="待解析三级分类列表"
    )
    parser.add_argument(
        "-f", "--outputFile",
        type=str,
        help="输出的Excel文件路径",
        default=None
    )
    parser.add_argument(
        "-l", "--limit",
        type=lambda x: list(map(int, x.split(','))),
        help="输出范围默认是-l 0,0,10 （第一个数字是每个2级领域最多显示多少so，第二个数字是过滤小于多少百分比的so，第三数字是过滤小于多少M的so）",
        default=[10, 0, 5]
    )
    parser.add_argument(
        "--detail",
        action='store_true',
        help="使用详细模式来解析trace",
        default=detail
    )
    parser.add_argument(
        "--soDir",
        type=str,
        help="符号表路径",
        required=False
    )
    parser.add_argument(
        "--tempDir",
        type=str,
        help="临时目录",
        required=False
    )
    parser.add_argument(
        "--topFrame",
        type=int,
        help="top栈帧分析",
    )
    parser.add_argument(
        "--showmap",
        type=str,
        help="showmap 文件路径 (hidumper --mem-smaps 输出, 12 列含 Name/Category)",
        default=""
    )
    parser.add_argument(
        "--procSmaps",
        type=str,
        help="proc smaps 文件路径 (cat /proc/<pid>/smaps, 供混合模式 VMA 映射做 SO_SIZE 归因)",
        default=""
    )
    parser.add_argument(
        "-o", "--output-path",
        type=str,
        help="输出目录",
        default=None
    )
    parser.add_argument(
        "--scene",
        type=str,
        help="场景名称",
        default="默认场景"
    )
    parser.add_argument(
        "--mm-dmabuf",
        type=str,
        help="mm_dmabuf_info文件路径 (cat /proc/pid/mm_dmabuf_info)",
        default=""
    )
    args = parser.parse_args()

    # 更新配置数据
    config_data["type"] = args.type
    config_data["kinds"] = args.kinds
    config_data["limit"] = args.limit
    if len(config_data["limit"]) < 3:
        config_data["limit"] += [0] * (3 - len(config_data["limit"]))
    config_data["pid"] = -1
    config_data["newrule"] = True
    config_data["detail"] = args.detail
    config_data["detail_explicitly_set"] = args.detail
    if args.soDir:
        config_data["so_dir"] = args.soDir
    if args.tempDir:
        config_data["temp_dir"] = args.tempDir
    config_data['sn'] = args.sn
    config_data["version"] = args.version
    config_data["date"] = DATE
    config_data['test_model'] = args.model
    config_data['heading'] = False
    config_data["oss_path"] = args.oss
    config_data["top_frame"] = args.topFrame
    config_data["empty_service"] = empty_service
    config_data["hiprofiler_noise"] = hiprofiler_noise
    config_data["arkts_empty_service"] = arkts_empty_service
    config_data["proc_smaps"] = args.procSmaps or None
    if not config_data["proc_smaps"]:
        for pattern in ["meminfo/dynamic_appsmaps/com.*_*.txt", "meminfo/smaps/raw_smaps_*.txt", "raw_smaps_*.txt"]:
            matches = sorted(Path(str(args.path)).glob(pattern))
            if matches:
                config_data["proc_smaps"] = str(matches[0])
                print(f"  [兜底] --procSmaps 未传, 自动使用 {matches[0]}")
                break
    config_data["showmap"] = args.showmap
    if not config_data["showmap"]:
        for pattern in ["meminfo/dynamic_showmap/com.*_*.txt", "meminfo/smaps/hidumper_smaps_*.txt", "hidumper_smaps_*.txt", "hidumper_showmap_*.txt", "showmap_*.txt"]:
            matches = sorted(Path(str(args.path)).glob(pattern))
            if matches:
                config_data["showmap"] = str(matches[0])
                print(f"  [兜底] --showmap 未传, 自动使用 {matches[0]}")
                break
    config_data["startts"] = None
    endts = None
    if config_data.get("showmap"):
        import re
        m = re.search(r'(\d{8}-\d{6})', Path(config_data["showmap"]).name)
        if m:
            endts = m.group(1)
            print(f"  [endts] 从 showmap 文件名提取时间戳: {endts}")
    config_data["endts"] = endts
    config_data["db_dir"] = str(args.path)
    if args.output_path:
        config_data["output_path"] = args.output_path
        import os
        os.makedirs(args.output_path, exist_ok=True)
    config_data["scene"] = args.scene
    config_data["mm_dmabuf_file"] = args.mm_dmabuf
    return Path(args.path)


def process_directory(directory, directory2, config):
    config_data = config

    for f in directory2.iterdir():
        if f.is_file():
            continue
        if 'PerformanceDynamic' not in directory2.name:
            continue

        process_data(
            trace_path=str(f / 'hitrace'),
            out_path=str(path / (directory.name + "_mem_result") /
                         (directory2.name + '_' + f.name)))

if __name__ == "__main__":
    path = set_config()

    if 'PerformanceDynamic' not in str(path):
        if not config_data.get("mm_dmabuf_file"):
            for pattern in ["meminfo/dynamic_process_dmabuf_info/process_dmabuf_info_*.txt", "meminfo/dynamic_process_dmabuf_info/mm_dmabuf_info_*.txt", "meminfo/mem_dmabuf/mm_dmabuf_info_*.txt", "mm_dmabuf_info_*.txt"]:
                matches = sorted(Path(str(path)).glob(pattern))
                if matches:
                    config_data["mm_dmabuf_file"] = str(matches[0])
                    break
        # Pre-copy meminfo.xlsx to output_path so topdown.py inside process_data() can find it
        import shutil
        src_meminfo = Path(str(path)) / "meminfo.xlsx"
        dst_meminfo = Path(config_data["output_path"]) / "meminfo.xlsx"
        if src_meminfo.exists() and not dst_meminfo.exists():
            shutil.copy2(str(src_meminfo), str(dst_meminfo))
        process_data(str(path), config_data["output_path"])
    else:
        with concurrent.futures.ProcessPoolExecutor(max_workers=MAX_THREADS) as executor:
            futures = []
            for i in path.iterdir():
                if i.is_file():
                    continue
                if 'mem_result' in i.name:
                    continue
                futures += [executor.submit(process_directory, i, j, config_data.copy()) for j in i.iterdir()]
            for future in concurrent.futures.as_completed(futures):
                try:
                    future.result()
                except Exception as e:
                    print(f"子进程异常: {e}")
            concurrent.futures.wait(futures)