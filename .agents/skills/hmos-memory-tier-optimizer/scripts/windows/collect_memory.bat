@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM HarmonyOS 应用内存数据采集脚本 (Windows .bat)
REM 用法: collect_memory.bat [bundleName] [outputDir]
REM 示例:
REM   collect_memory.bat                    (自动检测前台应用)
REM   collect_memory.bat com.ohos.mms       (指定应用)
REM   collect_memory.bat com.ohos.mms D:\TestData
REM
REM Mac/Linux 用户请使用 SKILL.md 中的手动 hdc 命令，
REM 或参考以下等效命令：
REM   hdc list targets
REM   hdc shell "aa dump -l"                                  # 获取前台应用
REM   hdc shell "ps -ef | grep <bundleName> | grep -v grep"  # 获取 PID
REM   hdc shell "hidumper --mem <PID>" > meminfo.txt
REM   hdc shell "uitest dumpLayout -p /data/local/tmp/ui_tree.json"
REM   hdc file recv /data/local/tmp/ui_tree.json ./uiTree/ui_tree.json
REM   hdc shell "uitest screenCap -p /data/local/tmp/screenshot.png"
REM   hdc file recv /data/local/tmp/screenshot.png ./screenshot.png
REM ============================================

REM 配置路径：可在外部设置 HDC 指向 hdc.exe；未设置时使用 PATH 中的 hdc
if "%HDC%"=="" set "HDC=hdc"
set "BUNDLE_NAME=%~1"
set "OUTPUT_DIR=%~2"

echo.
echo ============================================
echo HarmonyOS 内存数据采集工具
echo ============================================

REM 检查 hdc 是否可用
"%HDC%" list targets >nul 2>&1
if errorlevel 1 (
    echo [错误] 无法连接设备，请检查 hdc 连接
    exit /b 1
)

REM 如果未指定 bundleName，自动检测前台应用
if "%BUNDLE_NAME%"=="" (
    echo [0/5] 自动检测前台应用...
    for /f "tokens=2 delims=[]" %%a in ('"%HDC%" shell "aa dump -l" 2^>nul ^| findstr "bundle name"') do (
        set "BUNDLE_NAME=%%a"
        goto :got_bundle
    )
    :got_bundle
    if "%BUNDLE_NAME%"=="" (
        echo [错误] 无法检测到前台应用
        echo 请手动指定包名: collect_memory.bat ^<bundleName^>
        exit /b 1
    )
    echo       检测到: %BUNDLE_NAME%
    echo.
)

if "%OUTPUT_DIR%"=="" set "OUTPUT_DIR=.\memory_data"

REM 创建输出目录
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%OUTPUT_DIR%\meminfo" mkdir "%OUTPUT_DIR%\meminfo"
if not exist "%OUTPUT_DIR%\uiTree" mkdir "%OUTPUT_DIR%\uiTree"

echo.
echo ============================================
echo HarmonyOS 内存数据采集工具
echo ============================================
echo 目标应用: %BUNDLE_NAME%
echo 输出目录: %OUTPUT_DIR%
echo.

REM 检查 hdc 是否可用
"%HDC%" list targets >nul 2>&1
if errorlevel 1 (
    echo [错误] 无法连接设备，请检查 hdc 连接
    exit /b 1
)

echo [1/5] 获取前台应用信息...
for /f "tokens=2 delims=[]" %%a in ('"%HDC%" shell "aa dump -l" 2^>nul ^| findstr "main name"') do set "ABILITY_NAME=%%a"
for /f "tokens=2 delims=[]" %%a in ('"%HDC%" shell "aa dump -l" 2^>nul ^| findstr "Mission ID"') do set "MISSION_ID=%%a"
echo       Ability: %ABILITY_NAME%
echo       Mission: %MISSION_ID%
echo.

echo [2/5] 获取应用进程号...
for /f "tokens=2" %%i in ('"%HDC%" shell "ps -ef | grep %BUNDLE_NAME% | grep -v grep" 2^>nul') do (
    set PID=%%i
    goto :got_pid
)

:got_pid
if "%PID%"=="" (
    echo [错误] 未找到应用进程: %BUNDLE_NAME%
    echo 请确认应用正在运行
    exit /b 1
)

echo       PID: %PID%
echo.

echo [3/5] 采集 meminfo...
"%HDC%" shell "hidumper --mem %PID%" > "%OUTPUT_DIR%\meminfo\%BUNDLE_NAME%_%PID%.txt" 2>nul
if errorlevel 1 (
    echo [警告] meminfo 采集失败
) else (
    echo       已保存: %OUTPUT_DIR%\meminfo\%BUNDLE_NAME%_%PID%.txt
)
echo.

echo [4/5] 采集 UI 树...
"%HDC%" shell "uitest dumpLayout -p /data/local/tmp/ui_tree.json" >nul 2>&1
"%HDC%" file recv /data/local/tmp/ui_tree.json "%OUTPUT_DIR%\uiTree\ui_tree.json" >nul 2>&1
if errorlevel 1 (
    echo [警告] UI 树采集失败
) else (
    echo       已保存: %OUTPUT_DIR%\uiTree\ui_tree.json
)
echo.

echo [5/5] 采集截图...
"%HDC%" shell "uitest screenCap -p /data/local/tmp/screenshot.png" >nul 2>&1
"%HDC%" file recv /data/local/tmp/screenshot.png "%OUTPUT_DIR%\screenshot.png" >nul 2>&1
if errorlevel 1 (
    echo [警告] 截图采集失败
) else (
    echo       已保存: %OUTPUT_DIR%\screenshot.png
)
echo.

echo ============================================
echo 采集完成!
echo ============================================
echo 输出文件:
echo   - %OUTPUT_DIR%\meminfo\%BUNDLE_NAME%_%PID%.txt
echo   - %OUTPUT_DIR%\uiTree\ui_tree.json
echo   - %OUTPUT_DIR%\screenshot.png
echo.

REM 显示内存摘要
echo --------------------------------------------
echo 内存摘要:
echo --------------------------------------------
type "%OUTPUT_DIR%\meminfo\%BUNDLE_NAME%_%PID%.txt" | findstr /C:"Total" | findstr /V "native heap"
echo --------------------------------------------
