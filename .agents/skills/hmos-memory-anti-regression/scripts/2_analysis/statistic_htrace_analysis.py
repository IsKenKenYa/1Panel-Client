
import sys
from pathlib import Path
import argparse
import json
import logging
import os

from openpyxl import Workbook
from openpyxl.styles import Alignment
from openpyxl.utils.dataframe import dataframe_to_rows

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
sys.path.insert(0, str(Path(__file__).resolve().parent / "../1_collection"))
from callchain import OptimizedCallChain
from detail_mode import add_detail_data
from rule import find_response_field
from tracedbs import merge_multiple_dbs_to_json, query_string_table
from hidumper import add_so_data, add_web_data, add_native_heap_data
from hybrid_mod import add_anno_data
import first_kind_proc, third_kind_proc
from first_kind_proc import data_to_df
from topdown import add_topdown_data
from analysis_utils import thread_local, normalize_for_excel
from config import TraceType, DEFAULT_TYPES, DEFAULT_HTRACE_PATH, config_data
from convert_htrace_to_sqlitedb import htrace_to_sqlitedb, check_db_files_exist

logger = logging.getLogger()


def get_trace_name(target_file_path):
    if not os.path.exists(target_file_path):
        raise NotADirectoryError(f"目录不存在: {target_file_path}")
    if not os.path.isdir(target_file_path):
        raise NotADirectoryError(f"不是有效目录: {target_file_path}")

    files = os.listdir(target_file_path)
    return next(Path(target_file_path).glob("*.htrace"))


def alter_heap_size(chain):
    # if chain["type"] == TraceType.SO_SIZE.name:
    #     heap_count = chain["apply_count"] - chain["release_count"]
    #     if heap_count != 0:
    #         chain["heap_size"] = (chain["heap_size"] / (chain["apply_count"] - chain["release_count"]))
    #     else:
    #         chain["heap_size"] = 0
    #     return
    if not chain["frames"]:
        return
    if chain["type"] != TraceType.DMA.name:
        for frame in chain["frames"]:
            if "ExtractFromParcel" in frame["symbol_data"]:
                heap_count = chain["apply_count"] - chain["release_count"]
                if heap_count != 0:
                    chain["heap_size"] = (chain["heap_size"] / (chain["apply_count"] - chain["release_count"]))
                else:
                    chain["heap_size"] = 0
                break

def is_valid(chain):
    # DMA数据统计的时候，去掉回栈包含WriteFileDescriptor的数据
    if chain["type"] != "DMA":
        return True
    dup = False
    for frame in chain["frames"][::-1]:
        if ("WriteFileDescriptor" in frame["symbol_data"]) or ("CloneNativeBufferHandle" in frame["symbol_data"]):
            return False
        if frame["symbol_data"] == "dup":
            dup = True
            continue
        # 调用堆栈有dup，且上层调用不是ReadFileDescriptor的，全部过滤掉
        if dup and ("ReadFileDescriptor" not in frame["symbol_data"]):
            return False
        if dup:
            dup = False
    return True

def init_workbook():
    # 创建 Excel 工作簿
    wb = Workbook()
    ws = wb.active  # 获取当前活动的默认sheet
    wb.remove(ws)  # 删除该sheet
    return wb


def to_xlsx(ws, df):
    for r in dataframe_to_rows(df, index=False, header=True):
        ws.append(r)
    center = Alignment(horizontal="center", vertical="center")
    for row in ws.iter_rows():
        for cell in row:
            cell.alignment = center


def parse_arg_list(s):
    return s.split(",")


def merge_db_to_json(_types):
    callchain_data = merge_multiple_dbs_to_json(
        config_data["db_dir"],
        _types,
        startts=config_data["startts"],
        endts=config_data["endts"],
        pid=config_data["pid"],
    )

    output_dir = config_data.get("outputFile")
    if output_dir:
        json_path = os.path.join(config_data["htrace_dir"], 'callchain_result.json')
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(callchain_data.to_dict(), f, indent=4, ensure_ascii=False)
        logger.debug("Merged DB result written to %s", json_path)

    return callchain_data


