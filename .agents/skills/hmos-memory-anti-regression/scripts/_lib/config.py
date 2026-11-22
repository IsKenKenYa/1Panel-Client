
import os
import sys
from enum import Enum
from pathlib import Path
from types import MappingProxyType

class TraceType(Enum):
    OTHER = -100
    GUARD = -8
    STACK = -7
    DEV = -6
    ANON_PAGE_OTHER = -5
    FILE_PAGE_OTHER = -4
    DB = -3
    HAP = -2
    TTF = -1
    NATIVE_HEAP = 0
    MMAP = 1
    FILE_PAGE_MSG = 2
    MEMORY_USING_MSG = 3
    FD = 4
    THREAD = 5
    GPU_VK = 6
    GPU_GLES = 7
    GPU_CL = 8
    SO_SIZE = 9
    ARKTS_HEAP = 10
    JS_HEAP = 11
    KMP_HEAP = 12
    RN_HEAP = 13
    ASHMEM = 14
    DMA = 15


DEFAULT_HTRACE_PATH = str((Path(__file__).parent / "trace" / "long_trace").absolute())
DEFAULT_TYPES = {
    TraceType.NATIVE_HEAP.value,
    TraceType.GPU_VK.value,
    TraceType.GPU_GLES.value,
    TraceType.GPU_CL.value,
    TraceType.SO_SIZE.value,
    TraceType.ARKTS_HEAP.value,
    TraceType.ASHMEM.value,
    TraceType.DMA.value
}

import platform

# 根据操作系统类型选择可执行文件
if platform.system() == "Windows":
    streamer_exe = "trace_streamer.exe"
else:
    streamer_exe = "trace_streamer"

ALL_CASES_DF = []

CATEGORY_MAPPING = {
    ".db": TraceType.DB.name,
    ".hap": TraceType.HAP.name,
    ".so": TraceType.SO_SIZE.name,
    ".ttf": TraceType.TTF.name,
    "AnonPage other": TraceType.ANON_PAGE_OTHER.name,
    "FilePage other": TraceType.FILE_PAGE_OTHER.name,
    "dev": TraceType.DEV.name,
    "guard": TraceType.GUARD.name,
    "stack": TraceType.STACK.name,
}


__DEFAULT_CONFIG_DATA = MappingProxyType({
    "DEFAULT_STREAMER_PATH": str(Path(__file__).parent.parent / "utils" / "trace2db" / streamer_exe),
    "process_config": str((Path(__file__).parent / "Process_config.json")),
    "so_dir": str((Path(__file__).parent.parent / "so").absolute()),
    "statics_dir": str((Path(__file__).parent / "statics").absolute()),
    "txt_size_output": r"./lib_size.txt",
    "txt_count_output": r"./lib_count.txt",
    "heading": False,
    "case": '',
    "htrace_dir": "",
    "output_path": "./output",
    "db_dir": "",
    "showmap": "",
    "proc_smaps": "",
    "startts": 0,
    "endts": 9223372036854775807,
    "type": list(DEFAULT_TYPES),
    "pid": -1,
    "detail": False,
    "detail_explicitly_set": False,
    "scene": "",
    "mm_dmabuf_file": "",
    "merge": None,
    "kinds": None,
    "outputFile": "",
    "trace": "",
    "limit": 0,
    "empty_service": 35,
    "hiprofiler_noise": 42,
    "arkts_empty_service": 10,
})

config_data = dict(__DEFAULT_CONFIG_DATA)

MAX_INT = 9223372036854775807
ANON_NAME = "[anon]"


class Config:
    def __init__(self, config_file: str | None = None):
        self._data = dict(__DEFAULT_CONFIG_DATA)
        self._data.update(config_data)
        if config_file and os.path.isfile(config_file):
            import json
            with open(config_file) as f:
                self._data.update(json.load(f))

    @property
    def hiprofiler_cmd(self) -> str:
        return self._data.get("hiprofiler_cmd", "hiprofiler_cmd")

    @property
    def trace_streamer(self) -> str:
        return self._data.get("DEFAULT_STREAMER_PATH", self._data["DEFAULT_STREAMER_PATH"])

    @property
    def hdc(self) -> str | None:
        return self._data.get("hdc")

    @property
    def output_dir(self) -> str:
        return self._data.get("output_dir", "./output")

    @output_dir.setter
    def output_dir(self, value: str):
        self._data["output_dir"] = value

    @property
    def default_duration(self) -> int:
        return self._data.get("default_duration", 10)

    @property
    def collect_timeout(self) -> int:
        return self._data.get("collect_timeout", 300)

    @property
    def so_dir(self) -> str:
        return self._data.get("so_dir", self._data.get("so_dir", "./so"))

    @property
    def process_config(self) -> str:
        return self._data.get("process_config", "")

    def set(self, key: str, value):
        self._data[key] = value

    def get(self, key: str, default=None):
        return self._data.get(key, default)