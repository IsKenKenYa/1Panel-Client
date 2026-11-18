#ifndef RUNNER_HEADLESS_ENGINE_HOST_H_
#define RUNNER_HEADLESS_ENGINE_HOST_H_

#include <stdint.h>

extern "C" {

// Starts a headless Flutter engine with all plugins registered on a dedicated
// background thread and blocks until it is ready (15s timeout). Returns the
// messenger handle (AddRef'd per the C API contract, safe to use across
// threads by the WinUI3 host), or 0 on failure.
__declspec(dllexport) int64_t StartHeadlessEngine(const wchar_t* assets_path,
                                                  const wchar_t* icu_data_path);

// Asks the engine thread to exit and releases the engine (idempotent; may be
// skipped when the process is terminating anyway).
__declspec(dllexport) void StopHeadlessEngine();

}  // extern "C"

#endif  // RUNNER_HEADLESS_ENGINE_HOST_H_
