"""HTrace to SQLite database conversion module.

Provides htrace_to_sqlitedb() function for converting .htrace files
to .db SQLite databases via trace_streamer subprocess.
"""

import sys
from pathlib import Path
import logging
import os
import sqlite3
import subprocess

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "../2_analysis"))
from cmd_runner import CmdRunner

logger = logging.getLogger(__name__)


def _ensure_dir(path: str):
    Path(path).mkdir(parents=True, exist_ok=True)


def check_db_files_exist(target_file_path):
    try:
        files = os.listdir(target_file_path)
        return any(file.endswith('.db') for file in files)
    except FileNotFoundError:
        return False


def htrace_to_sqlitedb(
    htrace_path: str,
    output_dir: str,
    trace_streamer: str | None = None,
    so_dir: str | None = None,
    output_name: str | None = None,
    timeout: int = 1800,
    skip_existing: bool = False,
) -> str:
    htrace = Path(htrace_path)
    if not htrace.exists():
        raise FileNotFoundError(f"HTrace file not found: {htrace_path}")

    _ensure_dir(output_dir)

    db_name = output_name or f"{htrace.stem}.db"
    db_path = str(Path(output_dir) / db_name)

    if skip_existing and check_db_files_exist(db_path):
        logger.info("DB already exists, skipping conversion: %s", db_path)
        return db_path

    cmd_runner = CmdRunner(trace_streamer=trace_streamer, timeout=timeout)
    missing = cmd_runner.check_prerequisites(require_trace_streamer=True)
    if missing:
        raise FileNotFoundError(missing[0])

    cmd = [
        cmd_runner.trace_streamer,
        htrace_path,
        "-e", db_path,
    ]
    if so_dir:
        cmd.extend(["--So_dir", so_dir])

    logger.info("Converting htrace to SQLite: %s -> %s", htrace_path, db_path)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        logger.error("Conversion timed out after %ds: %s", timeout, htrace_path)
        raise
    except FileNotFoundError:
        logger.error("trace_streamer not found: %s", cmd_runner.trace_streamer)
        raise

    logger.info("trace_streamer stdout: %s", result.stdout)
    if result.stderr:
        logger.info("trace_streamer stderr: %s", result.stderr)

    if result.returncode != 0:
        logger.error("HTrace conversion failed (rc=%d): %s", result.returncode, result.stderr)
        raise RuntimeError(
            f"trace_streamer failed with return code {result.returncode}: {result.stderr}"
        )

    logger.info("HTrace converted to SQLite: %s", db_path)

    _create_indexes(db_path)

    return db_path


_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_nh_type_callchain_ipid ON native_hook_statistic(type, callchain_id, ipid)",
    "CREATE INDEX IF NOT EXISTS idx_nhf_callchain_id ON native_hook_frame(callchain_id)",
    "CREATE INDEX IF NOT EXISTS idx_process_ipid ON process(ipid)",
    "CREATE INDEX IF NOT EXISTS idx_native_hook_main ON native_hook(start_ts, end_ts, event_type, callchain_id)",
    "CREATE INDEX IF NOT EXISTS idx_native_hook_addr_heap ON native_hook(addr, heap_size)",
]


def _create_indexes(db_path: str):
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        for sql in _INDEXES:
            cur.execute(sql)
        conn.commit()
        conn.close()
    except Exception as e:
        logger.warning("Failed to create database indexes: %s: %s", type(e).__name__, e)
