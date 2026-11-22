# HarmonyOS 构建问题排查指南

## 问题分类

### 环境配置问题

#### 1. spawn java ENOENT

**错误信息**：
```
ERROR: spawn java ENOENT
```

**原因分析**：
- Java 可执行文件不在系统 PATH 中
- JAVA_HOME 未设置或设置错误
- 环境变量未正确传递给 hvigor 子进程

**解决方案**：
```bat
set "JAVA_HOME=<DevEco Studio>\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
```

**验证方法**：
```bat
"%JAVA_HOME%\bin\java.exe" -version
```

---

#### 2. Invalid DEVECO_SDK_HOME

**错误信息**：
```
ERROR: 00303217 Configuration Error
Error Message: Invalid value of 'DEVECO_SDK_HOME' in the system environment path.
```

**原因分析**：
- SDK 路径未设置
- SDK 路径格式错误（如使用正斜杠）
- **构建缓存未清理**（最常见原因）

**解决方案**：

1. 检查并设置 SDK 路径：
```bat
set "DEVECO_SDK_HOME=<DevEco Studio>\sdk"
```

2. **清理构建缓存**（重要）：
```bat
rd /s /q build
rd /s /q entry\build
rd /s /q .hvigor\cache
```

3. 检查 local.properties 文件：
```properties
sdk.dir=<DevEco Studio>/sdk
```

---

#### 3. hvigor-config.json5 not found

**错误信息**：
```
ERROR: 00304004 Not Found
Error Message: Hvigor config file xxx\hvigor\hvigor-config.json5 does not exist.
```

**原因分析**：
- 工作目录错误，不在项目根目录
- 项目结构不完整

**解决方案**：
```bat
REM 切换到包含 hvigor/ 目录的项目根目录
cd /d <project>
```

**验证方法**：
```bat
dir hvigor\hvigor-config.json5
```

---

### 权限问题

#### 4. pnpm install EPERM

**错误信息**：
```
npm ERR! code EPERM
npm ERR! syscall mkdir
npm ERR! path <DevEco Studio>\...\node_modules\pnpm
```

**原因分析**：
- 无权限写入 DevEco Studio 安装目录
- npm 试图在 DevEco 目录安装 pnpm

**解决方案**：
```bat
REM 设置用户缓存目录
set "HOME=<project>\.build-cache\home"
set "USERPROFILE=<project>\.build-cache\home"
set "HVIGOR_USER_HOME=<project>\.build-cache\hvigor"
set "npm_config_cache=<project>\.build-cache\npm"

REM 预先安装 pnpm 到用户目录
"<node>\npm.cmd" config set prefix "<project>\.build-cache\npm-global"
"<node>\npm.cmd" install -g pnpm@10.16.1
```

---

### 路径问题

#### 5. 路径空格导致的问题

**症状**：
- 环境变量值被截断
- 命令找不到

**原因分析**：
- 路径包含空格（如 "DevEco Studio"）
- set 命令未正确处理空格

**解决方案**：
```bat
REM 错误写法 - 空格会导致问题
set JAVA_HOME=<DevEco Studio>\jbr

REM 正确写法 - 使用引号包裹整个赋值表达式
set "JAVA_HOME=<DevEco Studio>\jbr"
```

---

### 缓存问题

#### 6. 构建无变化

**症状**：
- 修改代码后构建结果无变化
- 增量构建不生效

**解决方案**：
```bat
REM 清理所有缓存
rd /s /q build
rd /s /q entry\build
rd /s /q .hvigor\cache
rd /s /q .hvigor\dependencyMap

REM 重新构建
```

---

## 环境变量速查表

| 变量名 | 值 | 用途 |
|--------|-----|------|
| JAVA_HOME | `<DevEco Studio>\jbr` | Java 运行时 |
| DEVECO_SDK_HOME | `<DevEco Studio>\sdk` | HarmonyOS SDK |
| HOME | `<project>\.build-cache\home` | 用户主目录 |
| USERPROFILE | `<project>\.build-cache\home` | Windows 用户配置 |
| HVIGOR_USER_HOME | `<project>\.build-cache\hvigor` | Hvigor 缓存 |
| npm_config_cache | `<project>\.build-cache\npm` | npm 缓存 |

## 目录结构说明

```
项目根目录/
├── hvigor/
│   └── hvigor-config.json5    # Hvigor 配置文件
├── entry/
│   ├── build/                  # 模块构建输出（需清理）
│   └── src/
├── build/                      # 项目构建输出（需清理）
├── .hvigor/
│   └── cache/                  # Hvigor 缓存（需清理）
├── build-profile.json5         # 构建配置
├── hvigorfile.ts               # Hvigor 脚本
└── local.properties            # 本地配置（SDK 路径）
```

## 构建命令

```bat
REM 清理
hvigorw clean --no-daemon

REM 构建 HAP
hvigorw assembleHap --no-daemon

REM 构建 APP（多模块）
hvigorw assembleApp --no-daemon

REM 指定模块
hvigorw :entry:assembleHap --no-daemon
```

### ArkTS 编译错误

#### 7. bigint 与 number 类型运算错误

**错误信息**：
```
ERROR: 10505001 ArkTS Compiler Error
Error Message: Operator '/' cannot be applied to types 'bigint' and 'number'.
```

**原因分析**：
- ArkTS 中某些 API 返回 `bigint` 类型（如 `hidebug.getSystemMemInfo().totalMem`）
- 不能直接与 `number` 类型进行算术运算

**解决方案**：
```typescript
// 错误写法
let totalMemGB = memInfo.totalMem / (1024 * 1024);

// 正确写法 - 使用 Number() 转换
let totalMemGB = Number(memInfo.totalMem) / (1024 * 1024);
```

---

#### 8. 静态方法中使用 this

**错误信息**：
```
ERROR: 10605093 ArkTS Compiler Error
Error Message: Using "this" inside stand-alone functions is not supported (arkts-no-standalone-this)
```

**原因分析**：
- ArkTS 静态方法（static）中不能使用 `this` 关键字
- 静态方法属于类本身，不属于实例

**解决方案**：
```typescript
// 错误写法
class MemoryOptimizer {
  private static readonly TAG = 'MemoryOptimizer';

  static getCacheCount(): number {
    console.warn(`${this.TAG}: warning`);  // 错误
    return 2;
  }
}

// 正确写法 - 直接使用类名或字符串
class MemoryOptimizer {
  private static readonly TAG = 'MemoryOptimizer';

  static getCacheCount(): number {
    console.warn(`MemoryOptimizer: warning`);  // 正确
    return 2;
  }
}
```

---

## 调试技巧

### 1. 查看详细日志
```bat
hvigorw assembleHap --no-daemon --stacktrace
hvigorw assembleHap --no-daemon --debug
```

### 2. 验证环境变量
```bat
echo %JAVA_HOME%
echo %DEVECO_SDK_HOME%
"%JAVA_HOME%\bin\java.exe" -version
```

### 3. 检查 SDK 完整性
```bat
dir "%DEVECO_SDK_HOME%\default\openharmony"
dir "%DEVECO_SDK_HOME%\default\hms"
```
