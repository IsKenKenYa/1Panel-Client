#include "flutter_window.h"

#include <optional>

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
  
  // Create a placeholder Win32 ListBox
  listbox_hwnd_ = CreateWindow(
      L"LISTBOX", NULL,
      WS_CHILD | WS_VISIBLE | LBS_STANDARD,
      0, 0, 200, frame.bottom - frame.top,
      GetHandle(), NULL, GetModuleHandle(nullptr), NULL);
  SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)L"Loading servers...");

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // SubTask 3.2: Initialize channel communication
  SetupChannel();

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (native_channel_) {
    native_channel_ = nullptr;
  }

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::SetupChannel() {
  if (!flutter_controller_ || !flutter_controller_->engine()) {
    return;
  }

  native_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "com.onepanel.client/method",
          &flutter::StandardMethodCodec::GetInstance());

  // Check UIRenderMode
  auto mode_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          bool use_md3 = false;
          if (result) {
              if (auto* mode_str = std::get_if<std::string>(result)) {
                  use_md3 = (*mode_str == "md3");
              }
          }
          if (use_md3) {
              if (listbox_hwnd_) {
                  DestroyWindow(listbox_hwnd_);
                  listbox_hwnd_ = nullptr;
              }
              RECT rect;
              GetClientRect(GetHandle(), &rect);
              if (flutter_controller_ && flutter_controller_->view()) {
                  HWND flutter_hwnd = flutter_controller_->view()->GetNativeWindow();
                  if (flutter_hwnd) {
                      MoveWindow(flutter_hwnd, rect.left, rect.top, 
                                 rect.right - rect.left, rect.bottom - rect.top, TRUE);
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getUIRenderMode", nullptr, std::move(mode_result));

  // SubTask 5.1 & 5.2: Invoke Dart side to get data
  auto servers_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          if (listbox_hwnd_ && result) {
              SendMessage(listbox_hwnd_, LB_RESETCONTENT, 0, 0);
              if (auto* list = std::get_if<flutter::EncodableList>(result)) {
                  for (const auto& item : *list) {
                      if (auto* map = std::get_if<flutter::EncodableMap>(&item)) {
                          auto name_it = map->find(flutter::EncodableValue("name"));
                          if (name_it != map->end()) {
                              if (auto* name_str = std::get_if<std::string>(&name_it->second)) {
                                  int size_needed = MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), NULL, 0);
                                  std::wstring wname(size_needed, 0);
                                  MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), &wname[0], size_needed);
                                  SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)wname.c_str());
                              }
                          }
                      }
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getServers", nullptr, std::move(servers_result));

  flutter::EncodableMap args;
  args[flutter::EncodableValue("path")] = flutter::EncodableValue("/");
  auto files_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          if (listbox_hwnd_ && result) {
              SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)L"--- Files ---");
              if (auto* list = std::get_if<flutter::EncodableList>(result)) {
                  for (const auto& item : *list) {
                      if (auto* map = std::get_if<flutter::EncodableMap>(&item)) {
                          auto name_it = map->find(flutter::EncodableValue("name"));
                          if (name_it != map->end()) {
                              if (auto* name_str = std::get_if<std::string>(&name_it->second)) {
                                  int size_needed = MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), NULL, 0);
                                  std::wstring wname(size_needed, 0);
                                  MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), &wname[0], size_needed);
                                  SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)wname.c_str());
                              }
                          }
                      }
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getFiles", std::make_unique<flutter::EncodableValue>(args), std::move(files_result));

  auto apps_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          if (listbox_hwnd_ && result) {
              SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)L"--- Apps ---");
              if (auto* list = std::get_if<flutter::EncodableList>(result)) {
                  for (const auto& item : *list) {
                      if (auto* map = std::get_if<flutter::EncodableMap>(&item)) {
                          auto name_it = map->find(flutter::EncodableValue("name"));
                          if (name_it != map->end()) {
                              if (auto* name_str = std::get_if<std::string>(&name_it->second)) {
                                  int size_needed = MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), NULL, 0);
                                  std::wstring wname(size_needed, 0);
                                  MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), &wname[0], size_needed);
                                  SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)wname.c_str());
                              }
                          }
                      }
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getApps", nullptr, std::move(apps_result));

  auto websites_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          if (listbox_hwnd_ && result) {
              SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)L"--- Websites ---");
              if (auto* list = std::get_if<flutter::EncodableList>(result)) {
                  for (const auto& item : *list) {
                      if (auto* map = std::get_if<flutter::EncodableMap>(&item)) {
                          auto name_it = map->find(flutter::EncodableValue("primaryDomain"));
                          if (name_it != map->end()) {
                              if (auto* name_str = std::get_if<std::string>(&name_it->second)) {
                                  int size_needed = MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), NULL, 0);
                                  std::wstring wname(size_needed, 0);
                                  MultiByteToWideChar(CP_UTF8, 0, name_str->c_str(), (int)name_str->size(), &wname[0], size_needed);
                                  SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)wname.c_str());
                              }
                          }
                      }
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getWebsites", nullptr, std::move(websites_result));

  auto monitoring_result = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* result) {
          if (listbox_hwnd_ && result) {
              SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)L"--- Monitoring ---");
              if (auto* map = std::get_if<flutter::EncodableMap>(result)) {
                  auto cpu_it = map->find(flutter::EncodableValue("cpu"));
                  if (cpu_it != map->end()) {
                      if (auto* cpu_val = std::get_if<double>(&cpu_it->second)) {
                          std::wstring cpu_str = L"CPU: " + std::to_wstring(*cpu_val) + L"%";
                          SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)cpu_str.c_str());
                      }
                  }
                  auto mem_it = map->find(flutter::EncodableValue("memory"));
                  if (mem_it != map->end()) {
                      if (auto* mem_val = std::get_if<double>(&mem_it->second)) {
                          std::wstring mem_str = L"Memory: " + std::to_wstring(*mem_val) + L"%";
                          SendMessage(listbox_hwnd_, LB_ADDSTRING, 0, (LPARAM)mem_str.c_str());
                      }
                  }
              }
          }
      },
      nullptr, nullptr);
  native_channel_->InvokeMethod("getMonitoring", nullptr, std::move(monitoring_result));
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
      RECT rect;
      GetClientRect(hwnd, &rect);
      int listbox_width = 200;
      if (listbox_hwnd_) {
        MoveWindow(listbox_hwnd_, rect.left, rect.top, listbox_width, rect.bottom - rect.top, TRUE);
      }
      if (flutter_controller_ && flutter_controller_->view()) {
        HWND flutter_hwnd = flutter_controller_->view()->GetNativeWindow();
        if (flutter_hwnd) {
          if (listbox_hwnd_) {
            MoveWindow(flutter_hwnd, rect.left + listbox_width, rect.top, 
                       rect.right - rect.left - listbox_width, rect.bottom - rect.top, TRUE);
          } else {
            MoveWindow(flutter_hwnd, rect.left, rect.top, 
                       rect.right - rect.left, rect.bottom - rect.top, TRUE);
          }
        }
      }
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
