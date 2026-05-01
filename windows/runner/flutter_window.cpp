#include "flutter_window.h"

#include <dwmapi.h>
#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

constexpr UINT kTrayIconCallbackMessage = WM_APP + 200;
constexpr UINT kTrayIconId = 0x1001;

#ifndef DWMWA_SYSTEMBACKDROP_TYPE
#define DWMWA_SYSTEMBACKDROP_TYPE 38
#endif

enum class WindowsSystemBackdropType : int {
  kAuto = 0,
  kNone = 1,
  kMainWindow = 2,
  kTransientWindow = 3,
  kTabbedWindow = 4,
};

std::wstring Utf8ToWide(const std::string& input) {
  if (input.empty()) {
    return std::wstring();
  }

  const int size = MultiByteToWideChar(CP_UTF8, 0, input.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return std::wstring();
  }

  std::wstring output(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, input.c_str(), -1, output.data(), size);
  if (!output.empty() && output.back() == L'\0') {
    output.pop_back();
  }
  return output;
}

void CopyToBuffer(const std::wstring& source, wchar_t* target, size_t target_size) {
  if (target == nullptr || target_size == 0) {
    return;
  }
  wcsncpy_s(target, target_size, source.c_str(), _TRUNCATE);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  ConfigureWindowsBridge();

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  DisposeTrayIcon();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case kTrayIconCallbackMessage: {
      const UINT tray_event = static_cast<UINT>(lparam);
      if (tray_event == WM_LBUTTONUP || tray_event == WM_LBUTTONDBLCLK) {
        ShowWindow(hwnd, SW_RESTORE);
        SetForegroundWindow(hwnd);
      }
      return 0;
    }
    case WM_SIZE: {
      if (flutter_controller_ && flutter_controller_->view()) {
        HWND flutter_hwnd = flutter_controller_->view()->GetNativeWindow();
        if (flutter_hwnd) {
                    RECT rect;
                    GetClientRect(hwnd, &rect);
                    MoveWindow(flutter_hwnd, rect.left, rect.top,
                                         rect.right - rect.left, rect.bottom - rect.top, TRUE);
        }
      }
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::ConfigureWindowsBridge() {
  auto* messenger = flutter_controller_->engine()->messenger();
  windows_bridge_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "onepanel/windows_bridge",
          &flutter::StandardMethodCodec::GetInstance());

  windows_bridge_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "getCapabilities") {
          result->Success(flutter::EncodableValue(BuildCapabilitySnapshot()));
          return;
        }

        if (call.method_name() == "getWindowState") {
          result->Success(flutter::EncodableValue(BuildWindowState()));
          return;
        }

        if (call.method_name() == "performWindowCommand") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("invalid_args", "Expected command argument map.");
            return;
          }

          const auto command_it = args->find(flutter::EncodableValue("command"));
          if (command_it == args->end()) {
            result->Error("invalid_args", "Missing command argument.");
            return;
          }

          const auto* command_value =
              std::get_if<std::string>(&command_it->second);
          if (command_value == nullptr || command_value->empty()) {
            result->Error("invalid_args", "Command must be a non-empty string.");
            return;
          }

          bool enabled = false;
          const auto enabled_it = args->find(flutter::EncodableValue("enabled"));
          if (enabled_it != args->end()) {
            if (const auto* bool_value =
                    std::get_if<bool>(&enabled_it->second)) {
              enabled = *bool_value;
            }
          }

          std::string backdrop_mode;
          const auto backdrop_it =
              args->find(flutter::EncodableValue("backdrop"));
          if (backdrop_it != args->end()) {
            if (const auto* backdrop_value =
                    std::get_if<std::string>(&backdrop_it->second)) {
              backdrop_mode = *backdrop_value;
            }
          }

          const bool ok =
              PerformWindowCommand(*command_value, enabled, backdrop_mode);
          result->Success(flutter::EncodableValue(ok));
          return;
        }

        if (call.method_name() == "performTrayCommand") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("invalid_args", "Expected command argument map.");
            return;
          }

          const auto command_it = args->find(flutter::EncodableValue("command"));
          if (command_it == args->end()) {
            result->Error("invalid_args", "Missing command argument.");
            return;
          }

          const auto* command_value =
              std::get_if<std::string>(&command_it->second);
          if (command_value == nullptr || command_value->empty()) {
            result->Error("invalid_args", "Command must be a non-empty string.");
            return;
          }

          const bool ok = PerformTrayCommand(*command_value);
          result->Success(flutter::EncodableValue(ok));
          return;
        }

        if (call.method_name() == "showToast") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("invalid_args", "Expected toast argument map.");
            return;
          }

          const auto title_it = args->find(flutter::EncodableValue("title"));
          const auto message_it = args->find(flutter::EncodableValue("message"));
          if (title_it == args->end() || message_it == args->end()) {
            result->Error("invalid_args", "Missing toast title or message.");
            return;
          }

          const auto* title_value = std::get_if<std::string>(&title_it->second);
          const auto* message_value =
              std::get_if<std::string>(&message_it->second);
          if (title_value == nullptr || message_value == nullptr) {
            result->Error("invalid_args", "Toast title/message must be strings.");
            return;
          }

          const bool ok =
              ShowToastNotification(Utf8ToWide(*title_value), Utf8ToWide(*message_value));
          result->Success(flutter::EncodableValue(ok));
          return;
        }

        if (call.method_name() == "showTrayBalloon") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("invalid_args", "Expected tray balloon argument map.");
            return;
          }

          const auto title_it = args->find(flutter::EncodableValue("title"));
          const auto message_it = args->find(flutter::EncodableValue("message"));
          if (title_it == args->end() || message_it == args->end()) {
            result->Error("invalid_args", "Missing tray balloon title or message.");
            return;
          }

          const auto* title_value = std::get_if<std::string>(&title_it->second);
          const auto* message_value =
              std::get_if<std::string>(&message_it->second);
          if (title_value == nullptr || message_value == nullptr) {
            result->Error("invalid_args", "Tray balloon title/message must be strings.");
            return;
          }

          const bool ok =
              ShowTrayBalloon(Utf8ToWide(*title_value), Utf8ToWide(*message_value), true);
          result->Success(flutter::EncodableValue(ok));
          return;
        }

        if (call.method_name() == "setNotificationPermission") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("invalid_args", "Expected permission argument map.");
            return;
          }

          const bool ok = UpdateNotificationPermission(*args);
          result->Success(flutter::EncodableValue(ok));
          return;
        }

        result->NotImplemented();
      });
}

