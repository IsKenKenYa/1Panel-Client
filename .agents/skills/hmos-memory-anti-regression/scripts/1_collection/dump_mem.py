import os
import subprocess
import sys
from pathlib import Path
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
from tool_finder import find_hdc, hdc_env

def run_hdc_shell(hdc, device_cmd, timeout=120):
    """Execute `hdc shell <device_cmd>` and return stdout as string."""
    result = subprocess.run(
        [hdc, "shell"] + device_cmd.split(),
        capture_output=True, text=True, errors="replace",
        timeout=timeout, env=hdc_env(),
    )
    return result.stdout


def run_hdc_shell_to_file(hdc, device_cmd, out_path, timeout=120):
    """Execute `hdc shell <device_cmd>` and write stdout to out_path.

    Uses Python file I/O instead of shell redirect (>) so that Chinese
    characters in the output path are handled correctly on Windows.
    """
    result = subprocess.run(
        [hdc, "shell"] + device_cmd.split(),
        capture_output=True, text=True, errors="replace",
        timeout=timeout, env=hdc_env(),
    )
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    Path(out_path).write_text(result.stdout, encoding="utf-8")
    return result.stdout


_SMAPS_PERM_MARKERS = ("permission denied", "not permitted", "no such file or directory", "operation not permitted")


def smaps_is_valid(path) -> bool:
    """Check if a /proc/<pid>/smaps file has valid VMA data.

    On non-root devices `cat /proc/<pid>/smaps` may return only a permission
    error (or empty output). A valid smaps file must contain 'Size:' fields;
    files holding only an error message or zero bytes are treated as invalid.
    """
    try:
        p = Path(path)
        if not p.exists() or p.stat().st_size == 0:
            return False
        text = p.read_text(encoding="utf-8", errors="replace").lower()
    except OSError:
        return False
    if any(m in text for m in _SMAPS_PERM_MARKERS):
        return False
    return "size:" in text


def smaps_is_permission_failure(path) -> bool:
    """True if smaps output is empty or a permission/access error (非 root 信号)。

    用于区分非 root 权限失败 (→ 写 .nonroot_smaps 标记, 校验视为可接受) 与
    其他失败 (root 设备异常, 不写标记, 校验视为必需缺失)。
    """
    try:
        p = Path(path)
        if not p.exists() or p.stat().st_size == 0:
            return True
        text = p.read_text(encoding="utf-8", errors="replace").lower()
    except OSError:
        return True
    return any(m in text for m in _SMAPS_PERM_MARKERS)


def run(cmd, capture=True):
    """执行命令"""
    if capture:
        return subprocess.check_output(cmd, shell=True, text=True, errors="ignore")
    else:
        subprocess.run(cmd, shell=True)
        return None


def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def timestamp_now():
    t = datetime.now()
    return int(t.timestamp() * 1000), t.strftime("%Y%m%d-%H%M%S")