def find_responsibilities(_type, callchain_data):
    source_data = callchain_data
    res = OptimizedCallChain()
    for item in source_data:
        # if not is_valid(item):
        #     if config_data["verbose"]:
        #         logger.warning(f"无效调用栈{item}")
        #     continue
        if item["type"] == TraceType.SO_SIZE.name:
            continue
        alter_heap_size(item)
        # 只要求分解指定三级领域的 frame 堆栈，如果未指定则分解所有 frame 堆栈
        response_field = find_response_field(item)
        item['field'] = {
            "response_so": response_field[3],
            "firstkind": response_field[0],
            "secondkind": response_field[1],
            "thirdkind": response_field[2]
        }
        res.append(item)

    if config_data["showmap"] and TraceType.SO_SIZE.value in config_data['type']:
        add_so_data(config_data["showmap"], res)
    if config_data["proc_smaps"] and config_data["showmap"]:
        # 混合模式，统计 native_hook 表中的 MmapEvent
        add_anno_data(config_data["proc_smaps"], res)
    if config_data["showmap"]:
        add_web_data(config_data["showmap"], res)
        add_native_heap_data(config_data["showmap"], res)
    # add_topdown_data 必须是最后一个执行
    context = add_topdown_data(res)
    thread_local.ctx = context
    # none_cc = OptimizedCallChain()
    # for item in res:
    #     if item['field']["response_so"] is None:
    #         none_cc.append(item)
    # with open(Path(config_data["output_path"], f"none堆栈-{config_data['scene']}.json"), "w", encoding="utf-8") as f:
    #     json.dump(none_cc.to_dict(), f, ensure_ascii=False, indent=4)
    # flame = FlameGraph(none_cc, config_data["output_path"], only_full=True)
    # flame.build_full_flame_graph(f"response_so为none-{config_data['scene']}")

    # if config_data["top_frame"]:
    #     top_100_frame(res)
    first_kind_proportion, total_size = first_kind_proc.find_field_proportion(res)
    third_kind_proportion, _ = third_kind_proc.find_3rd_kind_field_proportion(res)
    for _, first_proportion in first_kind_proportion.items():
        third_kinds = first_proportion["third_kind"]
        for third_kind, third_proportion in third_kinds.items():
            third_proportion["so"] = third_kind_proportion[third_kind]["so"]
    print(f'firstkind _{_type}_ 存活内存:{total_size / (1024 * 1024)}')
    return first_kind_proportion, res

def init_config(args=None):
    parser = argparse.ArgumentParser(description='compare')
    parser.add_argument(
        '-p', '--path',
        type=str,
        help='hitrace路径',
        nargs='?',
        default=DEFAULT_HTRACE_PATH
    )
    parser.add_argument(
        '-s', '--start',
        type=str,
        help='开始时间yyyymmdd-hhmmss'
    )
    parser.add_argument(
        '-e', '--end',
        type=str,
        help='结束时间yyyymmdd-hhmmss'
    )
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
        "--showmap",
        type=str,
        help="showmap文件路径",
        default=""
    )
    parser.add_argument(
        "--newrule",
        action='store_true',
        help="使用新规则（输出整体内存情况时使用，竞品分析不要使用）\
            提供了merge参数默认使用新规则"
    )
    parser.add_argument(
        "--detail",
        action='store_true',
        help="使用详细模式来解析trace"
    )
    parser.add_argument(
        "--procSmaps",
        type=str,
        help="/proc/3055/smaps 文件路径，用于混合模式",
        default=""
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
        "--board",
        action='store_true',
        help="上传到看板"
    )
    parser.add_argument(
        "--topFrame",
        type=int,
        help="top栈帧分析",
    )
    parser.add_argument(
        "--mm_dmabuf",
        type=str,
        help="mm_dmabuf_info文件路径，用于DMA按buf_type和图片名归因",
        default=""
    )
    args = parser.parse_args(args)

    # 更新配置数据
    config_data["htrace_dir"] = args.path
    config_data["type"] = args.type
    config_data["startts"] = args.start
    config_data["endts"] = args.end
    if args.outputFile:
        config_data["output_path"] = args.outputFile
    else:
        config_data["output_path"] = os.path.join(config_data["htrace_dir"], 'output')
    os.makedirs(config_data["output_path"], exist_ok=True)
    config_data["showmap"] = args.showmap
    config_data["kinds"] = args.kinds
    config_data["limit"] = args.limit
    if len(config_data["limit"]) < 3:
        config_data["limit"] += [0] * (3 - len(config_data["limit"]))
    config_data["pid"] = -1
    config_data["merge"] = None
    config_data["newrule"] = True
    config_data["detail"] = args.detail
    config_data["detail_explicitly_set"] = args.detail
    config_data["board"] = args.board
    config_data["top_frame"] = args.topFrame
    config_data["proc_smaps"] = args.procSmaps
    config_data["mm_dmabuf_file"] = args.mm_dmabuf
    if args.soDir:
        config_data["so_dir"] = args.soDir
    if args.tempDir:
        config_data["temp_dir"] = args.tempDir