flutter::EncodableMap FlutterWindow::BuildCapabilitySnapshot() const {
  flutter::EncodableMap capabilities;
  capabilities[flutter::EncodableValue("nativeHostAvailable")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("windowCommands")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("alwaysOnTop")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("systemBackdrop")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("tray")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("jumpList")] =
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("toast")] =
      flutter::EncodableValue(true);
  capabilities[flutter::EncodableValue("fileAssociation")] =
      flutter::EncodableValue(false);
    capabilities[flutter::EncodableValue("toastPermissionGranted")] =
      flutter::EncodableValue(toast_permission_granted_);
    capabilities[flutter::EncodableValue("trayPermissionGranted")] =
      flutter::EncodableValue(tray_permission_granted_);
  capabilities[flutter::EncodableValue("bridgeVersion")] =
      flutter::EncodableValue(1);
  return capabilities;
}

  flutter::EncodableMap FlutterWindow::BuildWindowState() const {
    HWND hwnd = const_cast<FlutterWindow*>(this)->GetHandle();
    flutter::EncodableMap state;
    state[flutter::EncodableValue("isMinimized")] =
      flutter::EncodableValue(hwnd != nullptr ? IsIconic(hwnd) != FALSE : false);
    state[flutter::EncodableValue("isMaximized")] =
      flutter::EncodableValue(hwnd != nullptr ? IsZoomed(hwnd) != FALSE : false);
    state[flutter::EncodableValue("isAlwaysOnTop")] =
      flutter::EncodableValue(always_on_top_);
    state[flutter::EncodableValue("isVisible")] =
      flutter::EncodableValue(hwnd != nullptr ? IsWindowVisible(hwnd) != FALSE : false);
    state[flutter::EncodableValue("systemBackdropMode")] =
      flutter::EncodableValue(system_backdrop_mode_);
    return state;
  }

bool FlutterWindow::PerformWindowCommand(const std::string& command,
                                         bool enabled,
                                         const std::string& backdrop_mode) {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return false;
  }

  if (command == "minimize") {
    ShowWindow(hwnd, SW_MINIMIZE);
    return true;
  }

  if (command == "maximize") {
    ShowWindow(hwnd, SW_MAXIMIZE);
    return true;
  }

  if (command == "restore") {
    ShowWindow(hwnd, SW_RESTORE);
    return true;
  }

  if (command == "close") {
    PostMessage(hwnd, WM_CLOSE, 0, 0);
    return true;
  }

  if (command == "set_always_on_top") {
    always_on_top_ = enabled;
    SetWindowPos(hwnd, always_on_top_ ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0,
                 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    return true;
  }

  if (command == "set_system_backdrop") {
    return ApplySystemBackdropMode(backdrop_mode);
  }

  return false;
}

