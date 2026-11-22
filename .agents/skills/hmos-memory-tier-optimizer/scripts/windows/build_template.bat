@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM HarmonyOS Project Build Script Template (Windows .bat)
REM Usage:
REM   build_template.bat [projectPath]
REM Optional environment variables:
REM   DEVECO_HOME, DEVECO_SDK_HOME, OHOS_SDK_HOME, HM_SDK_HOME
REM
REM Mac/Linux 用户请使用 SKILL.md 中的 PowerShell 模板等价命令，
REM 关键差异：环境变量用 export 代替 set，反斜杠改为正斜杠。

set "PROJECT_PATH=%~1"
if "%PROJECT_PATH%"=="" set "PROJECT_PATH=%CD%"

pushd "%PROJECT_PATH%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] PROJECT_PATH does not exist: %PROJECT_PATH%
  exit /b 1
)

if not exist "build-profile.json5" (
  echo [ERROR] Not a HarmonyOS project root: %CD%
  echo         Expected build-profile.json5.
  popd
  exit /b 1
)

if not exist "hvigor" (
  echo [ERROR] Not a HarmonyOS project root: %CD%
  echo         Expected hvigor directory.
  popd
  exit /b 1
)

REM Read sdk.dir from local.properties if present.
set "SDK_FROM_LOCAL="
if exist "local.properties" (
  for /f "tokens=1,* delims==" %%a in ('findstr /b /c:"sdk.dir=" local.properties') do (
    set "SDK_FROM_LOCAL=%%b"
  )
)
if not "%SDK_FROM_LOCAL%"=="" set "SDK_FROM_LOCAL=%SDK_FROM_LOCAL:/=\%"

set "SDK_PATH=%DEVECO_SDK_HOME%"
if "%SDK_PATH%"=="" set "SDK_PATH=%OHOS_SDK_HOME%"
if "%SDK_PATH%"=="" set "SDK_PATH=%HM_SDK_HOME%"
if "%SDK_PATH%"=="" set "SDK_PATH=%SDK_FROM_LOCAL%"

if "%DEVECO_HOME%"=="" (
  if not "%SDK_PATH%"=="" (
    for %%i in ("%SDK_PATH%\..") do set "DEVECO_HOME=%%~fi"
  )
)

if "%DEVECO_HOME%"=="" (
  for %%d in (
    "%ProgramFiles%\Huawei\DevEco Studio"
    "%LocalAppData%\Programs\Huawei\DevEco Studio"
    "%CD:~0,3%Software\DevEco Studio"
  ) do (
    if exist "%%~d\jbr\bin\java.exe" if exist "%%~d\tools\node\node.exe" if exist "%%~d\tools\hvigor\bin\hvigorw.js" (
      set "DEVECO_HOME=%%~d"
      goto :found_deveco
    )
  )
)

:found_deveco
if "%DEVECO_HOME%"=="" (
  echo [ERROR] DevEco Studio not found.
  echo         Set DEVECO_HOME or DEVECO_SDK_HOME, or configure local.properties sdk.dir.
  popd
  exit /b 1
)

if "%SDK_PATH%"=="" set "SDK_PATH=%DEVECO_HOME%\sdk"

set "JAVA_HOME=%DEVECO_HOME%\jbr"
set "NODE_EXE=%DEVECO_HOME%\tools\node\node.exe"
set "HVIGOR_JS=%DEVECO_HOME%\tools\hvigor\bin\hvigorw.js"

if not exist "%JAVA_HOME%\bin\java.exe" (
  echo [ERROR] Missing java: %JAVA_HOME%\bin\java.exe
  popd
  exit /b 1
)
if not exist "%NODE_EXE%" (
  echo [ERROR] Missing node: %NODE_EXE%
  popd
  exit /b 1
)
if not exist "%HVIGOR_JS%" (
  echo [ERROR] Missing hvigor: %HVIGOR_JS%
  popd
  exit /b 1
)
if not exist "%SDK_PATH%\default\openharmony" (
  echo [ERROR] Missing SDK openharmony directory: %SDK_PATH%\default\openharmony
  popd
  exit /b 1
)

set "PATH=%JAVA_HOME%\bin;%PATH%"
set "DEVECO_SDK_HOME=%SDK_PATH%"

set "CACHE_ROOT=%CD%\.build-cache"
set "HOME=%CACHE_ROOT%\home"
set "USERPROFILE=%CACHE_ROOT%\home"
set "HVIGOR_USER_HOME=%CACHE_ROOT%\hvigor"
set "npm_config_cache=%CACHE_ROOT%\npm"
if not exist "%HOME%" mkdir "%HOME%"
if not exist "%HVIGOR_USER_HOME%" mkdir "%HVIGOR_USER_HOME%"
if not exist "%npm_config_cache%" mkdir "%npm_config_cache%"

echo ============================================
echo HarmonyOS Build
echo ============================================
echo Project: %CD%
echo DevEco: %DEVECO_HOME%
echo SDK: %DEVECO_SDK_HOME%
echo Java: %JAVA_HOME%
echo Cache: %CACHE_ROOT%
echo ============================================

echo Cleaning build cache...
if exist "build" rd /s /q "build"
if exist "entry\build" rd /s /q "entry\build"
if exist ".hvigor\cache" rd /s /q ".hvigor\cache"

echo Building project...
"%NODE_EXE%" "%HVIGOR_JS%" assembleHap --no-daemon
set "BUILD_EXIT=%ERRORLEVEL%"

if "%BUILD_EXIT%"=="0" (
  echo ============================================
  echo BUILD SUCCESSFUL
  if exist "entry\build\default\outputs\default" (
    dir /b "entry\build\default\outputs\default\*.hap" 2>nul
  )
) else (
  echo ============================================
  echo BUILD FAILED: %BUILD_EXIT%
)

popd
exit /b %BUILD_EXIT%