def query_callchains():
    t_list = config_data["type"]
    if not config_data["detail"]:
        # 统计模式
        callchain_data = merge_db_to_json(t_list)
    else:
        # 详细模式
        detail_types = []
        if TraceType.NATIVE_HEAP.value in t_list:
            detail_types.append(TraceType.NATIVE_HEAP)
        if TraceType.ARKTS_HEAP.value in t_list:
            detail_types.append(TraceType.ARKTS_HEAP)
        if TraceType.GPU_VK.value in t_list:
            detail_types.append(TraceType.GPU_VK)
        if TraceType.GPU_GLES.value in t_list:
            detail_types.append(TraceType.GPU_GLES)
        if TraceType.GPU_CL.value in t_list:
            detail_types.append(TraceType.GPU_CL)
        if TraceType.ASHMEM.value in t_list:
            detail_types.append(TraceType.ASHMEM)
        if TraceType.DMA.value in t_list:
            detail_types.append(TraceType.DMA)
        callchain_data = add_detail_data(detail_types)
    return callchain_data


def deal_data_to_wb(wb, scene, sub_process_data):
    """
    主处理函数，包含操作记录读取和Excel生成等功能。
    """
    # 將db文件转化为json
    callchain_data = query_callchains()

    # 统计拆解结果
    first_kind_proportion, field_data = find_responsibilities(config_data["type"], callchain_data)
    df = data_to_df(first_kind_proportion)
    df = df.map(normalize_for_excel)
    first_kind_proc.append_summary_data(first_kind_proportion, scene)
    ws = wb.create_sheet(title=scene)
    to_xlsx(ws, df)



def __inner_process_data():
    # 将所有htrace文件存入db
    if not check_db_files_exist(config_data["htrace_dir"]):
        htrace_to_sqlitedb(str(config_data["trace"]), config_data["htrace_dir"])

    if not config_data.get("detail_explicitly_set"):
        from tracedbs import detect_db_mode
        config_data["detail"] = detect_db_mode(config_data["htrace_dir"])
        mode_name = "详细模式" if config_data["detail"] else "统计模式"
        print(f"  自动检测DB模式: {mode_name} (detail={config_data['detail']})")

    wb = init_workbook()
    string_table = query_string_table(config_data["htrace_dir"])
    OptimizedCallChain.init_table_dict(string_table)

    scene = config_data.get("scene", "默认场景")
    deal_data_to_wb(wb, scene, None)
    wb.save(os.path.join(config_data["output_path"], config_data["case"] + '_' + '详细数据.xlsx'))
    # Generate DMA detail Excel if mm_dmabuf_file is configured
    mm_dmabuf_file = config_data.get("mm_dmabuf_file", "")
    if mm_dmabuf_file and Path(mm_dmabuf_file).exists():
        from topdown import generate_dma_detail_excel
        generate_dma_detail_excel(mm_dmabuf_file, Path(config_data["output_path"]))
    first_kind_proc.make_summary_excel()
    __validate_outputs()


def __validate_outputs():
    output_path = Path(config_data["output_path"])
    missing = []
    expected = [
        (f"{config_data['case']}_详细数据.xlsx", True),
        ("汇总.xlsx", True),
        (f"topdown报告-{config_data['scene']}.xlsx", True),
    ]
    conditional = [
        ("dma_detail.xlsx", config_data.get("mm_dmabuf_file")),
        ("meminfo.xlsx", config_data.get("showmap")),
        (f"混合模式明细-{config_data['scene']}.xlsx", config_data.get("proc_smaps")),
    ]
    for filename, required in expected:
        if not (output_path / filename).exists():
            missing.append((filename, required))
    for filename, has_input in conditional:
        if has_input and not (output_path / filename).exists():
            missing.append((filename, True))
    if missing:
        print("\n以下预期文件未生成：")
        for f, required in missing:
            label = "必需" if required else "可选"
            print(f"   [{label}] {f}")
        print("请检查输入参数是否完整（如 --showmap、--mm-dmabuf、--procSmaps 等）")


def process_data(trace_path, out_path):
    config_data["htrace_dir"] = trace_path
    config_data["merge"] = None
    config_data["output_path"] = out_path
    os.makedirs(config_data["output_path"], exist_ok=True)
    config_data["trace"] = get_trace_name(config_data["htrace_dir"])
    config_data["case"] = Path(out_path).name
    __inner_process_data()


if __name__ == "__main__":
    init_config()
    __inner_process_data()