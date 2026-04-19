#include "render_mode_bootstrap.h"

#include <shlobj.h>

#include <filesystem>
#include <fstream>
#include <optional>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

namespace {

constexpr wchar_t kCompanyName[] = L"IsKenKenYa";
constexpr wchar_t kProductName[] = L"1Panel Client";
constexpr wchar_t kPreferencesFileName[] = L"shared_preferences.json";
constexpr wchar_t kNativeHostRelativePath[] = L"native\\OnePanelNativeHost.exe";
constexpr wchar_t kRepoNativeHostDebugRelativePath[] =
  L"..\\..\\..\\..\\..\\windows\\runner\\native_host\\OnePanelNativeHost\\bin\\Debug\\net8.0-windows10.0.19041.0\\OnePanelNativeHost.exe";
constexpr wchar_t kRepoNativeHostReleaseRelativePath[] =
  L"..\\..\\..\\..\\..\\windows\\runner\\native_host\\OnePanelNativeHost\\bin\\Release\\net8.0-windows10.0.19041.0\\OnePanelNativeHost.exe";

std::optional<std::filesystem::path> GetRoamingAppDataPath() {
  PWSTR path = nullptr;
  const HRESULT hr = SHGetKnownFolderPath(
      FOLDERID_RoamingAppData,
      KF_FLAG_DEFAULT,
      nullptr,
      &path);
  if (FAILED(hr) || path == nullptr) {
    return std::nullopt;
  }

  const std::filesystem::path result(path);
  CoTaskMemFree(path);
  return result;
}

std::optional<std::filesystem::path> ResolveSharedPreferencesPath() {
  const auto roaming_dir = GetRoamingAppDataPath();
  if (!roaming_dir.has_value()) {
    return std::nullopt;
  }

  const std::filesystem::path preferences_path =
      *roaming_dir / kCompanyName / kProductName / kPreferencesFileName;
  if (std::filesystem::exists(preferences_path)) {
    return preferences_path;
  }

  return std::nullopt;
}

std::optional<std::string> ReadRenderModeRaw() {
  const auto preferences_path = ResolveSharedPreferencesPath();
  if (!preferences_path.has_value()) {
    return std::nullopt;
  }

  std::ifstream input(preferences_path->string(), std::ios::in | std::ios::binary);
  if (!input.is_open()) {
    return std::nullopt;
  }

  std::ostringstream content;
  content << input.rdbuf();

  const std::regex mode_regex(
      "\\\"flutter\\.app_ui_render_mode\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"");
  std::smatch match;
  const std::string raw = content.str();
  if (std::regex_search(raw, match, mode_regex) && match.size() >= 2) {
    return match[1].str();
  }

  return std::nullopt;
}

std::optional<std::filesystem::path> ResolveNativeHostExecutablePath() {
  wchar_t module_path[MAX_PATH];
  const DWORD length = GetModuleFileNameW(nullptr, module_path, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) {
    return std::nullopt;
  }

  const std::filesystem::path runner_executable(module_path);
  const std::filesystem::path runner_directory = runner_executable.parent_path();

  const std::vector<std::filesystem::path> candidates = {
      runner_directory / kNativeHostRelativePath,
      runner_directory / L"OnePanelNativeHost.exe",
      runner_directory / kRepoNativeHostDebugRelativePath,
      runner_directory / kRepoNativeHostReleaseRelativePath,
  };

  for (const auto& candidate : candidates) {
    if (std::filesystem::exists(candidate)) {
      return candidate;
    }
  }

  return std::nullopt;
}

bool LaunchDetachedProcess(const std::filesystem::path& executable,
                           const std::wstring& command_line) {
  std::wstring full_command = L"\"" + executable.wstring() + L"\"";
  if (!command_line.empty()) {
    full_command.append(L" ");
    full_command.append(command_line);
  }

  std::vector<wchar_t> mutable_command(full_command.begin(), full_command.end());
  mutable_command.push_back(L'\0');

  STARTUPINFOW startup_info{};
  startup_info.cb = sizeof(startup_info);
  PROCESS_INFORMATION process_info{};

  const BOOL ok = CreateProcessW(
      executable.c_str(),
      mutable_command.data(),
      nullptr,
      nullptr,
      FALSE,
      CREATE_NEW_PROCESS_GROUP,
      nullptr,
      executable.parent_path().c_str(),
      &startup_info,
      &process_info);

  if (!ok) {
    return false;
  }

  CloseHandle(process_info.hThread);
  CloseHandle(process_info.hProcess);
  return true;
}

}  // namespace

BootstrapRenderMode ReadBootstrapRenderMode() {
  const auto mode = ReadRenderModeRaw();
  if (mode.has_value() && *mode == "native") {
    return BootstrapRenderMode::kNative;
  }

  return BootstrapRenderMode::kMd3;
}

bool LaunchNativeHostIfConfigured(const std::wstring& command_line) {
  const auto native_host_path = ResolveNativeHostExecutablePath();
  if (!native_host_path.has_value()) {
    return false;
  }

  return LaunchDetachedProcess(*native_host_path, command_line);
}