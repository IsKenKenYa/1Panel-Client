---
name: hmos-appgallery-productview-getshortcut
description: 查询当前应用已固定在桌面上的所有快捷方式列表，支持真机调试，适用于Phone/Tablet/PC/2in1/TV设备（6.0.2(22)及以上版本支持TV），最大支持快捷方式数量由系统限制，适用于查看管理桌面快捷方式场景
---

# 查询应用内快捷方式技能

## 功能描述

查询应用内快捷方式用于获取当前应用已固定在桌面上的所有快捷方式列表。用户可以在应用内查看已添加到桌面的快捷方式列表，快速找到特定的快捷方式。也可通过定期查看和管理这些快捷方式，确保桌面的整洁和高效。

**核心能力**：
- 获取当前应用已固定在桌面上的所有快捷方式列表
- 返回快捷方式的详细信息（PinShortcutInfo）
- 支持Promise异步调用

**适用范围**：
- 真机调试（不支持模拟器）
- 支持设备：Phone、Tablet、PC/2in1、TV（6.0.2(22)及以上版本）
- API版本：6.1.1(24)及以上

**使用限制**：
- 应用市场推荐服务不支持模拟器，请使用真机调试
- 在模拟器中使用该服务将会提示：无法获取内容，请点击屏幕重试

**典型场景**：
- 查看已添加到桌面的快捷方式列表
- 快速查找特定快捷方式
- 管理和清理桌面快捷方式
- 桌面快捷方式状态检查

## 使用场景

### 触发词
- "查询快捷方式"
- "获取快捷方式列表"
- "查询应用内快捷方式"
- "getPinShortcutInfos"
- "查看桌面快捷方式"
- "管理快捷方式"

### 能做
- 获取当前应用已固定在桌面上的所有快捷方式列表
- 查看快捷方式的详细信息
- 定期检查桌面快捷方式状态
- 为快捷方式管理功能提供数据支持

### 绝不做
- 不创建或添加新的快捷方式（使用requestNewPinShortcut）
- 不删除或移除快捷方式
- 不校验快捷方式是否允许加桌（使用checkPinShortcutPermitted）
- 不在模拟器环境下工作

### 补充
- 从6.1.1(24)版本开始新增此接口
- TV设备支持从6.0.2(22)版本开始
- 返回的快捷方式数量由系统限制决定
- 需要真机环境才能正常使用

## 调用规范和规则

### 输入约束
- 无需输入参数
- 必须在真机环境下调用
- 调用方应用必须已获得相应权限

### 执行约束
- 最大耗时：取决于系统响应，通常在1-3秒内完成
- API调用频次：无明确限制，建议合理控制调用频率
- 异步调用：使用Promise异步回调方式

### 内容约束
- 禁止生成：模拟器环境下的调用代码
- 禁止操作：修改或删除系统快捷方式数据
- 禁止使用：同步调用方式（此API仅支持异步）

### 降级约束
- 网络失败：提示用户检查网络连接，稍后重试
- 权限不足：引导用户检查应用权限设置
- 真机检测失败：明确提示需要在真机环境下运行

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认运行环境为真机设备
2. 确认API版本满足要求（6.1.1(24)及以上）
3. 确认应用已获取必要权限
4. 准备错误处理逻辑

**依赖声明**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
```

### 步骤2：调用API

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'GetPinShortcutInfos';
const DOMAIN: number = 0x0001;

async function queryPinShortcutInfos(): Promise<void> {
  try {
    // 调用getPinShortcutInfos接口获取桌面快捷方式列表信息
    const shortcutInfos = await productViewManager.getPinShortcutInfos();
    
    // 成功获取快捷方式列表
    hilog.info(DOMAIN, TAG, `getPinShortcutInfos success. Count: ${shortcutInfos.length}`);
    
    // 处理快捷方式数据
    shortcutInfos.forEach((info, index) => {
      hilog.info(DOMAIN, TAG, `Shortcut ${index + 1}: ${JSON.stringify(info)}`);
    });
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `getPinShortcutInfos failed, code: ${err.code}, message: ${err.message}`);
    
    // 错误处理
    handleGetShortcutError(err);
  }
}

// 错误处理函数
function handleGetShortcutError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error. Please check the parameters.');
      break;
    case 1006620001:
      hilog.error(DOMAIN, TAG, 'System internal error.');
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
  }
}
```

