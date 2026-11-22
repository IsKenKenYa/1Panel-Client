---
name: hmos-remote-communication-kit-preparations
description: 配置Remote Communication Kit开发环境，包括权限申请、C API环境配置、HTTP明文传输策略设置，适用于使用远场通信服务前的开发准备场景
---

# Remote Communication Kit开发准备技能

## 功能描述

本技能用于配置HarmonyOS Remote Communication Kit的开发环境，包括：
- 申请和配置必需权限（ohos.permission.INTERNET和ohos.permission.GET_NETWORK_INFO）
- 配置C API开发环境（CMakeLists.txt设置）
- 配置HTTP明文传输策略（network_config.json）

Remote Communication Kit提供场景化的网络服务能力，支持HTTP/HTTPS请求、会话管理、代理配置等功能。

## 使用场景

### 触发词
- "Remote Communication Kit开发准备"
- "配置远场通信服务"
- "申请Remote Communication Kit权限"
- "配置HTTP明文传输"
- "设置Remote Communication Kit开发环境"

### 能做
- 指导配置module.json5权限声明
- 指导配置C API开发环境（CMakeLists.txt）
- 指导配置HTTP明文传输策略
- 提供权限配置示例代码
- 提供HTTP安全配置示例

### 绝不做
- 不执行具体的网络请求操作
- 不提供网络通信的API调用代码（仅提供开发准备配置）
- 不处理网络请求的业务逻辑

### 补充
- Remote Communication Kit除取消网络请求、关闭会话外，其余请求都需要权限
- HTTP明文传输配置仅在API 6.1.0(23)及以上版本支持
- C API需要链接librcp_c.so动态库

## 调用规范和规则

### 输入约束
- 应用类型：HarmonyOS应用
- 开发语言：ArkTS或C/C++
- 目标API版本：API 5.0.0(12)及以上
- 配置文件路径：entry/src/main/module.json5

### 执行约束
- 最大配置检查耗时：30秒
- 配置文件修改需备份原文件
- 必须验证配置文件的JSON格式正确性

### 内容约束
- 禁止删除已有权限配置
- 禁止修改不相关的配置项
- 禁止硬编码敏感信息（如证书密码）

### 降级约束
- 配置文件不存在：提示用户创建module.json5或CMakeLists.txt
- 权限申请失败：提示用户检查权限配置格式
- HTTP明文配置失败：使用默认HTTPS配置

## 调用流程和步骤

### 步骤1：权限配置准备

**前置校验**：
1. 检查entry/src/main/module.json5文件是否存在
2. 检查文件是否为有效的JSON5格式
3. 确认应用是否已配置必要权限

**权限说明**：
- `ohos.permission.INTERNET`：用于应用访问互联网（必需）
- `ohos.permission.GET_NETWORK_INFO`：用于获取设备网络信息（必需）

**参数准备**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 步骤2：配置权限（ArkTS开发）

**示例代码**：
```typescript
// entry/src/main/module.json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "always"
        }
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_network_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "always"
        }
      }
    ]
  }
}
```

### 步骤3：配置C API开发环境（C/C++开发）

**示例代码**：
```cmake
# CMakeLists.txt
# 设置最低CMake版本
cmake_minimum_required(VERSION 3.4.1)

# 设置项目名称
project(remote_communication_demo)

# 设置HarmonyOS SDK路径（根据实际安装路径调整）
set(HMOS_SDK_NATIVE ${OHOS_SDK_NATIVE}/native)

# 添加头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 添加动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接Remote Communication Kit动态库
target_link_libraries(entry PUBLIC 
    librcp_c.so
    # 其他依赖库
)

# 设置编译选项
set_target_properties(entry PROPERTIES
    C_STANDARD 11
    CXX_STANDARD 17
)
```

### 步骤4：配置HTTP明文传输策略

**示例代码**：
```json
// src/main/resources/base/profile/network_config.json
{
  "network-security-config": {
    "base-config": {
      "cleartextTrafficPermitted": true
    },
    "domain-config": [
      {
        "domains": [
          {
            "name": "example.com"
          }
        ],
        "cleartextTrafficPermitted": false
      }
    ],
    "component-config": {
      "Remote Communication Kit": true
    }
  }
}
```

**配置说明**：
- `base-config.cleartextTrafficPermitted`：全局明文传输开关，true表示允许，false表示禁止
- `domain-config`：针对特定域名的配置，优先级高于base-config
- `component-config.Remote Communication Kit`：启用Remote Communication Kit的HTTP明文拦截功能

### 步骤5：错误处理

