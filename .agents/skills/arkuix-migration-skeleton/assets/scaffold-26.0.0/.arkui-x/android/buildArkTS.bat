@echo off
setlocal enabledelayedexpansion

if "%~1" neq "" goto :copyStageBundleToAndroidAndIOS

@REM It is an ACE compilation flag that cannot be manually modified.
set isAceBuildFlag=%ACEBUILDFLAG%
if "%isAceBuildFlag%" == "true" goto :eof

@REM Select whether you want to execute the compile arkts script.
set scriptBuildFlag=true
if "%scriptBuildFlag%" == "false" goto :eof

set project_path=__PROJECT_PATH__
set ohpm_path=__OHPM_PATH__
set arkuiXSdkPath=__ARKUIX_SDK_PATH__

@REM You can change the module name you want to compile.
set moduleLists=entry

@REM You can change the android arkuix path to the specified path.
set android_arkuix_path=%project_path%\.arkui-x\android\app\src\main\assets\arkui-x

@REM You can change the android systemRes path to the specified path.
set android_systemRes_path=%project_path%\.arkui-x\android\app\src\main\assets\arkui-x\systemres

@REM You can change the ios arkuix path to the specified path.
set ios_arkuix_path=%project_path%\.arkui-x\ios\arkui-x

@REM You can change the ios systemRes path to the specified path.
set ios_systemRes_path=%project_path%\.arkui-x\ios\arkui-x\systemres

cd /d %project_path%
call %ohpm_path% update

call ./hvigorw default@CompileArkTS -p module=%moduleLists%

:copyStageBundleToAndroidAndIOS
    call :deleteFile %ios_arkuix_path%
    call :deleteFile %android_arkuix_path%
    call :copyStageBundleToAndroidAndIOSByTarget default
    set "systemResPath=%arkuiXSdkPath%\engine\systemres"
    xcopy "!systemResPath!" "%ios_systemRes_path%" /s /e /i /y >nul
    xcopy "!systemResPath!" "%android_systemRes_path%" /s /e /i /y >nul
exit /b

:deleteFile
    setlocal enabledelayedexpansion
    set "folders=%moduleLists%"
    for %%i in (%folders%) do (
        set "path=%~1/%%i"
        if exist "!path!" (
             rmdir /s /q "!path!"
        )
    )
    endlocal
exit /b

:copyStageBundleToAndroidAndIOSByTarget
setlocal
set "folders=%moduleLists%"
for %%i in (%folders%) do (
    set "src=%project_path%\%%i\build\default\intermediates\loader_out\%~1\ets"
    set "resindex=%project_path%\%%i\build\default\intermediates\res\%~1\resources.index"
    set "resPath=%project_path%\%%i\build\default\intermediates\res\%~1\resources"
    set "moduleJsonPath=%project_path%\%%i\build\default\intermediates\res\%~1\module.json"
    set "destClassName=%%i%~2"
    set "distAndroid=%android_arkuix_path%\!destClassName!\ets"
    set "distIOS=%ios_arkuix_path%\!destClassName!\ets"
    set "resindexAndroid=%android_arkuix_path%\!destClassName!\resources.index"
    set "resPathAndroid=%android_arkuix_path%\!destClassName!\resources"
    set "moduleJsonPathAndroid=%android_arkuix_path%\!destClassName!\module.json"
    set "resindexIOS=%ios_arkuix_path%\!destClassName!\resources.index"
    set "resPathIOS=%ios_arkuix_path%\!destClassName!\resources"
    set "moduleJsonPathIOS=%ios_arkuix_path%\!destClassName!\module.json"
    md "!distAndroid!" 2>nul
    xcopy "!src!" "!distAndroid!" /s /e /i /y >nul
    xcopy "!resPath!" "!resPathAndroid!" /s /e /i /y >nul
    copy "!resindex!" "!resindexAndroid!" >nul
    copy "!moduleJsonPath!" "!moduleJsonPathAndroid!" >nul
    md "!distIOS!" 2>nul
    xcopy "!src!" "!distIOS!" /s /e /i /y >nul
    xcopy "!resPath!" "!resPathIOS!" /s /e /i /y >nul
    copy "!resindex!" "!resindexIOS!" >nul
    copy "!moduleJsonPath!" "!moduleJsonPathIOS!" >nul
)
exit /b