def main():
    if len(sys.argv) != 3 and len(sys.argv) != 4:
        print(
            f"""
用法: 
    python {sys.argv[0]} <process_name> <case>
    python {sys.argv[0]} <process_name> <case> <output_dir>
""")
        sys.exit(1)

    search_name = sys.argv[1]
    case = sys.argv[2]
    out = Path(__file__).parent / "hidumper" / search_name if len(sys.argv) == 3 else Path(sys.argv[3])
    t, timestamp = timestamp_now()
    hdc = find_hdc() or "hdc"
    print(f"📤 timestamp: {timestamp};")

    # ========================
    # 查找进程
    # ========================
    processes = {}

    ps_output = run_hdc_shell(hdc, f"ps -ef | grep {search_name} | grep -v grep")
    main_pid = None
    for line in ps_output.splitlines():
        parts = line.split()
        if len(parts) < 8:
            continue
        pid = parts[1]
        process_name = parts[7]
        if ':' not in process_name:
            main_pid = pid
        clean_name = process_name.replace(":", "_")
        if pid not in processes:
            processes[pid] = process_name
        print(f"当前进程 PID: {pid}, 进程名称: {clean_name}")
    if main_pid is None:
        raise Exception(f"未找到主进程：\n {ps_output}")
    print(f"主进程 PID: {main_pid}")
    root_folder = out / "meminfo"

    # ========================
    # dynamic_gpuMem
    # ========================
    print("====================================================================================")
    print("正在保存 dynamic_gpuMem")
    print("↓")
    folder = root_folder / "dynamic_gpuMem"
    ensure_dir(folder)
    gpu_file = folder / f"gpuMem_{timestamp}_PerformanceDynamic_{search_name}_{case}.txt"
    run_hdc_shell_to_file(hdc, "cat /proc/gpu_memory", gpu_file)
    print(f"  GPU 内存信息已保存到: {gpu_file}")

    # ========================
    # dynamic_process_dmabuf_info
    # ========================
    print("====================================================================================")
    print("正在保存 dynamic_process_dmabuf_info")
    print("↓")
    folder = root_folder / "dynamic_process_dmabuf_info"
    ensure_dir(folder)
    dma_file = folder / f"process_dmabuf_info_{timestamp}_PerformanceDynamic_{search_name}_{case}.txt"
    run_hdc_shell_to_file(hdc, f"cat /proc/{main_pid}/mm_dmabuf_info", dma_file)
    print(f"  DMA 缓冲区信息已保存到: {dma_file}")

    # ========================
    # dynamic_meminfo
    # ========================
    print("====================================================================================")
    print("正在保存 dynamic_meminfo")
    print("↓")
    folder = root_folder / "dynamic_meminfo"
    ensure_dir(folder)
    meminfo_file = folder / f"dynamicMem_{timestamp}_PerformanceDynamic_{search_name}_{case}.txt"
    run_hdc_shell_to_file(hdc, "hidumper --mem --prune", meminfo_file)
    print(f"  meminfo 信息已保存到: {meminfo_file}")

    # ========================
    # dynamic_meminfo
    # ========================
    print("====================================================================================")
    print("正在保存 dynamic_dumpMem")
    print("↓")
    folder = root_folder / "dynamic_dumpMem"
    ensure_dir(folder)
    dump_mem_file = folder / f"dumpMem_{timestamp}_PerformanceDynamic_{search_name}_{case}.txt"
    run_hdc_shell_to_file(hdc, "hidumper -s 10 -a dumpMem", dump_mem_file)
    print(f"  dumpMem 信息已保存到: {dump_mem_file}")

    # ========================
    # dynamic_showmap
    # ========================
    print("====================================================================================")
    print("正在保存 dynamic_showmap")
    print("↓")
    folder = root_folder / "dynamic_showmap"
    ensure_dir(folder)
    for pid, process_name in processes.items():
        clean_name = process_name.replace(":", "_")
        out_file = folder / f"{clean_name}_{pid}_{timestamp}_PerformanceDynamic_{search_name}_{case}.txt"
        print(f"正在执行 hidumper --mem-smaps PID={pid}")
        print(f"  正在执行 hidumper --mem-smaps PID={pid}")
        run_hdc_shell_to_file(hdc, f"hidumper --mem-smaps {pid}", out_file, timeout=300)
        print(f"  showmap 信息已保存到: {out_file}")
    
    # ========================
    # 混合模式
    # ========================
    print("====================================================================================")
    print(f"正在保存 /proc/{main_pid}/dynamic_appsmaps")
    folder = root_folder / "dynamic_appsmaps"
    ensure_dir(folder)
    modified_timestamp = timestamp.replace("-", "")
    smaps_file = folder / f"{processes[main_pid]}_{main_pid}_{modified_timestamp}000.txt"
    run_hdc_shell_to_file(hdc, f"cat /proc/{main_pid}/smaps", smaps_file, timeout=300)
    if smaps_is_valid(smaps_file):
        print(f"  /proc/{main_pid}/smaps 已保存到: {smaps_file}")
    else:
        is_perm = smaps_is_permission_failure(smaps_file)
        smaps_file.unlink(missing_ok=True)
        if is_perm:
            # 非 root: 写标记供 verify_collection 识别为可接受的软失败
            (out / ".nonroot_smaps").write_text(
                "raw smaps 权限失败 (非root): cat /proc/<pid>/smaps 不可读\n",
                encoding="utf-8")
            print(f"  /proc/{main_pid}/smaps 采集失败 (非root设备无权限), 跳过混合模式 raw smaps")
            print(f"   影响: 混合模式 SO_SIZE 归因不可用, topdown 分析仍可正常运行")
        else:
            print(f"  /proc/{main_pid}/smaps 采集异常 (输出无有效 VMA), 请排查设备状态")

    # ========================
    # hilog (供 ArkWeb 案例匹配: CreateNWeb/NWebImpl::OnDestroy 事件计数)
    # ========================
    print("====================================================================================")
    print("正在保存 hilog (应用日志，供 ArkWeb 案例匹配使用)")
    print("↓")
    folder = root_folder / "hilog"
    ensure_dir(folder)
    hilog_file = folder / f"hilog_{main_pid}_{timestamp}_{search_name}_{case}.txt"
    # hilog -x 非阻塞读取缓冲区所有日志后退出（含系统级 Web 引擎事件，不按 PID 过滤）
    hilog_stdout = run_hdc_shell_to_file(hdc, "hilog -x", hilog_file, timeout=30)
    hilog_lines = len((hilog_stdout or "").splitlines())
    print(f"  hilog 已保存到: {hilog_file} ({hilog_lines} 行)")

    # ========================
    # 窗口/组件树 dump (供 ArkWeb 案例匹配: 当前显示的 Web 组件数 b)
    # ========================
    print("====================================================================================")
    print("正在保存窗口/组件树 dump (供 ArkWeb 案例匹配使用)")
    print("↓")
    folder = root_folder / "window_dump"
    ensure_dir(folder)
    # WindowManagerService -a "-a" dump all window information
    win_file = folder / f"window_{main_pid}_{timestamp}_{search_name}_{case}.txt"
    win_stdout = run_hdc_shell_to_file(
        hdc, 'hidumper -s WindowManagerService -a "-a"', win_file, timeout=30)
    win_lines = len((win_stdout or "").splitlines())
    if win_lines > 0:
        print(f"  窗口 dump 已保存到: {win_file} ({win_lines} 行)")
    else:
        print(f"  窗口 dump 为空 (设备可能不支持 WindowManagerService dump)")

if __name__ == "__main__":
    main()
