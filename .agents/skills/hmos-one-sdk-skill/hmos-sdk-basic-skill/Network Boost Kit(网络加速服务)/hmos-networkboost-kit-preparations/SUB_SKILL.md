---
name: hmos-networkboost-kit-preparations
description: 申请Network Boost Kit所需权限，包括GET_NETWORK_INFO、INTERNET、LINKTURBO权限配置，以及配置签名和受限ACL权限申请，适用于使用Network Boost Kit网络加速能力前的开发准备
---

# Network Boost Kit开发准备技能

## 功能描述

本技能用于指导开发者完成Network Boost Kit的权限申请和配置工作，包括三个核心权限的配置（GET_NETWORK_INFO、INTERNET、LINKTURBO），以及受限ACL权限的特殊申请流程。该技能涵盖了ArkTS和C API两种开发方式的准备工作，确保开发者能够顺利使用Network Boost Kit的网络加速能力。

**核心能力**：
- 权限申请：配置Network Boost Kit所需的三个权限
- 签名配置：完成调试和发布阶段的签名配置
- ACL权限申请：申请受限ACL权限（ohos.permission.LINKTURBO）
- C API准备：配置CMakeLists.txt以支持C API开发

## 使用场景

### 触发词
- "Network Boost Kit权限配置"
- "网络加速权限申请"
- "LINKTURBO权限"
- "受限ACL权限申请"
- "Network Boost Kit开发准备"

### 能做
- 指导配置ohos.permission.GET_NETWORK_INFO权限
- 指导配置ohos.permission.INTERNET权限
- 指导配置ohos.permission.LINKTURBO权限（包括受限ACL权限申请）
- 指导配置调试阶段和发布阶段的签名
- 指导配置C API开发的CMakeLists.txt

### 绝不做
- 不直接执行权限申请操作（需要开发者在AGC平台操作）
- 不替代DevEco Studio的自动签名功能
- 不处理除Network Boost Kit外的其他Kit权限申请

### 补充
- ohos.permission.LINKTURBO为受限ACL权限，需要特别申请流程
- 调试阶段推荐使用DevEco Studio自动签名
- API版本26.0.0 Beta1及以上，发布阶段签名流程已简化

## 调用规范和规则

### 输入约束
- 开发环境：DevEco Studio已安装
- 项目类型：HarmonyOS应用项目
- API版本：根据项目需求确定（影响签名配置流程）
- 开发语言：ArkTS或C API

### 执行约束
- 最大耗时：30分钟（包括ACL权限申请审核时间，审核需1个工作日）
- 权限配置步骤：必须按顺序执行
- 签名配置：区分调试阶段和发布阶段

### 内容约束
- 禁止跳过权限申请直接使用API
- 禁止在module.json5中配置未申请的权限
- 禁止使用非官方渠道申请权限

### 降级约束
- ACL权限申请失败：提示用户检查申请原因，重新提交申请
- 自动签名失败：引导用户使用手动签名方式
- 网络问题：提示检查网络连接，稍后重试

## 调用流程和步骤

### 步骤1：检查权限需求

**前置校验**：
1. 确认项目需要使用Network Boost Kit的哪些能力
2. 确认是否需要使用多网并发等网络加速能力（需要LINKTURBO权限）
3. 确认开发语言是ArkTS还是C API

**权限说明**：
- ohos.permission.GET_NETWORK_INFO：获取设备网络信息，必需
- ohos.permission.INTERNET：允许使用因特网访问网络，必需
- ohos.permission.LINKTURBO：使用多网并发等网络加速能力，可选（不使用该能力则不需要）

### 步骤2：配置module.json5权限

**示例代码**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

**说明**：
- 在entry/src/main路径下的module.json5中配置
- 必须手动配置上述权限后才能使用Network Boost Kit能力
- 如果不使用多网并发等网络加速能力，可以不配置LINKTURBO权限

### 步骤3：C API开发准备（可选）

**前置条件**：使用C API开发Network Boost Kit功能

**配置CMakeLists.txt**：
```cmake
# 编译target为entry时添加以下命令
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so) # 链接libnetwork_boost.so及其他依赖的so
```

**说明**：
- 需要设置动态库路径及头文件路径
- 需要链接libnetwork_boost.so库

### 步骤4：配置签名

**调试阶段**：
1. 方式一：使用DevEco Studio自动签名（推荐）
   - DevEco Studio会自动完成向AGC申请受限权限的步骤
   - 参考：[自动签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)

2. 方式二：手动签名
   - 申请调试证书
   - 注册设备
   - 申请调试Profile
   - 配置签名信息
   - 参考：[配置签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)

**发布阶段**：
- API版本 < 26.0.0 Beta1：
  - 申请发布证书
  - 申请发布Profile
  - 配置签名信息
  - 参考：[配置签名信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-publish-app)

- API版本 >= 26.0.0 Beta1：
  - 流程已简化，无需上述操作

### 步骤5：申请受限ACL权限（需要LINKTURBO权限时）

**操作步骤**：

1. 在申请调试Profile或发布Profile的第4步"申请权限"中：
   - 选中"受限ACL权限"
   - 点击"选择"

2. 搜索并勾选权限：
   - 在权限搜索框中输入"ohos.permission.LINKTURBO"
   - 找到LINKTURBO权限并勾选
   - 提交申请

3. 填写申请原因：
   - 根据实际业务需求填写申请原因
   - 提交后1个工作日内回复
   - 可在互动中心查看申请情况

4. 确认权限：
   - 权限申请通过后在"已获取权限"中查看
   - 勾选后点击确定

5. 生成新Profile文件：
   - 选择权限后点击"添加"
   - 下载新的Profile文件
   - 按手动签名方式替换profile文件

