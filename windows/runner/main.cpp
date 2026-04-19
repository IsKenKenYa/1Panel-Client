#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdlib>

#include "flutter_window.h"
#include "render_mode_bootstrap.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  const BootstrapRenderMode bootstrap_mode = ReadBootstrapRenderMode();
  if (bootstrap_mode == BootstrapRenderMode::kNative) {
    const std::wstring incoming_command_line =
        command_line != nullptr ? command_line : L"";
    if (LaunchNativeHostIfConfigured(incoming_command_line)) {
      ::CoUninitialize();
      return EXIT_SUCCESS;
    }

    // Native host is requested but unavailable, fallback to Flutter MD3 path.
    _wputenv_s(L"ONEPANEL_FORCE_MD3", L"1");
  }

  // Current process is the Flutter runner path, not the native host path.
  _wputenv_s(L"ONEPANEL_NATIVE_HOST_ACTIVE", L"0");

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"1Panel Client", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
