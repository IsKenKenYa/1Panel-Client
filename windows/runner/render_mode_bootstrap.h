#ifndef RUNNER_RENDER_MODE_BOOTSTRAP_H_
#define RUNNER_RENDER_MODE_BOOTSTRAP_H_

#include <string>

enum class BootstrapRenderMode {
  kMd3,
  kNative,
};

BootstrapRenderMode ReadBootstrapRenderMode();
bool LaunchNativeHostIfConfigured(const std::wstring& command_line);

#endif  // RUNNER_RENDER_MODE_BOOTSTRAP_H_