# Windows Native Host (WinUI3)

This directory contains the independent Windows App SDK WinUI3 native host.

The Flutter runner at [windows/runner/main.cpp](../main.cpp) tries to launch
`native/OnePanelNativeHost.exe` when render mode is `native`.

## Build

```powershell
dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj
```

## Bootstrap executable discovery

The runner resolves native host executables in this order:

1. `build/windows/x64/runner/Debug/native/OnePanelNativeHost.exe`
2. `build/windows/x64/runner/Debug/OnePanelNativeHost.exe`
3. `windows/runner/native_host/OnePanelNativeHost/bin/Debug/net8.0-windows10.0.19041.0/OnePanelNativeHost.exe`
4. `windows/runner/native_host/OnePanelNativeHost/bin/Release/net8.0-windows10.0.19041.0/OnePanelNativeHost.exe`

So for local development, running `dotnet build` is enough and manual copy is not required.

## Publish executable for packaged bootstrap

Publish the host and copy `OnePanelNativeHost.exe` to:

`build/windows/x64/runner/Debug/native/OnePanelNativeHost.exe`

This path matches the bootstrap launcher logic in [windows/runner/render_mode_bootstrap.cpp](../render_mode_bootstrap.cpp).