6. 更新module.json5：
```json
"requestPermissions": [{
  "name": "ohos.permission.LINKTURBO"
}]
```

**相关链接**：
- [申请调试Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)
- [申请发布Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090)
- [互动中心](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/interactive)

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| PERMISSION_DENIED | 权限未授予 | 检查module.json5中是否配置了对应权限 |
| ACL_PERMISSION_NOT_APPLIED | ACL权限未申请 | 按照受限ACL权限申请流程提交申请 |
| SIGNATURE_INVALID | 签名无效 | 检查签名配置是否正确，重新生成签名 |
| PROFILE_EXPIRED | Profile文件过期 | 重新申请Profile文件 |
| PERMISSION_REJECTED | 权限申请被拒绝 | 查看拒绝原因，修改申请理由后重新提交 |

## 编译和修复问题

### 依赖声明

**ArkTS项目**：
无特殊依赖，权限配置在module.json5中完成

**C API项目**：
```cmake
# CMakeLists.txt
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 环境要求
- DevEco Studio：最新版本
- HarmonyOS SDK：根据项目需求选择API版本
- HMOS_SDK_NATIVE环境变量：已正确配置（C API开发）

### 常见编译问题

**问题1：权限未生效**
```
Error: Permission denied: ohos.permission.LINKTURBO
```
**解决方法**：
- 检查module.json5中是否配置了权限
- 检查是否申请了受限ACL权限
- 检查Profile文件是否包含该权限

**问题2：C API链接失败**
```
Error: cannot find -lnetwork_boost
```
**解决方法**：
- 检查CMakeLists.txt中是否正确配置了target_link_directories
- 确认HMOS_SDK_NATIVE环境变量是否正确
- 确认libnetwork_boost.so库是否存在

**问题3：签名配置失败**
```
Error: Invalid profile file
```
**解决方法**：
- 检查Profile文件是否过期
- 确认Profile文件是否包含所需权限
- 重新生成Profile文件

## 常见问题与解决方法

### Q1：如何判断是否需要申请LINKTURBO权限？
**原因**：LINKTURBO权限用于多网并发等网络加速能力
**解决方法**：
- 如果使用多网并发、连接迁移等能力，需要申请LINKTURBO权限
- 如果仅使用基础网络功能，GET_NETWORK_INFO和INTERNET权限即可

### Q2：ACL权限申请需要多长时间？
**原因**：ACL权限申请需要人工审核
**解决方法**：
- 正常情况下1个工作日内完成审核
- 可在互动中心查看申请进度
- 申请理由需填写清楚，避免审核延迟

### Q3：自动签名和手动签名有什么区别？
**原因**：两种签名方式适用于不同场景
**解决方法**：
- 自动签名：DevEco Studio自动完成，适合调试阶段，推荐使用
- 手动签名：需要手动申请证书和Profile，适合特殊需求或自动签名失败时

### Q4：API版本26.0.0 Beta1前后的发布签名有什么区别？
**原因**：HarmonyOS简化了发布流程
**解决方法**：
- API版本 < 26.0.0 Beta1：需要申请发布证书、发布Profile并配置签名
- API版本 >= 26.0.0 Beta1：流程已简化，无需上述操作

### Q5：如何检查权限是否配置成功？
**原因**：需要验证权限配置是否正确
**解决方法**：
- 检查module.json5中的requestPermissions配置
- 检查Profile文件中是否包含已获取权限
- 运行应用测试功能是否正常

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "permissions": [
    "ohos.permission.GET_NETWORK_INFO",
    "ohos.permission.INTERNET",
    "ohos.permission.LINKTURBO"
  ],
  "acl_permissions": [
    "ohos.permission.LINKTURBO"
  ],
  "signature_type": "debug",
  "profile_status": "valid",
  "api_version": "26.0.0",
  "development_language": "ArkTS",
  "next_steps": [
    "权限配置已完成，可以开始使用Network Boost Kit功能",
    "如需使用C API，请确认CMakeLists.txt配置正确",
    "建议先进行功能测试，确保权限申请成功"
  ]
}
```

## 参考文档

- [开发准备（原始文档）](references/networkboost-preparations.md)
- [配置调试签名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)
- [发布应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-publish-app)
- [申请调试证书](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-cert-0000002283256797)
- [注册设备](https://developer.huawei.com/consumer/cn/doc/app/agc-help-add-device-0000002283189937)
- [申请调试Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)
- [申请发布证书](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-cert-0000002283336729)
- [申请发布Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090)
- [互动中心](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/interactive)

## 完整示例代码

- [ArkTS权限配置示例](assets/module.json5)
- [C API CMakeLists.txt配置示例](assets/CMakeLists.txt)
- [权限配置检查脚本](scripts/check_permissions.py)

## 测试用例

### 正向测试用例
- [基础权限配置测试](tests/test_basic_permissions.py)：测试GET_NETWORK_INFO和INTERNET权限配置
- [完整权限配置测试](tests/test_full_permissions.py)：测试包含LINKTURBO的完整权限配置
- [自动签名测试](tests/test_auto_signature.py)：测试DevEco Studio自动签名功能

### 边界测试用例
- [最小权限配置测试](tests/test_minimal_permissions.py)：仅配置必需权限
- [API版本边界测试](tests/test_api_version_boundary.py)：测试API版本26.0.0 Beta1前后的签名配置

### 异常测试用例
- [权限缺失测试](tests/test_missing_permissions.py)：测试未配置权限时的错误处理
- [ACL权限申请失败测试](tests/test_acl_permission_failure.py)：测试ACL权限申请被拒绝的情况
- [签名配置错误测试](tests/test_signature_error.py)：测试签名配置错误时的处理