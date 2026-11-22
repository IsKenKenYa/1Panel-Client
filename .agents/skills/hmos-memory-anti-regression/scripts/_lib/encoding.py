"""Force UTF-8 encoding for stdout/stderr.

Fixes Chinese garbled text on Windows (where default encoding is cp936/GBK).
No-op on macOS/Linux where UTF-8 is already the default.

Usage:
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
    from encoding import *  # noqa: E402
"""

import sys

for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
    except (AttributeError, Exception):
        pass