### 步骤3：完整UI示例

**完整页面示例**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'GetPinShortcutInfos';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct GetPinShortcutInfosPage {
  @State shortcutList: string[] = [];
  @State isLoading: boolean = false;
  @State errorMsg: string = '';

  build() {
    Column() {
      // 标题
      Text('查询应用内快捷方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      // 查询按钮
      Button("查询快捷方式")
        .width('80%')
        .height(50)
        .fontSize(16)
        .onClick(() => {
          this.queryShortcuts();
        })
        .margin({ bottom: 20 });

      // 加载状态
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      }

      // 错误信息
      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 10 });
      }

      // 快捷方式列表
      if (this.shortcutList.length > 0) {
        Text(`快捷方式列表 (${this.shortcutList.length})`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 10 });

        List() {
          ForEach(this.shortcutList, (item: string, index: number) => {
            ListItem() {
              Text(`${index + 1}. ${item}`)
                .fontSize(14)
                .padding(10)
                .width('100%')
                .backgroundColor('#F5F5F5')
                .borderRadius(5);
            }
            .margin({ bottom: 5 });
          });
        }
        .width('90%')
        .height('40%')
        .margin({ top: 10 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.Start);
  }

  // 查询快捷方式
  private async queryShortcuts(): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    this.shortcutList = [];

    try {
      // 调用getPinShortcutInfos接口获取桌面快捷方式列表信息
      const shortcutInfos = await productViewManager.getPinShortcutInfos();
      
      hilog.info(DOMAIN, TAG, `getPinShortcutInfos success. Count: ${shortcutInfos.length}`);
      
      // 更新UI显示
      this.shortcutList = shortcutInfos.map((info, index) => {
        return `快捷方式 ${index + 1}`;
      });
      
      this.isLoading = false;
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `getPinShortcutInfos error. code is ${err.code}, message is ${err.message}`);
      
      this.isLoading = false;
      this.errorMsg = `查询失败: ${err.message}`;
    }
  }
}
```

### 步骤4：降级处理

**降级处理代码**：
```typescript
async function queryPinShortcutsWithFallback(): Promise<void> {
  try {
    // 主流程：调用API查询快捷方式
    const shortcutInfos = await productViewManager.getPinShortcutInfos();
    hilog.info(DOMAIN, TAG, 'Successfully retrieved shortcut list');
  } catch (error) {
    const err = error as BusinessError;
    
    // 降级方案1：提示用户重试
    if (err.code === 1006620001) {
      hilog.warn(DOMAIN, TAG, 'System internal error, please retry later');
      // 可以显示重试按钮，让用户手动触发重试
      return;
    }
    
    // 降级方案2：提示真机环境要求
    if (err.code === 401) {
      hilog.error(DOMAIN, TAG, 'Device not supported, please use real device');
      // 显示明确的设备要求提示
      return;
    }
    
    // 降级方案3：记录错误日志，提供友好提示
    hilog.error(DOMAIN, TAG, `Query failed: ${err.message}`);
    // 显示友好的错误信息给用户
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误 | 检查API调用参数是否正确，此接口无需参数 |
| 1006620001 | System internal error. 系统内部错误 | 等待系统恢复后重试，或联系技术支持 |
| 其他错误 | 未知错误 | 查看错误信息日志，根据具体错误信息处理 |

**常见错误处理**：
- **参数错误(401)**：此API无需参数，检查是否错误传参
- **系统内部错误(1006620001)**：系统临时故障，建议延迟重试
- **设备不支持**：确认设备类型和API版本是否满足要求

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.PerformanceAnalysisKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS API版本：6.1.1(24)及以上
- 开发工具：DevEco Studio 最新版本
- 运行环境：真机设备（不支持模拟器）
- 设备类型：Phone、Tablet、PC/2in1、TV（6.0.2(22)及以上）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：
- 确认HarmonyOS SDK版本符合要求（6.1.1(24)及以上）
- 在DevEco Studio中检查SDK Manager，确保已安装对应版本的SDK
- 同步项目依赖：File -> Sync Project with Gradle Files

**问题2：API未定义**
```
Error: Property 'getPinShortcutInfos' does not exist on type 'typeof productViewManager'
```
**解决方法**：
- 确认API版本：此接口从6.1.1(24)版本开始支持
- 检查compileSdkVersion配置，确保使用正确的API版本
- 在build-profile.json5中配置正确的compileSdkVersion

**问题3：真机运行失败**
```
Error: Unable to get content, please tap screen to retry
```
**解决方法**：
- 确认使用真机设备而非模拟器
- 检查设备系统版本是否满足要求
- 确认应用已正确签名并安装到真机

## 常见问题与解决方法

### Q1：为什么在模拟器上无法使用此API？
**原因**：应用市场推荐服务不支持模拟器环境
**解决方法**：
- 使用真机设备进行调试
- 在模拟器中调用时会提示"无法获取内容，请点击屏幕重试"
- 确保真机设备系统版本满足API要求

### Q2：调用API后返回空列表
**原因**：当前应用没有已固定在桌面的快捷方式
**解决方法**：
- 确认应用是否已创建过快捷方式
- 先使用`requestNewPinShortcut`创建快捷方式
- 检查用户是否已手动删除了桌面快捷方式

### Q3：如何获取快捷方式的详细信息？
**原因**：需要了解PinShortcutInfo数据结构
**解决方法**：
- API返回`PinShortcutInfo[]`数组，包含快捷方式的详细信息
- 可以遍历数组获取每个快捷方式的具体属性
- 具体数据结构参考API参考文档

### Q4：支持的设备类型有哪些？
**原因**：不同版本支持的设备类型不同
**解决方法**：
- Phone、Tablet、PC/2in1：所有版本均支持
- TV设备：从6.0.2(22)版本开始支持
- 其他设备类型：不支持，调用会返回错误

### Q5：调用频率有限制吗？
**原因**：避免频繁调用影响性能
**解决方法**：
- API本身无明确调用频率限制
- 建议根据实际业务需求合理控制调用频率
- 避免在短时间内频繁查询，影响用户体验

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shortcutCount": "快捷方式数量",
  "shortcutList": "快捷方式列表信息",
  "apiUsed": [
    "productViewManager.getPinShortcutInfos"
  ],
  "deviceInfo": {
    "deviceType": "设备类型",
    "apiVersion": "API版本"
  }
}
```

**成功输出示例**：
```json
{
  "status": "success",
  "shortcutCount": 3,
  "shortcutList": [
    { "id": "shortcut_1", "label": "功能A" },
    { "id": "shortcut_2", "label": "功能B" },
    { "id": "shortcut_3", "label": "功能C" }
  ],
  "apiUsed": ["productViewManager.getPinShortcutInfos"],
  "deviceInfo": {
    "deviceType": "Phone",
    "apiVersion": "6.1.1(24)"
  }
}
```

**失败输出示例**：
```json
{
  "status": "failed",
  "errorCode": 1006620001,
  "errorMessage": "System internal error",
  "suggestion": "请稍后重试或联系技术支持"
}
```

## 参考文档

- [API开发指南 - 查询应用内快捷方式](references/appgallery-productview-getshortcut-guide.md)
- [API参考说明 - productViewManager](references/store-productviewmanager-reference.md)
- [错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-error-code)

## 完整示例代码

- [ArkTS示例 - 查询快捷方式完整实现](assets/query-shortcut-example.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [查询快捷方式成功场景](tests/test_positive.py)：真机环境下成功查询快捷方式列表
- [空列表场景](tests/test_positive.py)：应用无快捷方式时返回空列表

### 边界测试用例
- [多快捷方式场景](tests/test_boundary.py)：查询大量快捷方式列表
- [TV设备测试](tests/test_boundary.py)：验证TV设备支持（6.0.2(22)及以上）

### 异常测试用例
- [模拟器环境测试](tests/test_exception.py)：模拟器环境下调用失败
- [参数错误测试](tests/test_exception.py)：验证参数校验
- [系统错误测试](tests/test_exception.py)：系统内部错误处理