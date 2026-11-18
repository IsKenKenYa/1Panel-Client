#include "headless_engine_host.h"

#include <flutter/plugin_registry.h>
#include <flutter_messenger.h>
#include <flutter_windows.h>

#include <windows.h>

#include <memory>
#include <string>
#include <utility>

#include "generated_plugin_registrant.h"

namespace {

// Headless engine: creates and runs the engine via the C API and reuses the generated plugin registrant through the PluginRegistry interface.
class HeadlessEngine : public flutter::PluginRegistry {
 public:
  bool Start(const std::wstring& assets_path, const std::wstring& icu_data_path) {
    FlutterDesktopEngineProperties properties = {};
    properties.assets_path = assets_path.c_str();
    properties.icu_data_path = icu_data_path.c_str();
    properties.dart_entrypoint = nullptr;  // Dart main()
    properties.dart_entrypoint_argc = 0;
    properties.dart_entrypoint_argv = nullptr;

    engine_ = FlutterDesktopEngineCreate(&properties);
    if (engine_ == nullptr) {
      return false;
    }
    // Plugins must be registered before Run: Dart main() may call plugin
    // channels (path_provider, shared_preferences...) as soon as it starts.
    RegisterPlugins(this);
    if (!FlutterDesktopEngineRun(engine_, nullptr)) {
      return false;
    }
    messenger_ = FlutterDesktopEngineGetMessenger(engine_);
    if (messenger_ == nullptr) {
      return false;
    }
    // The messenger is handed to the WinUI3 host across threads; AddRef per the C API contract.
    FlutterDesktopMessengerAddRef(messenger_);
    return true;
  }

  FlutterDesktopMessengerRef messenger() const { return messenger_; }

  void Stop() {
    if (messenger_ != nullptr) {
      FlutterDesktopMessengerRelease(messenger_);
      messenger_ = nullptr;
    }
    if (engine_ != nullptr) {
      FlutterDesktopEngineDestroy(engine_);
      engine_ = nullptr;
    }
  }

  FlutterDesktopPluginRegistrarRef GetRegistrarForPlugin(
      const std::string& plugin_name) override {
    return FlutterDesktopEngineGetPluginRegistrar(engine_, plugin_name.c_str());
  }

 private:
  FlutterDesktopEngineRef engine_ = nullptr;
  FlutterDesktopMessengerRef messenger_ = nullptr;
};

HeadlessEngine* g_engine = nullptr;
HANDLE g_engine_thread = nullptr;
DWORD g_engine_thread_id = 0;
HANDLE g_ready_event = nullptr;

// Engine platform thread: after creating the engine, drive engine tasks with a
// standard Win32 message loop (the Windows embedding processes engine messages
// transparently through DispatchMessage).
DWORD WINAPI EngineThreadMain(LPVOID param) {
  auto* paths = static_cast<std::pair<std::wstring, std::wstring>*>(param);
  std::unique_ptr<HeadlessEngine> engine = std::make_unique<HeadlessEngine>();
  const bool started = engine->Start(paths->first, paths->second);
  delete paths;

  if (started) {
    g_engine = engine.release();
  }
  ::SetEvent(g_ready_event);
  if (!started) {
    return 1;
  }

  MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0) > 0) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  g_engine->Stop();
  delete g_engine;
  g_engine = nullptr;
  return 0;
}

}  // namespace

int64_t StartHeadlessEngine(const wchar_t* assets_path,
                            const wchar_t* icu_data_path) {
  if (assets_path == nullptr || icu_data_path == nullptr || g_engine != nullptr) {
    return 0;
  }
  g_ready_event = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (g_ready_event == nullptr) {
    return 0;
  }

  auto* paths =
      new std::pair<std::wstring, std::wstring>(assets_path, icu_data_path);
  HANDLE thread =
      ::CreateThread(nullptr, 0, EngineThreadMain, paths, 0, &g_engine_thread_id);
  if (thread == nullptr) {
    delete paths;
    ::CloseHandle(g_ready_event);
    g_ready_event = nullptr;
    return 0;
  }

  ::WaitForSingleObject(g_ready_event, 15000);
  ::CloseHandle(g_ready_event);
  g_ready_event = nullptr;
  g_engine_thread = thread;

  if (g_engine == nullptr) {
    ::PostThreadMessageW(g_engine_thread_id, WM_QUIT, 0, 0);
    ::WaitForSingleObject(thread, 5000);
    ::CloseHandle(thread);
    g_engine_thread = nullptr;
    g_engine_thread_id = 0;
    return 0;
  }
  return reinterpret_cast<int64_t>(g_engine->messenger());
}

void StopHeadlessEngine() {
  if (g_engine == nullptr) {
    return;
  }
  ::PostThreadMessageW(g_engine_thread_id, WM_QUIT, 0, 0);
  if (g_engine_thread != nullptr) {
    ::WaitForSingleObject(g_engine_thread, 5000);
    ::CloseHandle(g_engine_thread);
    g_engine_thread = nullptr;
  }
  g_engine_thread_id = 0;
}
