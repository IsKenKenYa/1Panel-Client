#!/usr/bin/env python3
"""应用 HTrace 数据采集 (Python 实现, 复用 CmdRunner)。

跨主机 OS (Linux/macOS/Windows): pathlib 处理路径, 复用 _lib/cmd_runner.CmdRunner
的 hdc 封装 (run_on_device/push_to_device/pull_from_device/find_hdc), 不再依赖 bash 脚本。

用法:
  python scripts/1_collection/collect.py --app <应用名> [--yes] <版本标签> [时长]
  例: python scripts/1_collection/collect.py --app myapp --yes v1 30

采集流程:
  Phase 1: 应用安装检查 + 登录前置操作 (--login-script 时自动执行登录脚本, 否则人工确认)
  Phase 2: 杀死应用 + 启动 htrace (nativehook 详细模式, startup_mode=true 冷启动)
            + 清空 hilog 缓冲区 (hilog -r)
           --scenario 时自动运行场景复现替代手工操作
  Phase 3: 采集 showmap / smaps / mm_dmabuf_info / hilog / 窗口dump
  Phase 4: 重新拉起进程 + 采集 heapsnapshot
  Phase 5: 拉取 htrace 及其余产物
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
from cmd_runner import CmdRunner  # noqa: E402
from tool_finder import find_hdc, hdc_env  # noqa: E402
from verify_collection import verify_products  # noqa: E402

DEVICE_TMP = "/data/local/tmp"
HEAP_REMOTE_DIR = "/data/log/reliability/resource_leak/memory_leak"

NATIVEHOOK_CONFIG = """request_id: 1
session_config {
  buffers {
    pages: 131072
  }
}
plugin_configs {
  plugin_name: "nativehook"
  sample_interval: 1000
  config_data {
    save_file: false
    filter_size:128
    smb_pages: 16384
    max_stack_depth: 50
    process_name: "{process_name}"
    string_compressed: true
    fp_unwind: true
    blocked: true
    callframe_compress: true
    record_accurately: true
    offline_symbolization: true
    statistics_interval: 0
    startup_mode: true
    js_stack_report: 1
    max_js_stack_depth: 16
    malloc_disable: false
    memtrace_enable: true
    async_stack_enable: true
    async_type: ALL_ASYNC_TYPE
    restrace_tag: "RES_DMABUF_MASK"
    restrace_tag: "RES_FD_ALL"
    restrace_tag: "RES_ARKTS_HEAP_MASK"
    restrace_tag: "RES_JS_HEAP_MASK"
    restrace_tag: "RES_GPU_GLES_IMAGE"
    restrace_tag: "RES_GPU_VK"
    restrace_tag: "RES_GPU_GLES_BUFFER"
    restrace_tag: "RES_GPU_CL_IMAGE"
    unique_stack_table_size:256
    use_file_cache_mode:true
  }
}
"""


def prompt_confirm(msg: str, yes: bool) -> None:
    """--yes 跳过; 非 TTY 无 --yes 报错退出 (杜绝静默自动采集); TTY 等 Enter."""
    if yes:
        return
    if not sys.stdin.isatty():
        print(f"[错误] {msg}", file=sys.stderr)
        print("        非交互环境且未传 --yes: 请先与用户确认 (采集步骤/时长/复现时机/登录状态) 后加 --yes 运行",
              file=sys.stderr)
        sys.exit(1)
    input(msg)


def find_pid(runner: CmdRunner, process_name: str) -> str | None:
    """优先精确匹配主进程名 (排除 :render/:webview 子进程), 找不到回退首个包含匹配."""
    r = runner.run_on_device(["ps", "-ef"])
    lines = r.stdout.splitlines()
    # 精确: 最后字段 == process_name
    for line in lines:
        parts = line.split()
        if len(parts) >= 2 and parts[-1] == process_name:
            return parts[1]
    # 回退: 含 process_name 的首行 (排除 ps 自身)
    for line in lines:
        parts = line.split()
        if len(parts) >= 2 and process_name in line and "grep" not in line:
            return parts[1]
    return None

def _get_device_version(runner: CmdRunner, bundle: str) -> tuple[str, str]:
    """Get installed app versionCode and versionName from device. Returns ('', '') if not installed."""
    r = runner.run_on_device(["bm", "dump", "-n", bundle])
    text = r.stdout or ""
    if bundle not in text:
        return "", ""
    # Find the outermost versionCode/versionName (the last occurrence in bm dump output)
    vc_matches = re.findall(r'"versionCode"\s*:\s*(\d+)', text)
    vn_matches = re.findall(r'"versionName"\s*:\s*"([^"]*)"', text)
    # The outermost (app-level) values appear last
    version_code = vc_matches[-1] if vc_matches else ""
    version_name = vn_matches[-1] if vn_matches else ""
    return version_code, version_name


def _get_hap_info(hap_path: str) -> tuple[str, str, str]:
    """Extract versionCode, versionName and bundleName from a HAP file (zip).
    Returns ('', '', '') on failure."""
    try:
        with zipfile.ZipFile(hap_path) as z:
            for name in z.namelist():
                if name.endswith("module.json") or name.endswith("config.json"):
                    content = z.read(name).decode("utf-8", errors="replace")
                    vc = re.search(r'"versionCode"\s*:\s*(\d+)', content)
                    vn = re.search(r'"versionName"\s*:\s*"([^"]*)"', content)
                    bn = re.search(r'"bundleName"\s*:\s*"([^"]*)"', content)
                    return (vc.group(1) if vc else "",
                            vn.group(1) if vn else "",
                            bn.group(1) if bn else "")
    except Exception:
        pass
    return "", "", ""


def _get_ability_from_hap(hap_path: str) -> str:
    """Extract the main/entry ability name from a HAP's module.json.

    Looks for `module.mainElement` (the declared entry ability). Returns '' if
    not found (caller should fall back to device bm dump query or --ability).
    """
    try:
        with zipfile.ZipFile(hap_path) as z:
            for name in z.namelist():
                if name.endswith("module.json") or name.endswith("config.json"):
                    content = z.read(name).decode("utf-8", errors="replace")
                    m = re.search(r'"mainElement"\s*:\s*"([^"]+)"', content)
                    if m:
                        return m.group(1)
    except Exception:
        pass
    return ""


def _get_ability_from_device(runner: CmdRunner, bundle: str) -> str:
    """Query installed app's ability names from device via `bm dump -n`.
    Returns the first PAGE-type ability name, or '' if not found."""
    try:
        result = runner.run_on_device(["bm", "dump", "-n", bundle])
        if result.returncode != 0 or not result.stdout:
            return ""
        # bm dump output has "abilityInfos" and "extensionAbilityInfos" sections.
        # We collect "name" values that appear after "abilityInfos" and before
        # the next section boundary ("extensionAbilityInfos" or same-level closing).
        lines = result.stdout.splitlines()
        # Track which section we are in: 'ability' or 'extension' or None
        section = None
        # Indentation level of the section header, to detect when it ends
        section_indent = 0
        candidates = []
        for line in lines:
            stripped = line.strip()
            indent = len(line) - len(line.lstrip())
            # Detect section starts
            if '"abilityInfos"' in stripped:
                section = "ability"
                section_indent = indent
                continue
            if '"extensionAbilityInfos"' in stripped:
                section = "extension"
                section_indent = indent
                continue
            # Detect section end: a line at same or lower indent as section header
            if section and stripped and indent <= section_indent and stripped not in ("[", "{", "]", "}"):
                # Could be a new key at same level = section ended
                if not stripped.startswith('"') or ":" not in stripped:
                    pass  # bracket line, ignore
                elif indent <= section_indent:
                    section = None
            # Collect name fields inside ability section
            if section == "ability" and '"name"' in stripped:
                m = re.search(r'"name":\s*"([^"]+)"', stripped)
                if m:
                    val = m.group(1)
                    # Filter: skip ohos.* system names, DFX_*, paths with /
                    if not val.startswith("ohos.") and not val.startswith("DFX_") and "/" not in val:
                        candidates.append(val)
        if not candidates:
            return ""
        # Priority: MainAbility > EntryAbility > first found
        for pref in ("MainAbility", "EntryAbility"):
            if pref in candidates:
                return pref
        return candidates[0]
    except Exception:
        return ""

def _run_login_script(scenario_dir: str, scenario_name: str) -> bool:
    """执行登录预制 Hypium 脚本并校验结果。

    同步执行 `python main.py <scenario_name>`,
    等待结束后复用 _check_scenario_result 解析 xdevice 报告判断成败。

    Args:
        scenario_dir: Hypium 工程根目录 (含 main.py)
        scenario_name: 登录用例名 (如 MyappPrerequisiteSetup)
    Returns:
        True=脚本执行成功, False=失败
    """
    main_py = Path(scenario_dir) / "main.py"
    if not main_py.exists():
        print(f"  [错误] 登录脚本入口不存在: {main_py}", file=sys.stderr)
        return False
    print(f"  执行登录预制脚本: {scenario_name} (dir={scenario_dir})")
    start_time = time.time()
    try:
        result = subprocess.run(
            [sys.executable, str(main_py), scenario_name],
            cwd=str(main_py.parent),
            capture_output=True, text=True, timeout=300,
        )
    except subprocess.TimeoutExpired:
        print("  [错误] 登录脚本执行超时 (>300s)", file=sys.stderr)
        return False
    except Exception as e:
        print(f"  [错误] 登录脚本执行异常: {e}", file=sys.stderr)
        return False

    if result.returncode != 0:
        print(f"  [错误] 登录脚本执行失败 (退出码={result.returncode})", file=sys.stderr)
        if result.stderr:
            print(f"  stderr: {result.stderr}", file=sys.stderr)
        return False

    # 复用 _check_scenario_result 校验 xdevice 报告
    passed, detail = _check_scenario_result(scenario_dir, scenario_name, start_time)
    if passed:
        print(f"  [OK] 登录脚本执行成功: {detail}")
        return True
    else:
        print(f"  [错误] 登录脚本执行失败: {detail}", file=sys.stderr)
        return False


def phase_install_check(runner: CmdRunner, bundle: str, yes: bool,
                        hap_path: str = "",
                        login_scenario: str = "", login_scenario_dir: str = "") -> None:
    print("\n  检查应用是否已安装...")
    device_vc, device_vn = _get_device_version(runner, bundle)
    installed = bool(device_vc)

    if installed:
        print(f"  应用已安装: {bundle} (versionCode={device_vc}, versionName={device_vn})")

        # Version verification: if --hap provided, check installed version matches
        if hap_path:
            hap_vc, hap_vn, _ = _get_hap_info(hap_path)
            if hap_vc:
                print(f"  目标 HAP:  {hap_path} (versionCode={hap_vc}, versionName={hap_vn})")
                if device_vc != hap_vc:
                    print(f"\n  [警告] 版本不匹配! 设备已装 versionCode={device_vc}, 目标 HAP versionCode={hap_vc}")
                    print(f"  将覆盖安装 {hap_path} ...")
                    hap_abs = os.path.abspath(hap_path)
                    result = runner.run([runner.hdc, "install", hap_abs], env=hdc_env())
                    if result.returncode != 0:
                        print(f"  [错误] 安装失败: {result.stderr}", file=sys.stderr)
                        print("  如果是版本降级, 需先卸载: hdc uninstall <bundle>", file=sys.stderr)
                        sys.exit(1)
                    # Verify installation
                    new_vc, new_vn = _get_device_version(runner, bundle)
                    print(f"  安装后版本: versionCode={new_vc}, versionName={new_vn}")
                    if new_vc != hap_vc:
                        print(f"  [错误] 安装后版本仍不匹配! 期望={hap_vc}, 实际={new_vc}", file=sys.stderr)
                        sys.exit(1)
                    print("  [OK] 版本校验通过")
                    if login_scenario and login_scenario_dir:
                        if not _run_login_script(login_scenario_dir, login_scenario):
                            print("  [错误] 登录预制失败, 请检查脚本或手动登录后重试", file=sys.stderr)
                            sys.exit(1)
                    else:
                        print("\n  [重要] 应用已更新, 请在设备上完成以下操作后再继续:")
                        print("  1. 打开应用  2. 完成登录  3. 确保应用处于正常使用状态\n")
                        prompt_confirm("  登录完成后, 按 Enter 继续... ", yes)
                else:
                    print("  [OK] 版本校验通过, 无需重新安装")
            else:
                print(f"  [警告] 无法从 HAP 文件提取版本号, 跳过版本校验")
        return

    # Not installed — need to install
    print(f"  应用未安装: {bundle}")
    if hap_path:
        print(f"  安装 {hap_path} ...")
        hap_abs = os.path.abspath(hap_path)
        result = runner.run([runner.hdc, "install", hap_abs], env=hdc_env())
        if result.returncode != 0:
            print(f"  [错误] 安装失败: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        # Verify
        new_vc, new_vn = _get_device_version(runner, bundle)
        hap_vc, hap_vn, _ = _get_hap_info(hap_path)
        if hap_vc and new_vc != hap_vc:
            print(f"  [错误] 安装后版本不匹配! 期望={hap_vc}, 实际={new_vc}", file=sys.stderr)
            sys.exit(1)
        print(f"  安装成功 (versionCode={new_vc}, versionName={new_vn})")
        if login_scenario and login_scenario_dir:
            if not _run_login_script(login_scenario_dir, login_scenario):
                print("  [错误] 登录预制失败, 请检查脚本或手动登录后重试", file=sys.stderr)
                sys.exit(1)
        else:
            print("\n  [重要] 应用已安装, 请在设备上完成以下操作后再继续:")
            print("  1. 打开应用  2. 完成登录  3. 确保应用处于正常使用状态\n")
            prompt_confirm("  登录完成后, 按 Enter 继续... ", yes)
    else:
        print("  [错误] 应用未安装且未指定 --hap 安装包路径", file=sys.stderr)
        print(f"  请: python {sys.argv[0]} --hap /path/to/app.hap ... 或手动安装后重跑",
              file=sys.stderr)
        sys.exit(1)


def _estimate_scenario_duration(scenario_dir: str, scenario_name: str = "") -> int:
    """估算场景复现耗时 (秒), 用于自动调整 htrace 采集时长。

    策略 (优先级从高到低):
      1. 从上次 xdevice 报告读取实际执行耗时 (最准确, 须匹配 scenario_name)
      2. 无历史报告时, 使用保守默认值
    """

    # 策略 1: 从上次 xdevice 报告获取实际耗时
    reports_dir = Path(scenario_dir) / "reports"
    if reports_dir.exists():
        report_dirs = sorted(
            [d for d in reports_dir.iterdir() if d.is_dir()],
            key=lambda d: d.name,
            reverse=True,
        )
        scenario_lower = scenario_name.lower() if scenario_name else ""
        for rdir in report_dirs:
            report_file = rdir / "report_data.json"
            if report_file.exists():
                try:
                    with open(report_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    # 取模块的实际执行时间 (秒), 须匹配 scenario_name
                    for module in data.get("modules", []):
                        module_name = module.get("name", "")
                        if scenario_lower and scenario_lower not in module_name.lower():
                            continue
                        exec_time = module.get("time")  # float, 秒
                        if exec_time and exec_time > 0:
                            estimated = int(exec_time)
                            print(f"  [估算] 从历史报告读取场景耗时: {exec_time:.0f}s = {estimated}s"
                                  f" (来源: {report_file.relative_to(scenario_dir)})")
                            return estimated
                except Exception:
                    pass  # 解析失败, 回退默认值

    # 策略 2: 保守默认值 (覆盖大多数场景: 初始化 + 固定步骤 + 滑动 + 等待)
    default_duration = 120
    print(f"  [估算] 无历史报告, 使用保守默认值: {default_duration}s")
    return default_duration


def _launch_scenario_replay(scenario_dir: str, scenario_name: str
                            ) -> subprocess.Popen | None:
    """后台启动场景复现 (通过外部 Hypium 工程的 main.py)。

    场景模式下由 Hypium 脚本负责拉起应用, collect.py 不执行 aa start。
    场景的具体参数 (滑动次数/间隔/等待时长等) 由 Hypium 工程自身的默认值决定,
    collect.py 只负责触发脚本, 不关心场景内部逻辑。
    执行结果由 xdevice 写入 <scenario_dir>/reports/<timestamp>/,
    _check_scenario_result 从该目录读取 report_data.json 判断成败。

    Args:
        scenario_dir: Hypium 工程根目录 (含 main.py)
        scenario_name: xdevice 测试用例名 (如 MyappScenarioReplay)

    返回 Popen 实例 (调用方需 wait), 失败返回 None。
    """
    main_py = Path(scenario_dir) / "main.py"
    if not main_py.exists():
        print(f"  [警告] 场景复现入口不存在: {main_py}")
        return None
    cmd = [
        sys.executable, str(main_py),
        scenario_name,
    ]
    print(f"  启动场景复现: {scenario_name}")
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT,
                                text=True, cwd=str(main_py.parent))
        return proc
    except Exception as e:
        print(f"  [警告] 场景复现启动失败: {e}")
        return None


def _check_scenario_result(scenario_dir: str, scenario_name: str,
                           scenario_start_time: float) -> tuple[bool, str]:
    """解析 xdevice report_data.json 判断场景执行是否成功。

    在 scenario_dir/reports/ 下查找本次场景对应的报告:
      1. 目录时间戳 >= scenario_start_time (排除历史报告)
      2. 报告中包含与 scenario_name 匹配的 module (排除其他场景的报告)

    判断逻辑:
      - summary.failed == 0 且匹配 module 的 cases 全部 Passed → 成功
      - 否则 → 失败，返回失败步骤详情

    Args:
        scenario_dir: Hypium 工程根目录
        scenario_name: 场景名 (如 Myapp)
        scenario_start_time: 场景启动时的 time.time() 时间戳, 用于过滤报告目录

    Returns:
        (is_passed, detail_msg): is_passed=True 表示全部通过; detail_msg 包含失败步骤详情
    """
    reports_dir = Path(scenario_dir) / "reports"
    if not reports_dir.exists():
        return False, f"未找到 xdevice 报告目录: {reports_dir}"

    # xdevice 报告目录格式: YYYY-MM-DD-HH-MM-SS, 转为时间戳用于比较
    def _dir_timestamp(d: Path) -> float | None:
        try:
            return datetime.strptime(d.name, "%Y-%m-%d-%H-%M-%S").timestamp()
        except ValueError:
            return None

    # 找 scenario_start_time 之后的报告目录 (按时间倒序, 取最新的匹配)
    candidate_dirs = sorted(
        [d for d in reports_dir.iterdir() if d.is_dir()],
        key=lambda d: _dir_timestamp(d) or 0,
        reverse=True,
    )
    # 过滤: 只保留启动时间之后的目录 (留 5s 容差, 因为 xdevice 创建目录略晚于进程启动)
    recent_dirs = [d for d in candidate_dirs
                   if (_dir_timestamp(d) or 0) >= scenario_start_time - 5]

    if not recent_dirs:
        # 无新目录: 可能是本机与设备时钟偏移, 检查最新目录是否在 120s 内
        # 超过 120s 的旧报告不应被回退采纳
        if candidate_dirs:
            latest_ts = _dir_timestamp(candidate_dirs[0]) or 0
            if latest_ts >= scenario_start_time - 120:
                recent_dirs = [candidate_dirs[0]]
        if not recent_dirs:
            return False, (f"reports 目录下无场景启动后的新报告 "
                           f"(启动时间: {scenario_start_time}, "
                           f"最新报告目录: {candidate_dirs[0].name if candidate_dirs else '无'})")

    # 场景名 → module 名匹配: "Myapp" 匹配 "MyappScenarioReplay" 等
    scenario_lower = scenario_name.lower()

    for rdir in recent_dirs:
        report_file = rdir / "report_data.json"
        if not report_file.exists():
            continue
        try:
            with open(report_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            continue

        # 查找与当前场景匹配的 module
        matched_modules = []
        for module in data.get("modules", []):
            module_name = module.get("name", "").lower()
            if scenario_lower in module_name:
                matched_modules.append(module)

        if not matched_modules:
            continue  # 这个报告不包含当前场景, 跳过

        # 基于匹配的 module 判断结果
        total_passed = sum(m.get("passed", 0) for m in matched_modules)
        total_failed = sum(m.get("failed", 0) for m in matched_modules)

        if total_failed == 0 and total_passed > 0:
            return True, (f"场景 {scenario_name}: 全部 {total_passed} 个测试用例通过 "
                          f"(来源: {report_file.relative_to(scenario_dir)})")

        # 有失败 → 收集失败详情
        failed_details = []
        for module in matched_modules:
            for suite in module.get("suites", []):
                for case in suite.get("cases", []):
                    if case.get("result") != "Passed":
                        case_name = case.get("name", "未知")
                        case_error = case.get("error", "")
                        failed_steps = []
                        for step in case.get("steps", []):
                            step_name = step.get("name", "未知步骤")
                            step_error = step.get("error", "")
                            step_completed = step.get("completed", "true")
                            if step_completed != "true" or step_error:
                                failed_steps.append(
                                    f"  - {step_name}: completed={step_completed}"
                                    + (f", error={step_error}" if step_error else "")
                                )
                        detail = f"用例 {case_name}: result={case.get('result', '未知')}"
                        if case_error:
                            detail += f", error={case_error}"
                        if failed_steps:
                            detail += "\n" + "\n".join(failed_steps)
                        failed_details.append(detail)

        msg = f"场景 {scenario_name} 测试失败! passed={total_passed}, failed={total_failed}"
        msg += f"\n报告路径: {report_file}"
        if failed_details:
            msg += "\n失败详情:\n" + "\n".join(failed_details)
        return False, msg

    # 遍历了所有新目录都没找到匹配场景的 module
    return False, (f"在 reports/ 下未找到场景 '{scenario_name}' 对应的报告 "
                   f"(已检查 {len(recent_dirs)} 个目录, 启动时间: {scenario_start_time})")


def phase_kill_and_htrace(runner: CmdRunner, process_name: str, bundle: str,
                          ability: str, app_label: str, duration: int,
                          output_dir: Path, yes: bool,
                          scenario: str = "", scenario_dir: str = ""
                          ) -> tuple[str | None, str, str, bool]:
    print("\n===============================================\n  Phase 2: 杀死应用 + 启动 htrace\n===============================================")
    pid = find_pid(runner, process_name)
    if pid:
        print(f"  杀死进程 {process_name} (PID={pid})...")
        runner.run_on_device(["aa", "force-stop", bundle])
        time.sleep(2)
        pid = find_pid(runner, process_name)
        if pid:
            print("  [警告] 进程仍存在, 尝试 kill -9...")
            runner.run_on_device(["kill", "-9", pid])
            time.sleep(2)
    print("  应用已停止\n")
    print(f"  启动 htrace 采集 (冷启动, startup_mode=true, {duration}s)...")
    print("  插件: nativehook (详细模式)  restrace_tag: DMA/FD/ArkTS/JS/GPU\n")

    runner.run_on_device(["mkdir", "-p", DEVICE_TMP])
    remote_file = f"{DEVICE_TMP}/{app_label}_{duration}s.htrace"
    local_file = str(output_dir / f"{app_label}_{duration}s.htrace")
    print("  清理设备端残留文件...")
    runner.run_on_device(["rm", "-f", remote_file])
    # split_file: true 时旧拆分文件名含时间戳, 需通配清理
    runner.run_on_device(["sh", "-c", f"rm -f {DEVICE_TMP}/{app_label}_{duration}s_*.htrace"])

    print(f"\n  ! htrace 采集即将开始，时长 {duration}s")
    print("  ⚠️ 操作时机（关键）：")
    print("    冷启动：应用拉起后请立即开始复现问题/执行目标操作！")
    print("    运行态：profiler 启动后立即开始操作/复现问题！")
    print(f"    整个采集期间（{duration}s）请持续操作目标场景。\n")
    if scenario:
        print(f"  场景复现已启用 ({scenario}), 采集期间自动执行场景操作\n")
    else:
        print("  采集开始后请立即开始复现问题/执行目标操作！\n")

    # 冷启动: profiler 后台启动 → 3s 后拉起应用捕获启动期分配 → wait 至 duration 结束
    config_text = NATIVEHOOK_CONFIG.replace("{process_name}", process_name)
    config_remote = f"{DEVICE_TMP}/htrace_config.txt"
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
        f.write(config_text)
        config_local = f.name
    runner.push_to_device(config_local, config_remote)
    os.unlink(config_local)

    print("  ! 冷启动采集: profiler 先启动, 3s 后拉起应用捕获启动期分配")
    if scenario:
        print(f"  场景复现 ({scenario}) 将在应用拉起后自动执行\n")
    else:
        print("  !!! 应用拉起后请立即开始复现问题/执行目标操作！ !!!\n")
    
    # 分步执行（替代 sh -c '& wait' 模式，避免 wait 无限挂起）:
    #   1. 后台启动 hiprofiler_cmd（nohup + &）
    #   2. sleep 3 后拉起应用
    #   3. 等待采集时长 + 缓冲 → 清理残留进程 → 校验 htrace 文件
    start_cmd = (
        f"nohup {runner.hiprofiler_cmd} -c {config_remote} "
        f"-o {remote_file} -t {duration} -s -k > /dev/null 2>&1 &"
    )
    runner.run_on_device([start_cmd], timeout=10)
    print("  hiprofiler_cmd 已后台启动")
    # 验证 hiprofiler_cmd 进程是否真正运行，避免静默失败导致空等整个 duration
    time.sleep(2)
    r = runner.run_on_device(["ps", "-elf"])
    if "hiprofiler_cmd" not in (r.stdout or ""):
        print("  [错误] hiprofiler_cmd 启动后未检测到进程，可能路径错误或权限不足")
        print(f"  请检查: hdc shell ls -la {runner.hiprofiler_cmd}")
        return None, remote_file, local_file, True
    print("  hiprofiler_cmd 进程已确认运行")
    # 清空 hilog 缓冲区，确保后续 dump 只含本次场景日志（供 ArkWeb 案例匹配使用）
    runner.run_on_device(["hilog", "-r"])
    print("  hilog 缓冲区已清空")
    # 冷启动: 拉起应用捕获启动期分配
    time.sleep(1)
    if not scenario:
        runner.run_on_device(["aa", "start", "-a", ability, "-b", bundle])
        print(f"  应用已拉起 ({ability})")

    # 场景复现: 后台启动 (由 Hypium 脚本管理应用启停)
    scenario_proc = None
    scenario_passed = True  # 默认通过; 无场景时无影响
    scenario_start_time = 0.0
    if scenario:
        scenario_start_time = time.time()
        scenario_proc = _launch_scenario_replay(scenario_dir, scenario)

    # 等待采集时长结束, trace 停止后立即采集瞬时数据
    print(f"  采集中... 等待 {duration}s")
    time.sleep(duration)

    # 等待场景复现脚本完成
    if scenario_proc is not None:
        print("  等待场景复现脚本完成...")
        try:
            scenario_proc.wait(timeout=180)
            if scenario_proc.returncode == 0:
                print("  [完成] 场景复现进程已退出 (exit code=0)")
            else:
                print(f"  [警告] 场景复现退出码: {scenario_proc.returncode}")
        except subprocess.TimeoutExpired:
            scenario_proc.kill()
            print("  [警告] 场景复现超时 (>180s), 已终止")

        # 解析 xdevice report_data.json 判断场景执行结果
        if scenario_dir:
            scenario_passed, result_msg = _check_scenario_result(
                scenario_dir, scenario, scenario_start_time)
            if scenario_passed:
                print(f"  [通过] {result_msg}")
            else:
                print(f"\n  [失败] {result_msg}")

    pid = find_pid(runner, process_name)
    if not pid:
        print(f"  [警告] 采集后未找到 {process_name} 进程, 后续瞬时数据将跳过")
    else:
        print(f"  应用进程 PID: {pid}")
    return pid, remote_file, local_file, scenario_passed


def phase_instant_data(runner: CmdRunner, pid: str, process_name: str, output_dir: Path) -> None:
    print("\n===============================================\n  Phase 3: 采集瞬时数据 (调用 dump_mem.py, 标准输出结构)\n===============================================")
    dump_mem_script = SCRIPT_DIR / "dump_mem.py"
    try:
        subprocess.run(
            [sys.executable, str(dump_mem_script), process_name, "默认场景", str(output_dir)],
            check=True,
            timeout=300,
        )
    except subprocess.TimeoutExpired:
        print("  [错误] dump_mem.py 执行超时 (>300s)，设备可能无响应")
        print("  跳过瞬时数据采集，继续后续阶段")
        return
    print("  [完成] 瞬时数据采集完成")


def _validate_heapsnapshot(filepath: str) -> tuple[bool, str]:
    """校验 heapsnapshot 文件完整性。返回 (是否完整, 原因说明)。"""
    p = Path(filepath)
    if not p.exists() or p.stat().st_size == 0:
        return False, "文件不存在或大小为0"
    size_mb = p.stat().st_size / 1048576
    # 读取文件末尾检查 JSON 是否完整闭合
    with open(p, "rb") as f:
        f.seek(0, 2)
        total = f.tell()
        tail_size = min(4096, total)
        f.seek(total - tail_size)
        tail = f.read(tail_size).decode("utf-8", errors="replace").strip()
    if not tail.endswith("}"):
        return False, f"文件末尾非 '}}' 闭合 (末尾: ...{tail[-50:]}), JSON 截断"
    return True, f"校验通过 ({size_mb:.1f}MB, JSON 闭合完整)"


def _get_device_file_size(runner: CmdRunner, remote_path: str) -> int:
    """获取设备端文件大小(字节), 文件不存在返回 -1。"""
    r = runner.run_on_device(["ls", "-l", remote_path])
    parts = (r.stdout or "").split()
    # ls -l: perms links owner group SIZE date time filename
    if len(parts) >= 5:
        try:
            return int(parts[4])
        except ValueError:
            pass
    return -1


def _trigger_and_pull_heap(runner: CmdRunner, pid: str, heap_local_dir: Path,
                            max_retry: int = 40) -> bool:
    """触发 hidumper --mem-jsheap 并轮询拉取快照。

    关键: hidumper 发出 dump 指令后, 目标进程异步写文件, 文件在 ls 中出现时
    可能尚未写完。必须等文件大小稳定(连续2次相同)后再拉取, 否则拉到截断 JSON。
    截断后不删设备端文件(dump 是一次性操作, 删了不会重新生成), 而是等待后重新拉取。
    """
    runner.run_on_device(["rm", "-f", f"{HEAP_REMOTE_DIR}/hidumper-jsheap-*"])
    print(f"  采集主线程 heapsnapshot (hidumper --mem-jsheap {pid} -T {pid})...")
    runner.run_on_device(["hidumper", "--mem-jsheap", pid, "-T", pid], timeout=600)

    prev_size = -1
    stable_checks = 0
    for i in range(max_retry):
        time.sleep(6)
        r = runner.run_on_device(["ls", HEAP_REMOTE_DIR])
        files = [ln.strip() for ln in (r.stdout or "").splitlines()
                 if "hidumper-jsheap" in ln and pid in ln]
        if not files:
            if i < max_retry - 1:
                print(f"  [重试] heapsnapshot 尚未落盘, {i + 1}/{max_retry}, 等待中... (大堆快照需1-2分钟)")
            continue

        fname = files[0]
        remote_path = f"{HEAP_REMOTE_DIR}/{fname}"
        cur_size = _get_device_file_size(runner, remote_path)
        if cur_size < 0:
            if i < max_retry - 1:
                print(f"  [重试] 文件存在但无法读取大小, {i + 1}/{max_retry}")
            continue

        size_mb = cur_size / 1048576

        if cur_size != prev_size:
            prev_size = cur_size
            stable_checks = 0
            print(f"  文件写入中: {fname} ({size_mb:.1f}MB), 等待落盘完成... ({i + 1}/{max_retry})")
            continue

        stable_checks += 1
        if stable_checks < 2:
            print(f"  文件大小未变 ({size_mb:.1f}MB), 再确认一次 ({stable_checks}/2)...")
            continue

        print(f"  文件大小稳定 ({size_mb:.1f}MB), 开始拉取: {fname}")
        local_path = str(heap_local_dir / fname)
        runner.pull_from_device(remote_path, local_path)

        ok, msg = _validate_heapsnapshot(local_path)
        print(f"  [校验] {msg}")
        if ok:
            return True

        print(f"  [警告] 文件大小稳定但 JSON 不完整, 可能慢写或损坏, 等待后重新拉取...")
        Path(local_path).unlink(missing_ok=True)
        prev_size = -1
        stable_checks = 0

    return False


def phase_heapsnapshot(runner: CmdRunner, pid: str, ability: str, bundle: str,
                       process_name: str, output_dir: Path, yes: bool) -> None:
    print("\n===============================================\n  Phase 4: 采集 heapsnapshot\n===============================================")
    print(f"  进程 PID: {pid}")
    heap_local_dir = output_dir / "heapsnapshot"
    heap_local_dir.mkdir(parents=True, exist_ok=True)

    runner.run_on_device(["aa", "start", "-a", ability, "-b", bundle])
    print(f"  应用已拉起 ({ability})")
    pulled = _trigger_and_pull_heap(runner, pid, heap_local_dir, max_retry=40)
    if pulled:
        print("  [完成] heapsnapshot 采集完成 (校验通过)")
    else:
        print(f"\n  [错误] heapsnapshot 采集失败 (PID={pid} 一直未落盘)")
        print(f"  请手动检查: hdc shell \"ls -la {HEAP_REMOTE_DIR}\"")
        print(f"  手动采集: hdc shell \"hidumper --mem-jsheap {pid} -T {pid}\"")


def phase_pull(runner: CmdRunner, remote_file: str, local_file: str) -> None:
    print("\n===============================================\n  Phase 5: 拉取 htrace 及其余产物\n===============================================")
    print("  拉取 htrace 文件...")

    # split_file: true 时 hiprofiler 生成带时间戳的拆分文件, 名称格式:
    #   {base}_{timestamp}_{N}.htrace (如 hmapp_14.8.10_120s_20261008_211932_1.htrace)
    # 需先列出设备上匹配的拆分文件, 逐个拉取并重命名为 {base}_{N}.htrace
    import glob
    remote_dir = Path(remote_file).parent.as_posix()  # as_posix: Windows backslash -> forward slash for device
    remote_base = Path(remote_file).stem  # e.g. hmapp_14.8.10_120s
    local_dir = str(Path(local_file).parent)

    r = runner.run_on_device(["ls", remote_dir])
    split_files = []
    single_file = remote_file
    for line in (r.stdout or "").splitlines():
        line = line.strip()
        if line.startswith(remote_base) and line.endswith(".htrace"):
            if line == f"{remote_base}.htrace":
                single_file = f"{remote_dir}/{line}"
            elif f"{remote_base}_" in line:
                split_files.append(f"{remote_dir}/{line}")

    if split_files:
        split_files.sort()
        total_mb = 0
        for idx, rf in enumerate(split_files, 1):
            lf = str(Path(local_file).with_name(f"{remote_base}_{idx}.htrace"))
            print(f"  拉取拆分文件 {idx}/{len(split_files)}: {Path(rf).name}")
            runner.pull_from_device(rf, lf)
            lp = Path(lf)
            if lp.exists():
                size_mb = lp.stat().st_size / 1048576
                total_mb += size_mb
                if size_mb < 10:
                    print(f"  [警告] {lp.name}: {size_mb:.2f} MB (< 10MB), 可能采集异常")
                else:
                    print(f"  {lp.name}: {size_mb:.2f} MB")
            else:
                print(f"  [错误] 拉取失败: {lp.name}")
        print(f"  htrace 总大小: {total_mb:.2f} MB ({len(split_files)} 个拆分文件)")
    else:
        runner.pull_from_device(single_file, local_file)
        local_path = Path(local_file)
        if not local_path.exists():
            print("  [错误] htrace 文件拉取失败，本地文件不存在")
        else:
            size_mb = local_path.stat().st_size / 1048576
            if size_mb == 0:
                print("  [错误] htrace 文件大小为 0，采集失败或传输中断")
            elif size_mb < 10:
                print(f"  [警告] htrace 文件仅 {size_mb:.2f} MB (< 10MB), 可能采集异常")
            else:
                print(f"  {local_file}: {size_mb:.2f} MB")
    print("  [完成] 所有产物已拉取")


def _save_collection_meta(output_dir: Path, args, duration: int) -> None:
    """保存采集参数到 collection_meta.json, 供跨版本参数一致性校验。"""
    import datetime
    meta = {
        "version_tag": args.version_tag,
        "bundle": args.app,
        "ability": args.ability or "",
        "process": args.process or args.app,
        "duration": duration,
        "scenario": args.scenario or "",
        "scenario_dir": args.scenario_dir or "",
        "login_scenario": args.login_scenario or "",
        "login_scenario_dir": args.login_scenario_dir or "",
        "collection_mode": "scenario" if args.scenario else "manual",
        "timestamp": datetime.datetime.now().isoformat(),
    }
    meta_path = output_dir / "collection_meta.json"
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
    print(f"  采集参数已保存: {meta_path}")


def main() -> int:
    ap = argparse.ArgumentParser(
        description="应用 HTrace 数据采集 (Python 实现, 复用 CmdRunner)",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("version_tag", help="版本标签 (v1/v2/old/new)")
    ap.add_argument("duration", nargs="?", type=int, default=60, help="htrace 采集时长(秒), 默认 60")
    ap.add_argument("--app", required=True, help="目标应用 bundle 名 (如 com.dragon.read.next)")
    ap.add_argument("--ability", help="ABILITY_NAME (如 MainAbility; 未提供时从 HAP 或设备自动提取)")
    ap.add_argument("--process", help="覆盖 PROCESS_NAME (默认同 bundle)")
    ap.add_argument("--label", help="覆盖 APP_LABEL (默认 <app>_<tag>)")
    ap.add_argument("--output-base", help="输出基目录 (默认 ./output, 相对当前运行目录)")
    ap.add_argument("--yes", action="store_true",
                    help="跳过交互确认 (AI 非交互调用须传, 前提: 调用方已与用户确认)")
    ap.add_argument("--hap", default="", help="HAP 安装包路径 (用于安装 + 版本校验)")
    ap.add_argument("--scenario", default="", help="场景复现名称 (如 Myapp), 采集期间自动执行替代手工操作")
    ap.add_argument("--scenario-dir", default="", help="Hypium 工程根目录路径 (含 main.py), 配合 --scenario 使用")
    ap.add_argument("--login-scenario", default="", help="登录预制用例名 (如 MyappPrerequisiteSetup), 安装后自动执行替代人工登录")
    ap.add_argument("--login-scenario-dir", default="", help="登录预制 Hypium 工程根目录 (含 main.py), 配合 --login-scenario 使用")
    args = ap.parse_args()

    # bundle 来源优先级: HAP 内 bundleName > --app 参数
    bundle = ""
    if args.hap:
        _, _, hap_bundle = _get_hap_info(args.hap)
        if hap_bundle:
            bundle = hap_bundle
            print(f"  从 HAP 提取 bundleName: {bundle}")
    if not bundle:
        bundle = args.app

    # runner 提前创建（ability 设备查询需要）
    runner = CmdRunner(hdc=os.environ.get("HDC_PATH") or find_hdc())
    missing = runner.check_prerequisites(require_hdc=True)
    if missing:
        print("[错误] 前置工具缺失:", file=sys.stderr)
        for m in missing:
            print(m, file=sys.stderr)
        return 1

    # ability 来源优先级: --ability 参数 > HAP 内提取 > 设备 bm dump 查询
    ability = args.ability or ""
    if not ability and args.hap:
        ability = _get_ability_from_hap(args.hap)
        if ability:
            print(f"  从 HAP 提取 ability: {ability}")
    if not ability:
        # 尝试从设备查询已安装应用的 ability
        ability = _get_ability_from_device(runner, bundle)
        if ability:
            print(f"  从设备查询到 ability: {ability}")
        else:
            print("[错误] 未指定 ability 名称，且无法从设备自动获取（应用未安装或解析失败）。", file=sys.stderr)
            print("  请通过 --ability 提供 (如 MainAbility)，或通过 --hap 从安装包自动提取", file=sys.stderr)
            return 1

    process = args.process or bundle
    # app_label: 用 bundle 的最后一段作为标签前缀
    # 有 --scenario 时追加场景名，便于区分不同场景的采集产物
    _label_prefix = bundle.rsplit(".", 1)[-1] if "." in bundle else bundle
    app_label = f"{_label_prefix}_{args.version_tag}"
    if args.scenario:
        app_label = f"{app_label}_{args.scenario}"
    if args.label:
        app_label = args.label
    output_dir = Path(args.output_base or "./output") / app_label
    output_dir.mkdir(parents=True, exist_ok=True)

    # 场景复现校验
    if args.scenario and not args.scenario_dir:
        print("[错误] 使用 --scenario 时必须同时指定 --scenario-dir (Hypium 工程根目录)", file=sys.stderr)
        return 1

    # --scenario / --login-scenario 模式需要 hypium (手动操作模式不需要)
    if args.scenario or args.login_scenario:
        try:
            __import__("hypium")
        except ImportError:
            print("[错误] --scenario / --login-scenario 自动场景复现需要 hypium, 但未安装", file=sys.stderr)
            print("  安装: pip install hypium -i https://mirrors.huaweicloud.com/repository/pypi/simple", file=sys.stderr)
            print("  或使用手动操作模式 (不传 --scenario, 采集期间自行操作设备)", file=sys.stderr)
            return 1

    # 场景复现时自动调整 htrace 采集时长: 确保覆盖完整场景操作
    duration = args.duration
    if args.scenario:
        estimated = _estimate_scenario_duration(args.scenario_dir, args.scenario)
        if duration < estimated:
            print(f"  [自动调整] htrace 采集时长 {duration}s < 场景预估耗时 {estimated}s, 调整为 {estimated}s")
            duration = estimated

    print("===============================================\n  应用 HTrace 数据采集")
    print(f"  版本标签: {args.version_tag}\n  Bundle:   {bundle}\n  Ability:  {ability}")
    print(f"  Process:  {process}\n  时长:     {duration}s\n  输出目录: {output_dir}")
    if args.scenario:
        print(f"  场景复现: {args.scenario} (工程: {args.scenario_dir})")
    print("===============================================")

    phase_install_check(runner, bundle, args.yes, hap_path=args.hap,
                        login_scenario=args.login_scenario, login_scenario_dir=args.login_scenario_dir)

    print("\n  即将开始应用内存数据采集，步骤:")
    print("  1. 杀死应用  2. 重启应用  3. 启动 htrace (nativehook, startup_mode=true 冷启动)")
    print("  4. 采集 showmap/smaps/heapsnapshot/hilog/窗口dump  5. 拉取 htrace 及其余产物\n  请确保应用已登录并处于正常使用状态\n")
    prompt_confirm("  准备好了？按 Enter 开始采集... ", args.yes)

    max_attempts = 2  # 初始采集 + 1 次自动重试
    for attempt in range(1, max_attempts + 1):
        if attempt > 1:
            print(f"\n===============================================\n  第 {attempt} 次采集尝试 (上次校验失败)\n===============================================")
            shutil.rmtree(output_dir, ignore_errors=True)
            output_dir.mkdir(parents=True, exist_ok=True)
            if not args.yes:
                prompt_confirm("  校验失败, 按 Enter 重新采集... ", args.yes)

        pid, remote_file, local_file, scenario_passed = phase_kill_and_htrace(
            runner, process, bundle, ability, app_label, duration, output_dir, args.yes,
            scenario=args.scenario, scenario_dir=args.scenario_dir)

        if not pid:
            print(f"\n  [警告] Phase 2 后未找到 {process} 进程, 尝试重新拉起应用...")
            runner.run_on_device(["aa", "start", "-a", ability, "-b", bundle])
            time.sleep(10)
            pid = find_pid(runner, process)
        if pid:
            phase_instant_data(runner, pid, process, output_dir)
        else:
            print("\n  [警告] 重新拉起后仍无 PID, 跳过 Phase 3/4 (瞬时数据 + heapsnapshot)")

        # Phase 3 完成后, 先等待 hiprofiler_cmd 刷完缓冲并退出, 释放 nativehook 钩子.
        # 必须在 Phase 4 (heapsnapshot) 之前完成: hidumper --mem-jsheap 在 nativehook
        # 钩子仍挂载时会无法落盘 (180s trace 产生 2.7GB 缓冲, 刷缓冲可达 600s+).
        # 瞬时数据(showmap/smaps)已在 Phase 3 捕获 post-scenario 内存状态, 此处仅等 profiler 退出.
        print("\n  等待 hiprofiler_cmd 刷缓冲完成 (释放 nativehook 钩子, 为 heapsnapshot 让路)...")
        max_flush_wait = 600
        flush_waited = 0
        while flush_waited < max_flush_wait:
            time.sleep(10)
            flush_waited += 10
            r = runner.run_on_device(["ps", "-elf"])
            if "hiprofiler_cmd" not in (r.stdout or ""):
                print(f"  hiprofiler_cmd 已自然退出 (等待 {flush_waited}s)")
                break
            print(f"  hiprofiler_cmd 仍在刷缓冲 ({flush_waited}s)...")
        else:
            print(f"  [警告] hiprofiler_cmd 刷缓冲超时 (>{max_flush_wait}s)")

        # 无论自然退出还是超时, 都要强杀全部 profiler 进程, 确保 nativehook 钩子释放.
        # nativehook 钩子由 native_daemon 注入目标进程, 仅杀 hiprofiler_cmd 不释放钩子:
        #   - 自然退出时 -k 会杀 daemons, 但可能不干净/有延迟
        #   - 超时强杀 hiprofiler_cmd 不走 -k 路径, daemons 残留, 钩子持续阻塞 hidumper --mem-jsheap
        # 统一 killall -9 全部 profiler 进程, 否则 Phase 4 heapsnapshot 必然失败.
        runner.run_on_device(
            ["killall", "-9", "hiprofiler_cmd", "hiprofilerd",
             "hiprofiler_plugins", "native_daemon"],
            timeout=10,
        )
        time.sleep(3)
        runner.run_on_device(["rm", "-f", f"{DEVICE_TMP}/htrace_config.txt"])

        # Phase 4: 所有 profiler 进程已清理, nativehook 钩子已释放, 现在采集 heapsnapshot
        if pid:
            phase_heapsnapshot(runner, pid, ability, bundle, process, output_dir, args.yes)

        phase_pull(runner, remote_file, local_file)

        # 场景执行失败提示
        if args.scenario and not scenario_passed:
            print("\n===============================================")
            print("  [重要] 场景复现测试未全部通过!")
            print("  采集到的数据可能不完整或不代表预期场景。")
            print("  请查看上方失败详情和 reports/ 下的 xdevice 报告。")
            print("===============================================")
            if not args.yes:
                choice = input("\n  请选择操作:\n    1) 重新采集 (推荐)\n    2) 继续使用当前数据\n  输入 1 或 2: ").strip()
                if choice == "1":
                    print("\n  将重新采集... 请确认应用状态后再次运行采集命令")
                    return 2
                else:
                    print("  继续使用当前数据...")
            else:
                print("\n  [提示] --yes 模式下无法交互选择。建议:")
                print("  1. 查看 xdevice 报告确认失败原因")
                print("  2. 修复问题后重新运行采集命令")
                print("  3. 如确认数据可用, 可继续后续分析")
                return 2

        # 采集产物完整性校验
        print("\n===============================================\n  产物完整性校验\n===============================================")
        ok, results = verify_products(output_dir)
        for r in results:
            status = "OK" if r["ok"] else "FAIL"
            print(f"  [{status}] {r['name']:14s} {r['detail']}")

        if ok:
            print("  [通过] 必需产物齐全")
            _save_collection_meta(output_dir, args, duration)
            print(f"\n===============================================\n  采集完成! 版本标签:", args.version_tag)
            return 0

        # 校验失败
        print(f"\n  [失败] 第 {attempt} 次采集校验未通过")
        for r in results:
            if not r["ok"]:
                print(f"    - {r['name']}: {r['detail']}")

        if attempt < max_attempts:
            print("\n  将删除不完整产物并重新采集...")
        else:
            print(f"\n  [错误] 重新采集后仍校验失败, 请排查环境问题")
            print(f"  产物目录: {output_dir}")
            print(f"  手动检查: python scripts/1_collection/verify_collection.py {output_dir}")
            return 3


if __name__ == "__main__":
    sys.exit(main())