**常见配置错误**：
```typescript
// 权限配置错误示例
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
        // 锺少reason字段（API 9+必填）
      }
    ]
  }
}

// 正确配置
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|--------|------|----------|
| 201 | 权限被拒绝 | 检查module.json5中是否正确配置了ohos.permission.INTERNET和ohos.permission.GET_NETWORK_INFO权限 |
| 1007900201 | HTTP明文请求被拦截 | 检查network_config.json中是否配置了允许HTTP明文传输，或使用HTTPS协议 |
| 401 | 参数错误 | 检查module.json5配置格式是否正确，确保JSON5格式无误 |
| 1007900001 | 不支持的协议 | 检查URL协议是否正确，确保使用http或https |
| 1007900003 | URL格式错误 | 检查传入的url格式是否正确 |
| 1007900006 | 域名解析失败 | 检查网络连接和DNS配置 |

更多错误码请参考：[Remote Communication Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：API 5.0.0(12)及以上
- DevEco Studio：4.0及以上版本
- CMake：3.4.1及以上版本（C API开发）
- NDK：r12及以上版本（C API开发）

### 常见编译问题

**问题1：找不到librcp_c.so**
```
CMake Error: Cannot find -llibrcp_c
```
**解决方法**：
1. 检查HarmonyOS SDK是否正确安装
2. 确认HMOS_SDK_NATIVE路径配置正确
3. 确认target_link_directories中路径正确

**问题2：权限配置不生效**
```
Error: Permission denied
```
**解决方法**：
1. 检查module.json5中requestPermissions配置格式
2. 确保reason字段使用字符串资源引用（$string:xxx）
3. 清理项目并重新编译：Build > Clean Project

**问题3：HTTP明文请求失败**
```
Error: 1007900201
```
**解决方法**：
1. 检查network_config.json文件是否存在
2. 确认component-config中Remote Communication Kit设置为true
3. 对特定域名配置domain-config允许明文传输

## 常见问题与解决方法

### Q1：如何判断应用是否需要配置权限？
**原因**：Remote Communication Kit除取消网络请求、关闭会话外，其余请求都需要权限
**解决方法**：
- 如果应用需要发起网络请求，必须配置ohos.permission.INTERNET权限
- 如果应用需要获取网络状态，必须配置ohos.permission.GET_NETWORK_INFO权限
- 权限配置位置：entry/src/main/module.json5

### Q2：C API开发时如何配置开发环境？
**原因**：C API需要额外的编译和链接配置
**解决方法**：
- 在CMakeLists.txt中添加头文件路径：`target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)`
- 添加动态库路径：`target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)`
- 链接librcp_c.so：`target_link_libraries(entry PUBLIC librcp_c.so)`

### Q3：如何配置HTTP明文传输？
**原因**：默认情况下，系统会拦截HTTP明文请求以保障安全
**解决方法**：
- 创建network_config.json文件：src/main/resources/base/profile/network_config.json
- 配置base-config.cleartextTrafficPermitted为true（全局允许）
- 或使用domain-config为特定域名配置明文传输策略
- 启用component-config.Remote Communication Kit为true

### Q4：如何处理权限申请失败？
**原因**：权限配置格式不正确或缺少必要字段
**解决方法**：
- 检查module.json5格式是否正确
- 确保reason字段使用字符串资源引用（$string:xxx）
- 确保usedScene字段配置正确
- 使用DevEco Studio的配置检查功能验证配置

### Q5：如何验证配置是否成功？
**原因**：配置后需要验证才能确认配置生效
**解决方法**：
- 使用`hdc shell bm dump -n <bundle_name>`命令查看应用权限
- 发起一个测试网络请求，检查是否返回权限错误
- 检查日志中是否有权限相关的错误信息
- 使用DevEco Studio的Profiler工具监控网络请求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "Remote Communication Kit开发环境配置完成",
  "configurations": {
    "permissions": [
      "ohos.permission.INTERNET",
      "ohos.permission.GET_NETWORK_INFO"
    ],
    "c_api": {
      "header_path": "${HMOS_SDK_NATIVE}/sysroot/usr/include",
      "library_path": "${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos",
      "linked_library": "librcp_c.so"
    },
    "http_cleartext": {
      "config_file": "src/main/resources/base/profile/network_config.json",
      "enabled": true
    }
  },
  "apiUsed": [
    "Remote Communication Kit"
  ],
  "next_steps": [
    "配置完成后即可使用Remote Communication Kit发起网络请求",
    "参考开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-preparations",
    "参考API文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview"
  ]
}
```

## 参考文档

- [Remote Communication Kit开发指南](references/remote-communication-preparations.md)
- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview)
- [Remote Communication Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)
- [HTTP明文访问权限配置说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)

## 完整示例代码

- [ArkTS权限配置示例](assets/module.json5.example)
- [C API配置示例](assets/CMakeLists.txt.example)
- [HTTP明文配置示例](assets/network_config.json.example)

## 测试用例

### 正向测试用例
- [权限配置验证](tests/test_permissions.ts)：验证module.json5中权限配置正确性
- [C API环境验证](tests/test_c_api.cpp)：验证CMakeLists.txt配置正确性
- [HTTP明文配置验证](tests/test_http_cleartext.ts)：验证network_config.json配置正确性

### 边界测试用例
- [多权限配置](tests/test_multiple_permissions.ts)：测试同时配置多个权限的场景
- [域名白名单配置](tests/test_domain_whitelist.ts)：测试特定域名HTTP明文配置

### 异常测试用例
- [权限配置缺失](tests/test_missing_permission.ts)：测试权限配置缺失时的错误处理
- [配置格式错误](tests/test_invalid_config.ts)：测试配置文件格式错误时的错误提示
- [库链接失败](tests/test_library_link_error.cpp)：测试librcp_c.so链接失败时的处理