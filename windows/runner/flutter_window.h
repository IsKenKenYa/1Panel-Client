#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"

#include <map>
#include <string>

// TODO(SubTask 3.1): Prepare for WinUI 3 integration.
// Currently wraps Win32Window, but will be replaced by DesktopWindowXamlSource (WinUI 3)
// or a native WinUI 3 Window app model in the future to replace Win32 HWND entirely.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // SubTask 3.2: Native channel for communication with Flutter Engine
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> native_channel_;

  HWND listbox_hwnd_ = nullptr;

  // SubTask 4.1: I18n cache
  std::map<std::string, std::wstring> i18n_cache_;
  std::wstring GetI18nString(const std::string& key, const std::wstring& fallback);

  void SetupChannel();
  void SetupListViewColumns();
  void FetchData();
  void AddListViewItem(const std::wstring& text);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
