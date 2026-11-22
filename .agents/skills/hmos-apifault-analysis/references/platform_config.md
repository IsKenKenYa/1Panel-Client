# 平台配置速查表

## 1. OS 与 Shell 探测

| 探测项 | 命令                                                       | 结果判断                                        |
| ------ | ---------------------------------------------------------- | ----------------------------------------------- |
| OS     | `python3 -c "import platform; print(platform.system())"` | Windows→host_os=windows, Darwin→host_os=macos |
| Shell  | `uname -s`                                               | 退出码0→bash, 非0→powershell                  |
| Python | 先试python3，失败改python                                  | 记录到py_cmd，后续统一使用                      |

**命令分支规则：** 后续所有平台相关命令按`host_shell`值选择bash或powershell分支。

## 2. 命令映射表（按 host_shell）

| 功能           | bash                             | powershell                                                                                                                |
| -------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| 创建目录       | `mkdir -p diagnosis`           | `New-Item -ItemType Directory -Force -Path diagnosis \| Out-Null`                                                        |
| 文件存在性检查 | `test -f "{path}"`             | `Test-Path "{path}"`                                                                                                    |
| 列举目录内容   | `ls "{dir}/"`                  | `Get-ChildItem "{dir}/" -Name`                                                                                          |
| 递归查找文件   | `find "{dir}/" -type f`        | `Get-ChildItem -Path "{dir}/" -Recurse -File \| Select-Object -ExpandProperty FullName`                                  |
| 递归grep搜索   | `grep -rEn "pattern" "{dir}/"` | `Get-ChildItem "{dir}/" -Recurse -File \| Select-String -Pattern "pattern" \| Select-Object -ExpandProperty Path -Unique` |
| 获取时间戳     | `date +%Y%m%d_%H%M%S`          | `Get-Date -Format 'yyyyMMdd_HHmmss'`                                                                                    |

## 3. hilogtool 路径规则

| host_os | 二进制名      | 候选路径                                |
| ------- | ------------- | --------------------------------------- |
| windows | hilogtool.exe | {sdk_path}/hms/toolchains/hilogtool.exe |
| macos   | hilogtool     | {sdk_path}/hms/toolchains/hilogtool     |

**备选路径：** 若候选路径不存在，尝试`{sdk_path}/default/hms/toolchains/{binary_name}`

## 4. SDK 路径提取

**来源文件：** 项目根目录`local.properties`

**提取规则：** 读取`sdk.dir=`行，提取等号后的路径

**分隔符：** Windows用`\`，macOS用`/`

**备用来源：** 若无local.properties或无sdk.dir，读取`build-profile.json5`获取API版本信息，或在对话中询问用户。

## 5. 路径拼接规则

| 路径类型    | Windows示例                                       | macOS示例                                   |
| ----------- | ------------------------------------------------- | ------------------------------------------- |
| SDK工具路径 | `C:\Users\xxx\Sdk\hms\toolchains\hilogtool.exe` | `/Users/xxx/Sdk/hms/toolchains/hilogtool` |
| Skill目录   | `{skill_dir}\references\scripts\xxx.py`         | `{skill_dir}/references/scripts/xxx.py`   |
| 项目路径    | `D:\project\entry\src\main`                     | `/home/user/project/entry/src/main`       |

**注意：**

- 所有路径拼接时注意分隔符
- 传递给命令的路径统一用双引号包裹（避免空格问题）
- `{skill_dir}`为SKILL.md所在目录的absolute path，与项目cwd相对关系不固定
