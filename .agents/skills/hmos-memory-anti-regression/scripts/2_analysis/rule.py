
import sys
from pathlib import Path
import re
from collections import deque

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from callchain import OptimizedCallChain
from so_field import lookup
from config import config_data

excluded_rule = [
    re.compile(re.escape("/lib/libhmulibs.so.0.1")),
    re.compile(re.escape("/lib/libc-sys.so")),
    re.compile(re.escape("/lib/libdh-linux.so")),
    re.compile(re.escape("/lib/libdh-lnxbase.so.1.0")),
    re.compile(re.escape("/lib/libdh.so.0.1")),
    re.compile(re.escape("/system/lib64/module/arkcompiler/stub.an")),
    re.compile(re.escape("/system/lib64/platformsdk/libark_jsruntime.so")),
    re.compile(re.escape("/system/lib64/libark_jsoptimizer.so")),
    re.compile(re.escape("/system/etc/abc/framework/stateMgmt.abc")),
    re.compile(re.escape("/system/lib64/platformsdk/libace_napi.z.so")),
    re.compile(re.escape("/system/lib64/libc++.so")),
    re.compile(re.escape("/system/lib64/chipset-sdk-sp/libc++.so")),
    re.compile(re.escape("/system/lib64/libc++_shared.so")),
    re.compile(re.escape("/proc/.*/libs/arm64/libc++_shared.so")),
    re.compile(re.escape("/data/storage/el1/bundle/libs/arm64/libc++_shared.so")),
    re.compile(re.escape("/system/lib64/libdfmalloc.z.so")),
    re.compile(re.escape("/system/lib/ld-musl-aarch64.so.1")),
    re.compile(re.escape("/system/lib64/libnative_hook.z.so")),
    re.compile("/proc/.*/data/storage/ark-cache/arm64/phone_photos.an"),
    re.compile("/proc/.*/data/storage/.*/bundle/.*libappnative.so$"),
    re.compile(".*\\.elf"),
    re.compile(".*\\.ko"),
    re.compile("^/bin/.*"),
    re.compile("^/lib/.*"),
    re.compile("^/liblinux/.*")
]

WHITE_SO_NAMES = [
    "libarkweb_engine.so",
    "pdd_image_knife",
    "@amap/imageknife",
    "librnoh_semi.so",
    "libflutter.so",
    "libapp.so",
    "libALIPAYKMP.so",
    "libkntr.so",
    "libimageknifepro.so",
    "imageknife"
]


TS_PATTERN = re.compile(
    r'([^:]+):\[url:([^:|]+)\|([^|]+)\|([^:|]+)\|([^|\]]*):(\d+):(\d+)]$'
)
THIRD_ARKTS_FRAGMENT = [
    "@alipay/afservicesdk",
    "@amap/amap_lbs_common",
    "@amap/amap_lbs_location",
    "@cashier_alipay/cashiersdk",
    "@hw-agconnect/hmcore",
    "@hw-agconnect/ohos-apms",
    "@imagex/imagex_bdimageknife",
    "@imagex/imagex_gpu_transform",
    "@imagex/imagex_heifdecoder",
    "@netteam/prefetcher",
    "@ohos/axios",
    "@ohos/crypto-js",
    "@ohos/dataorm",
    "@ohos/gpu_transform",
    "@ohos/httpclient",
    "@ohos/imageknife",
    "@ohos/lottie",
    "@ohos/mmkv",
    "@ohos/pinyin4js",
    "@ohos/protobuf_format",
    "@ohos/protobufjs",
    "@ohos/retrofit",
    "@ohos/sax",
    "@ohos/xml_js",
    "@protobufjs/aspromise",
    "@protobufjs/base64",
    "@protobufjs/codegen",
    "@protobufjs/eventemitter",
    "@protobufjs/fetch",
    "@protobufjs/float",
    "@protobufjs/inquire",
    "@protobufjs/path",
    "@protobufjs/pool",
    "@protobufjs/utf8",
    "@react-native-oh-tpl/react-native-linear-gradient",
    "@rnoh/react-native-openharmony",
    "@tencent/libpag",
    "@tencent/qq-open-sdk",
    "@tencent/wechat_open_sdk",
    "@tencentcloud/cos",
    "@tencentmap/base",
    "@tencentmap/location_sdk",
    "@tencentmap/map",
    "@wolfx/json5",
    "@wolfx/lodash",
    "base64-js",
    "bignumber.js",
    "class-transformer",
    "dayjs",
    "eventemitter3",
    "iconfont",
    "json-bigint",
    "js-sha256",
    "lodash",
    "long",
    "pako",
    "protobufjs",
    "reflect-metadata",
    "rxjs",
    "tslib",
    "axios",
    "crypto-js",
    "dataorm",
    "gpu_transform",
    "httpclient",
    "imageknife",
    "lottie",
    "mmkv",
    "pinyin4js",
    "protobuf_format",
    "protobufjs",
    "retrofit",
    "sax",
    "xml_js",
    "pdd_image_knife",
    "@amap/imageknife",
]


def get_so_of_frame(frame):
    so = frame['file_data']
    symbol = frame['symbol_data']
    if (not so.endswith(".hap")) and (not so.endswith(".hsp")):
        return so, False
    m = TS_PATTERN.search(symbol)
    if m is None:
        return so, False
    (_, _, package_name, _, _, _, _) = m.groups()
    return package_name, True

def is_white_so(so):
    for so_name in WHITE_SO_NAMES:
        if so_name in so:
            return True
    return False

def find_response_field(stack):
    frames = stack['frames']
    if frames is None:
        return "系统SDK", "others", "others", None
    que = deque()
    so_que = deque()
    async_stack = False
    res_field = None
    for item in frames[::-1]:
        if item['file_data'] is None:
            continue
        if "libnative_hook.z.so" in item["file_data"]:
            continue
        if ("uv_timer_start" in item["symbol_data"]) and ("libuv.so" in item['file_data']):
            async_stack = True
            continue
        if async_stack and ("libuv.so" in item['file_data']):
            continue
        async_stack = False
        skip = False
        so, is_arkts_lib = get_so_of_frame(item)
        if is_arkts_lib:
            if res_field is None or is_white_so(so):
                contain = any(p == so for p in THIRD_ARKTS_FRAGMENT)
                if not contain:
                    return "三方自研代码", "应用自身ArkTS", "应用自身ArkTS", so,
                return "三方ArkTS库", "三方开源ArkTS库", "三方开源ArkTS库", so
        so_que.append(so)

        for excluded_pattern in excluded_rule:
            if excluded_pattern.search(so):
                skip = True
                break
        field = lookup.find_field(so)
        if (not skip) and (field is not None):
            if is_white_so(field[3]):
                return field
            if res_field is None:
                res_field = field
        elif skip and (field is not None):
            que.append(field)
        else:
            continue
    if res_field:
        return res_field
    elif len(que) == 0:
        if len(so_que) == 0:
            return "系统SDK", "others", "others", None
        return "系统SDK", "others", "others", so_que.popleft()
    else:
        return que.popleft()
