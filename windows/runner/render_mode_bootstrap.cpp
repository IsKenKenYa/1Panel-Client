#include "render_mode_bootstrap.h"

#include <shlobj.h>

#include <cstdio>
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
// The csproj pins RuntimeIdentifier win-x64, so the built host lands under a
// RID subdirectory (verified in production); framework-dependent builds put it
// directly in the TFM directory. Probe both layouts. The %s segment carries
// the directory separator itself ("\win-x64\" or "\").
constexpr wchar_t kRepoTfmRelativePath[] =
  L"..\\..\\..\\..\\..\\windows\\runner\\native_host\\OnePanelNativeHost\\bin\\%s\\net8.0-windows10.0.19041.0%sOnePanelNativeHost.exe";
constexpr wchar_t kRidSegment[] = L"\\win-x64\\";
constexpr wchar_t kPlainSegment[] = L"\\";
constexpr wchar_t kDebugMode[] = L"Debug";
constexpr wchar_t kReleaseMode[] = L"Release";

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

  // Build repo-source-tree candidates: {Debug,Release} x {win-x64 RID, TFM-only}.
  std::vector<std::filesystem::path> repo_candidates;
  for (const wchar_t* mode : {kDebugMode, kReleaseMode}) {
    for (const wchar_t* rid : {kRidSegment, kPlainSegment}) {
      wchar_t formatted[MAX_PATH];
      swprintf_s(formatted, kRepoTfmRelativePath, mode, rid);
      repo_candidates.push_back(runner_directory / formatted);
    }
  }

  std::vector<std::filesystem::path> candidates = {
      runner_directory / kNativeHostRelativePath,
      runner_directory / L"OnePanelNativeHost.exe",
  };
  candidates.insert(candidates.end(), repo_candidates.begin(),
                    repo_candidates.end());

  for (const auto& candidate : candidates) {
    const bool found = std::filesystem::exists(candidate);
    {
      std::wofstream log(
          runner_directory / L"bootstrap_launch.log", std::ios::app);
      if (log.is_open()) {
        log << L"candidate=" << candidate.wstring()
            << L" exists=" << (found ? L"1" : L"0") << std::endl;
      }
    }
    if (found) {
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
  BootstrapRenderMode result = BootstrapRenderMode::kMd3;
  if (mode.has_value() && *mode == "native") {
    result = BootstrapRenderMode::kNative;
  }

  // Dev diagnostic: why did bootstrap pick this mode?
  wchar_t exe_path[MAX_PATH];
  std::filesystem::path log_path = L"bootstrap_launch.log";
  if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) > 0) {
    log_path = std::filesystem::path(exe_path).parent_path() / log_path;
  }
  const auto prefs = ResolveSharedPreferencesPath();
  std::wofstream log(log_path, std::ios::app);
  if (log.is_open()) {
    const std::wstring raw_mode =
        mode.has_value() ? std::wstring(mode->begin(), mode->end())
                         : std::wstring(L"<none>");
    log << L"ReadBootstrapRenderMode mode=" << raw_mode << L" -> "
        << (result == BootstrapRenderMode::kNative ? L"native" : L"md3")
        << L" prefs=" << (prefs.has_value() ? prefs->wstring() : L"<missing>")
        << std::endl;
  }
  return result;
}

bool LaunchNativeHostIfConfigured(const std::wstring& command_line) {
  const auto native_host_path = ResolveNativeHostExecutablePath();
  if (!native_host_path.has_value()) {
    return false;
  }

  const bool launched = LaunchDetachedProcess(*native_host_path, command_line);

  // Dev diagnostic: resolution + spawn outcome next to the runner exe
  // (bootstrap failures are otherwise completely silent).
  wchar_t module_path[MAX_PATH];
  if (GetModuleFileNameW(nullptr, module_path, MAX_PATH) > 0) {
    const std::filesystem::path log_path =
        std::filesystem::path(module_path).parent_path() /
        L"bootstrap_launch.log";
    std::wofstream log(log_path, std::ios::app);
    if (log.is_open()) {
      log << L"resolved=" << native_host_path->wstring()
          << L" launched=" << (launched ? L"1" : L"0")
          << L" gle=" << GetLastError() << std::endl;
    }
  }

  return launched;
}