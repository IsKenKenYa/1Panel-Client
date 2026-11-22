"""Force UTF-8 on stdout/stderr to avoid garbled Chinese output on Windows
consoles that default to GBK/cp936.

Windows Chinese locales ship with console code page 936 (GBK); Python detects
this at startup and sets ``sys.stdout.encoding = 'gbk'``. When GBK bytes are
captured by Windows Terminal / pipes / the AI tool harness (which expect
UTF-8), multi-byte CJK sequences decode incorrectly -> 乱码.

Import this module as early as possible — right after the ``sys.path.insert``
for ``_lib``, before any ``print()`` or ``logging`` — in entry-point scripts:

    sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
    import utf8_bootstrap  # noqa: E402,F401  — force UTF-8 stdout/stderr (Windows GBK fix)
    from cmd_runner import CmdRunner  # noqa: E402

Safe on all platforms (on Linux/macOS stdout is already UTF-8, so this is a
no-op). Requires Python 3.7+ (``TextIOWrapper.reconfigure``); the project
requires 3.10+, so it is always available.

For a no-code-change alternative, set ``PYTHONUTF8=1`` in the environment
(Python PEP 540 UTF-8 mode) — equivalent and global to the Python process.
"""

import sys


def _force_utf8() -> None:
    for _stream in (sys.stdout, sys.stderr):
        # sys.stdout is typed as TextIO but is a TextIOWrapper at runtime;
        # use getattr so static checkers don't flag the reconfigure attribute.
        _reconfigure = getattr(_stream, "reconfigure", None)
        if _reconfigure is None:
            continue
        try:
            _reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            # Already-closed streams or unsupported runtimes: skip silently.
            pass


# Apply on import.
_force_utf8()
