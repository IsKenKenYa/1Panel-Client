#include "flutter_window.h"

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"

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

          const bool ok = PerformWindowCommand(*command_value, enabled);
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
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("tray")] =
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("jumpList")] =
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("toast")] =
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("fileAssociation")] =
      flutter::EncodableValue(false);
  capabilities[flutter::EncodableValue("bridgeVersion")] =
      flutter::EncodableValue(1);
  return capabilities;
}

bool FlutterWindow::PerformWindowCommand(const std::string& command,
                                         bool enabled) {
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

  return false;
}
