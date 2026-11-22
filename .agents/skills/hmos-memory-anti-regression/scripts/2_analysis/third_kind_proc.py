
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from config import config_data, TraceType
from analysis_utils import sort


# noinspection DuplicatedCode
def find_3rd_kind_field_proportion(res):
    field_proportion = {}
    total_size = 0
    for item in res:
        total_size += item['heap_size']
        if 'field' not in item.keys():
            continue
        field = (item['field']['firstkind'], item['field']['thirdkind'])
        so = item['field']['response_so']
        if so is None:
            so = "(未归因)"
        if field in field_proportion:
            field_proportion[field]["size"] += item['heap_size']
        else:
            field_proportion[field] = {"size": item['heap_size'], "so": {}}
        if so in field_proportion[field]["so"]:
            field_proportion[field]["so"][so]["size"] += item['heap_size']
        else:
            field_proportion[field]["so"][so] = {"size": item['heap_size'], "types": {}}
        field_proportion[field]["so"][so]["types"][item['type']] = field_proportion[field]["so"][so]["types"].get(item['type'], 0) + item['heap_size']

    for item in field_proportion:
        field_proportion[item]["ratio"] = field_proportion[item]["size"] / total_size
        field_proportion[item]["size"] = field_proportion[item]["size"] / 1024 / 1024
        for so in field_proportion[item]["so"]:
            field_proportion[item]["so"][so]["ratio"] = field_proportion[item]["so"][so]["size"] / total_size
            field_proportion[item]["so"][so]["size"] = field_proportion[item]["so"][so]["size"] / 1024 / 1024
            for _k, _v in field_proportion[item]["so"][so]["types"].items():
                field_proportion[item]["so"][so]["types"][_k] = _v / 1024 / 1024
    field_proportion = sort(field_proportion, "so")
    return field_proportion, total_size
