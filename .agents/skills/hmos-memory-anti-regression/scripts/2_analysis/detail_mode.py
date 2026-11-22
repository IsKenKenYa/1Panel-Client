
import sys
from pathlib import Path
import logging

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from tracedbs import query_native_hook
from callchain import OptimizedCallChain
from config import TraceType, config_data

logger = logging.getLogger(__name__)

EVENT_TYPE_MAPPING = {
    TraceType.NATIVE_HEAP: "AllocEvent",
    TraceType.ARKTS_HEAP: "ARKTS_HEAP_Alloc_Event",
    TraceType.GPU_CL: "GPU_CL_Alloc_Event",
    TraceType.GPU_VK: "GPU_VK_Alloc_Event",
    TraceType.GPU_GLES: "GPU_GLES_Alloc_Event",
    TraceType.ASHMEM: "ASHMEM_Alloc_Event",
    TraceType.DMA: "ION_Alloc_Event"
}
EVENT_TYPE_MAPPING_REVERSE = {v: k.name for k, v in EVENT_TYPE_MAPPING.items()}


# noinspection DuplicatedCode
def add_detail_data(_types: list[TraceType]):
    callchains = OptimizedCallChain()
    types_value = [_t.value for _t in _types]
    print(f"添加 {types_value} 数据")
    startts = config_data["startts"]
    endts = config_data["endts"]

    event_types = [EVENT_TYPE_MAPPING[_t] for _t in _types]
    detail_data_list = query_native_hook(
        config_data["htrace_dir"], event_types=event_types,
        startts=startts, endts=endts, aggregate=True)
    for data in detail_data_list:
        data["type"] = EVENT_TYPE_MAPPING_REVERSE[data["event_type"]]
        data["release_count"] = 0
        data["apply_size"] = data["heap_size"]
        data["release_size"] = 0
        callchains.append(data)
    return callchains