bool FlutterWindow::ApplySystemBackdropMode(const std::string& mode) {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return false;
  }

  WindowsSystemBackdropType backdrop = WindowsSystemBackdropType::kMainWindow;
  std::string normalized_mode = "mica";

  if (mode.empty() || mode == "mica") {
    backdrop = WindowsSystemBackdropType::kMainWindow;
    normalized_mode = "mica";
  } else if (mode == "acrylic") {
    backdrop = WindowsSystemBackdropType::kTransientWindow;
    normalized_mode = "acrylic";
  } else if (mode == "none") {
    backdrop = WindowsSystemBackdropType::kNone;
    normalized_mode = "none";
  } else if (mode == "auto") {
    backdrop = WindowsSystemBackdropType::kAuto;
    normalized_mode = "auto";
  } else if (mode == "tabbed") {
    backdrop = WindowsSystemBackdropType::kTabbedWindow;
    normalized_mode = "tabbed";
  } else {
    return false;
  }

  const int backdrop_value = static_cast<int>(backdrop);
  const HRESULT hr = DwmSetWindowAttribute(
      hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &backdrop_value,
      sizeof(backdrop_value));
  if (FAILED(hr)) {
    return false;
  }

  system_backdrop_mode_ = normalized_mode;
  return true;
}

bool FlutterWindow::PerformTrayCommand(const std::string& command) {
  if (command == "initialize") {
    return EnsureTrayIcon();
  }

  if (command == "show") {
    return SetTrayVisibility(true);
  }

  if (command == "hide") {
    return SetTrayVisibility(false);
  }

  if (command == "dispose") {
    return DisposeTrayIcon();
  }

  return false;
}

bool FlutterWindow::ShowToastNotification(const std::wstring& title,
                                          const std::wstring& message) {
  if (!toast_permission_granted_) {
    return false;
  }

  // Current phase uses a Win32-compatible balloon notification path.
  return ShowTrayBalloon(title, message, false);
}

bool FlutterWindow::ShowTrayBalloon(const std::wstring& title,
                                    const std::wstring& message,
                                    bool enforce_tray_permission) {
  if (enforce_tray_permission && !tray_permission_granted_) {
    return false;
  }
  if (!EnsureTrayIcon()) {
    return false;
  }

  NOTIFYICONDATAW notify_data = tray_icon_data_;
  notify_data.uFlags = NIF_INFO;
  CopyToBuffer(title, notify_data.szInfoTitle, ARRAYSIZE(notify_data.szInfoTitle));
  CopyToBuffer(message, notify_data.szInfo, ARRAYSIZE(notify_data.szInfo));
  notify_data.dwInfoFlags = NIIF_INFO;
  notify_data.uTimeout = 3000;
  return Shell_NotifyIconW(NIM_MODIFY, &notify_data) == TRUE;
}

bool FlutterWindow::EnsureTrayIcon() {
  if (tray_initialized_) {
    return true;
  }

  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return false;
  }

  tray_icon_data_ = {};
  tray_icon_data_.cbSize = sizeof(NOTIFYICONDATAW);
  tray_icon_data_.hWnd = hwnd;
  tray_icon_data_.uID = kTrayIconId;
  tray_icon_data_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  tray_icon_data_.uCallbackMessage = kTrayIconCallbackMessage;
  tray_icon_data_.hIcon = static_cast<HICON>(
      LoadImage(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON),
                IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_SHARED));
  if (tray_icon_data_.hIcon == nullptr) {
    tray_icon_data_.hIcon = static_cast<HICON>(
        LoadImage(nullptr, IDI_APPLICATION, IMAGE_ICON, 0, 0,
                  LR_DEFAULTSIZE | LR_SHARED));
  }
  CopyToBuffer(L"1Panel Client", tray_icon_data_.szTip,
               ARRAYSIZE(tray_icon_data_.szTip));

  if (Shell_NotifyIconW(NIM_ADD, &tray_icon_data_) != TRUE) {
    tray_icon_data_.hIcon = nullptr;
    return false;
  }

  tray_initialized_ = true;
  tray_visible_ = true;
  return true;
}

bool FlutterWindow::DisposeTrayIcon() {
  bool ok = true;
  if (tray_initialized_) {
    ok = Shell_NotifyIconW(NIM_DELETE, &tray_icon_data_) == TRUE;
  }

  if (tray_icon_data_.hIcon != nullptr) {
    tray_icon_data_.hIcon = nullptr;
  }

  tray_icon_data_ = {};
  tray_initialized_ = false;
  tray_visible_ = false;
  return ok;
}

bool FlutterWindow::SetTrayVisibility(bool visible) {
  if (visible) {
    return EnsureTrayIcon();
  }
  return DisposeTrayIcon();
}

bool FlutterWindow::UpdateNotificationPermission(
    const flutter::EncodableMap& arguments) {
  const auto toast_it = arguments.find(flutter::EncodableValue("toastAllowed"));
  if (toast_it != arguments.end()) {
    if (const auto* toast_allowed = std::get_if<bool>(&toast_it->second)) {
      toast_permission_granted_ = *toast_allowed;
    }
  }

  const auto tray_it = arguments.find(flutter::EncodableValue("trayAllowed"));
  if (tray_it != arguments.end()) {
    if (const auto* tray_allowed = std::get_if<bool>(&tray_it->second)) {
      tray_permission_granted_ = *tray_allowed;
    }
  }

  return true;
}
