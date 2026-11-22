@rem Copyright Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
@echo off

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.\
set APP_HOME=%DIRNAME:~0,-5%

@rem Check if node is installed
node -v >nul 2>nul
if "%errorlevel%" == "9009" (
  echo Could not find Node.js.Please install Node.js first
  goto mainEnd
) else (
  goto sourcemap
)

:sourcemap
set INDEXPATH=%APP_HOME%\lib\index.js
@rem Execute hstack
node "%INDEXPATH%" %*

:mainEnd
if "%OS%"=="Windows_NT" endlocal
