---
name: hmos-form-kit-image-update
description: 在ArkTS卡片上刷新展示本地图片和网络图片，支持通过文件描述符传递图片数据，限制FormExtensionAbility存活5秒内完成网络下载，适用于卡片图片动态刷新、网络图片更新场景
---

# ArkTS卡片图片刷新技能

## 功能描述

本技能实现ArkTS卡片上展示和刷新本地图片、网络图片的能力。通过FormExtensionAbility的生命周期回调，使用文件描述符(fd)方式传递图片数据给卡片页面，支持本地图片的即时展示和网络图片的异步下载刷新。

**核心能力**：
- 本地图片刷新：通过onAddForm回调传递本地图片fd给卡片页面
- 网络图片刷新：通过onFormEvent回调异步下载网络图片并更新卡片
- 图片数据传递：使用formBindingData的formImages字段传递fd数据
- 卡片页面渲染：通过Image组件的memory://协议加载图片

**技术特点**：
- 使用fileIo.openSync获取文件描述符
- 使用http.createHttp下载网络图片
- FormExtensionAbility进程限制5秒存活时间
- 图片通过文件描述符而非路径传递

## 使用场景

### 触发词
- "卡片刷新图片"
- "卡片显示图片"
- "卡片网络图片"
- "卡片本地图片"
- "ArkTS卡片图片"

### 能做
- 在卡片添加时展示本地图片
- 通过卡片事件触发刷新网络图片
- 传递图片文件描述符给卡片页面
- 处理网络图片下载和本地保存
- 更新卡片显示的图片内容

### 绝不做
- 不支持超过5秒的网络图片下载（FormExtensionAbility存活限制）
- 不支持超过2MB的单张图片（API version 19及之前）
- 不支持超过5张图片同时显示（API version 19及之前）
- 不支持超过20张图片同时显示（API version 20）
- 不支持超过10MB的总数据大小（API version 20）
- 不直接传递图片路径（必须使用fd）

### 补充
- 网络图片下载必须在5秒内完成，否则FormExtensionAbility会被销毁
- 图片文件描述符在FormExtensionAbility进程销毁时释放
- Image组件使用memory://fileName格式加载图片
- imgName必须每次不同才能触发图片刷新

## 调用规范和规则

### 输入约束
- 图片格式：支持PNG/JPG等常见图片格式
- 本地图片路径：应用tempDir目录下的文件路径
- 网络图片URL：有效的HTTP/HTTPS链接
- 图片大小：单张≤2MB（API version 19），单张≤10MB（API version 20）
- 图片数量：≤5张（API version 19），≤20张（API version 20）
- 网络权限：必须申请ohos.permission.INTERNET权限

### 执行约束
- FormExtensionAbility存活时间：≤5秒
- 网络图片下载耗时：≤5秒
- 文件操作：使用fileIo.openSync获取fd
- http请求：使用http.createHttp发起请求

### 内容约束
- 禁止直接传递图片文件路径给卡片
- 禁止在formImages字段使用文件路径
- 禁止使用超过限制大小的图片
- 禁止在FormExtensionAbility中引用音频、相机等不支持模块
- 必须使用formImages字段传递图片fd
- 必须使用memory://协议加载图片

### 降级约束
- 网络下载超时：提示"刷新失败"，停止下载
- 文件打开失败：记录错误日志，返回空数据
- 图片超过限制：提示用户使用较小图片
- 权限未申请：提示用户申请INTERNET权限

## 调用流程和步骤

### 步骤1：权限申请和环境准备

**前置校验**：
1. 在module.json5中申请ohos.permission.INTERNET权限
2. 准备本地图片文件（如应用tempDir下的head.PNG）
3. 确认FormExtensionAbility扩展能力已配置

**权限配置**：
```json
// entry/src/main/module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 步骤2：导入必要模块

**示例代码**：
```typescript
// entry/src/main/ets/formability/WgtImgUpdateEntryFormAbility.ts
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
```

### 步骤3：实现onAddForm回调（本地图片刷新）

**功能说明**：在卡片添加时，打开本地图片并传递文件描述符给卡片页面。

**示例代码**：
```typescript
export default class WgtImgUpdateEntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const TAG: string = 'WgtImgUpdateEntryFormAbility';
    const DOMAIN_NUMBER: number = 0xFF00;
    
    let tempDir = this.context.getApplicationContext().tempDir;
    hilog.info(DOMAIN_NUMBER, TAG, `tempDir: ${tempDir}`);
    
    let imgMap: Record<string, number> = {};
    try {
      let file = fileIo.openSync(tempDir + '/' + 'head.PNG');
      imgMap['imgBear'] = file.fd;
    } catch (e) {
      hilog.error(DOMAIN_NUMBER, TAG, `openSync failed: ${JSON.stringify(e as BusinessError)}`);
    }
    
    class FormDataClass {
      text: string = 'Image: Bear';
      loaded: boolean = true;
      imgName: string = 'imgBear';
      formImages: Record<string, number> = imgMap;
    }
    
    let formData = new FormDataClass();
    return formBindingData.createFormBindingData(formData);
  }
}
```

**关键说明**：
- fileIo.openSync返回文件对象，包含fd字段
- imgMap['imgBear'] = file.fd：key必须和imgName相同
- formImages字段是必填项，用于传递图片fd数据

### 步骤4：实现onFormEvent回调（网络图片刷新）

**功能说明**：接收卡片事件消息，下载网络图片并更新卡片显示。

**示例代码**：
```typescript
export default class WgtImgUpdateEntryFormAbility extends FormExtensionAbility {
  async onFormEvent(formId: string, message: string): Promise<void> {
    const TAG: string = 'WgtImgUpdateEntryFormAbility';
    const DOMAIN_NUMBER: number = 0xFF00;
    const TEXT1: string = '刷新中...'
    const TEXT2: string = '刷新失败'
    
    let param: Record<string, string> = {
      'text': TEXT1
    };
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
    formProvider.updateForm(formId, formInfo);
    
    let netFile = 'https://example.com/image.jpg';
    let tempDir = this.context.getApplicationContext().tempDir;
    let fileName = 'file' + Date.now();
    let tmpFile = tempDir + '/' + fileName;
    let imgMap: Record<string, number> = {};
    
    class FormDataClass {
      text: string = 'Image: ' + fileName;
      loaded: boolean = true;
      imgName: string = fileName;
      formImages: Record<string, number> = imgMap;
    }
    
    let httpRequest = http.createHttp()
    let data = await httpRequest.request(netFile);
    
    if (data?.responseCode == http.ResponseCode.OK) {
      try {
        let imgFile = fileIo.openSync(tmpFile, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        imgMap[fileName] = imgFile.fd;
        
        try {
          let writeLen: number = await fileIo.write(imgFile.fd, data.result as ArrayBuffer);
          hilog.info(DOMAIN_NUMBER, TAG, "write data to file succeed and size is:" + writeLen);
          
          try {
            let formData = new FormDataClass();
            let formInfo = formBindingData.createFormBindingData(formData);
            await formProvider.updateForm(formId, formInfo);
            hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
          } catch (error) {
            hilog.error(DOMAIN_NUMBER, TAG, `FormAbility updateForm failed: ${JSON.stringify(error)}`);
          }
        } catch (err) {
          hilog.error(DOMAIN_NUMBER, TAG, "write data to file failed: " + err.message);
        } finally {
          fileIo.closeSync(imgFile);
        }
      } catch (e) {
        hilog.error(DOMAIN_NUMBER, TAG, `openSync failed: ${JSON.stringify(e as BusinessError)}`);
      }
    } else {
      hilog.error(DOMAIN_NUMBER, TAG, `ArkTSCard download task failed`);
      let param: Record<string, string> = {
        'text': TEXT2
      };
      let formInfo = formBindingData.createFormBindingData(param);
      formProvider.updateForm(formId, formInfo);
    }
    
    httpRequest.destroy();
  }
}
```

**关键说明**：
- fileName必须每次不同（使用Date.now()），否则图片不会刷新
- 网络下载必须在5秒内完成
- 图片下载后写入临时文件，再通过fd传递
- 使用fileIo.closeSync关闭文件

### 步骤5：卡片页面实现

**功能说明**：在卡片页面通过backgroundImage或Image组件展示图片。

**示例代码**：
```typescript
// entry/src/main/ets/widget/pages/WidgetCard.ets
let storage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetImageUpdateCard {
  @LocalStorageProp('text') text: ResourceStr = '加载中...';
  @LocalStorageProp('loaded') loaded: boolean = false;
  @LocalStorageProp('imgName') imgName: ResourceStr = '';
  
  build() {
    Column() {
      Column() {
        Text(this.text)
          .fontColor('#FFFFFF')
          .fontSize(12)
          .margin({ top: '8%', left: '10%' })
      }
      .width('100%')
      .height('50%')
      
      Row() {
        Button('刷新图片')
          .width(120)
          .height(32)
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: {
                info: 'refreshImage'
              }
            });
          })
      }
      .width('100%')
      .height('40%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundImage(this.loaded ? 'memory://' + this.imgName : $r('app.media.placeholder'))
    .backgroundImageSize(ImageSize.Cover)
  }
}
```

**关键说明**：
- Image组件使用memory://fileName格式加载图片
- fileName对应formImages中的key
- 通过postCardAction触发onFormEvent回调

### 步骤6：错误处理

**错误处理代码**：
```typescript
try {
  await formProvider.updateForm(formId, formInfo);
} catch (error) {
  let err = error as BusinessError;
  hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed, code: ${err.code}, message: ${err.message}`);
  
  if (err.code === 16501001) {
    hilog.error(DOMAIN_NUMBER, TAG, 'Form ID does not exist');
  } else if (err.code === 16501003) {
    hilog.error(DOMAIN_NUMBER, TAG, 'Form cannot be operated by current app');
  }
}
```

### 步骤7：降级处理

**降级处理代码**：
```typescript
async function downloadImageWithFallback(url: string): Promise<void> {
  try {
    let httpRequest = http.createHttp();
    let data = await httpRequest.request(url);
    
    if (data?.responseCode !== http.ResponseCode.OK) {
      throw new Error('Download failed');
    }
    
    // 正常处理下载结果
    await processImage(data.result as ArrayBuffer);
  } catch (error) {
    hilog.error(DOMAIN_NUMBER, TAG, 'Primary download failed, try fallback');
    
    // 降级方案：使用预设的备用图片URL
    let fallbackUrl = 'https://fallback.example.com/image.jpg';
    try {
      let httpRequest = http.createHttp();
      let data = await httpRequest.request(fallbackUrl);
      await processImage(data.result as ArrayBuffer);
    } catch (fallbackError) {
      // 最终降级：使用本地默认图片
      hilog.error(DOMAIN_NUMBER, TAG, 'Fallback also failed, use local image');
      useLocalDefaultImage();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。必填参数未指定、参数类型错误或参数校验失败 | 检查参数类型和取值范围，确保formId、formBindingData等参数正确 |
| 16500050 | IPC连接错误 | 检查系统服务连接状态，重试操作 |
| 16500060 | 服务连接错误 | 检查FormKit服务状态，重启应用或设备 |
| 16500100 | 获取配置信息失败 | 检查module.json5配置，确保form_config.json正确 |
| 16501000 | 内部功能错误 | 检查代码逻辑，查看详细日志定位问题 |
| 16501001 | 操作的卡片ID不存在 | 确认formId是否正确，检查卡片是否已删除 |
| 16501002 | 卡片数量超过最大限制 | 减少同时显示的卡片数量 |
| 16501003 | 当前应用无法操作此卡片 | 确认卡片归属，只有卡片提供方才能操作 |
| 16501011 | 卡片不支持此操作 | 确认卡片类型和API版本是否支持该操作 |

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**oh-package.json5依赖**：
```json
{
  "dependencies": {
    "@kit.FormKit": "标准系统Kit",
    "@kit.AbilityKit": "标准系统Kit",
    "@kit.CoreFileKit": "标准系统Kit",
    "@kit.NetworkKit": "标准系统Kit",
    "@kit.BasicServicesKit": "标准系统Kit"
  }
}
```

### 环境要求
- HarmonyOS API version 9及以上
- DevEco Studio 3.1及以上
- Stage模型应用

### 常见编译问题

**问题1：权限未声明**
```
Error: ohos.permission.INTERNET permission not declared
```
**解决方法**：在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**问题2：导入模块失败**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**：确保使用正确的导入语法：
```typescript
import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
```

**问题3：FormExtensionAbility未配置**
```
Error: FormExtensionAbility not found in module.json5
```
**解决方法**：在module.json5的extensionAbilities中添加：
```json
{
  "extensionAbilities": [
    {
      "name": "WgtImgUpdateEntryFormAbility",
      "srcEntry": "./ets/formability/WgtImgUpdateEntryFormAbility.ts",
      "type": "form",
      "label": "$string:form_ability_label",
      "description": "$string:form_ability_desc",
      "metadata": [
        {
          "name": "ohos.extension.form",
          "resource": "$profile:form_config"
        }
      ]
    }
  ]
}
```

**问题4：图片超过限制大小**
```
Error: Image size exceeds 2MB limit
```
**解决方法**：压缩图片或使用较小尺寸的图片，确保单张图片≤2MB（API version 19）

**问题5：网络下载超时**
```
Error: Download timeout, FormExtensionAbility destroyed
```
**解决方法**：使用更快的网络链接或更小的图片，确保下载在5秒内完成

## 常见问题与解决方法

### Q1：图片在卡片上不显示
**原因**：
- formImages字段未正确传递
- imgName和formImages的key不一致
- 图片文件打开失败

**解决方法**：
- 确保formImages字段包含图片fd
- 确保imgName值和formImages的key相同
- 检查fileIo.openSync是否成功返回fd
- 查看hilog日志确认错误信息

### Q2：网络图片刷新失败
**原因**：
- 网络下载超过5秒
- INTERNET权限未申请
- 网络链接无效

**解决方法**：
- 使用更快的网络链接或更小的图片
- 在module.json5中申请ohos.permission.INTERNET权限
- 确认网络图片URL有效且可访问
- 检查http.request的responseCode是否为OK

### Q3：图片连续刷新不生效
**原因**：
- imgName每次传递相同值
- Image组件检测到参数无变化

**解决方法**：
- 每次刷新使用不同的imgName（如'file' + Date.now()）
- 确保每次传递的fileName都不同
- 参考示例代码中的fileName生成方式

### Q4：FormExtensionAbility进程异常退出
**原因**：
- 在FormExtensionAbility中引用了不支持模块
- 进程存活超过10秒
- 下载图片超过5秒

**解决方法**：
- 不在FormExtensionAbility中引用音频、相机等不支持模块
- 确保所有操作在5秒内完成
- 参考文档列出的不支持模块列表

### Q5：图片fd释放导致显示异常
**原因**：
- FormExtensionAbility进程销毁时fd自动释放
- 文件未正确关闭

**解决方法**：
- 理解fd在进程销毁时自动释放的特性
- 使用fileIo.closeSync正确关闭文件
- 在onRemoveForm中清理临时文件

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "cardImageUpdated": true,
  "imageType": "network",
  "imageSize": "150KB",
  "downloadTime": "2.3s",
  "formId": "12400633174999288",
  "imgName": "file1704038400000",
  "apiUsed": [
    "FormExtensionAbility.onAddForm",
    "FormExtensionAbility.onFormEvent",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm",
    "fileIo.openSync",
    "fileIo.write",
    "fileIo.closeSync",
    "http.createHttp",
    "http.request",
    "postCardAction"
  ],
  "errors": [],
  "warnings": []
}
```

## 参考文档

- [API开发指南：刷新本地图片和网络图片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-image-update)
- [API参考：FormExtensionAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [API参考：formBindingData](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [API参考：formProvider](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [API参考：formInfo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-forminfo)
- [API参考：fileIo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-corefile-kit-fileio)
- [API参考：http](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-network-kit-http)
- [开发指南：声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)

## 完整示例代码

- [ArkTS卡片FormExtensionAbility完整示例](assets/WgtImgUpdateEntryFormAbility.ets)
- [ArkTS卡片页面完整示例](assets/WidgetImageUpdateCard.ets)
- [module.json5配置示例](assets/module.json5)
- [form_config.json配置示例](assets/form_config.json)

## 测试用例

### 正向测试用例
- [本地图片刷新测试](tests/test_local_image_refresh.ts)：验证本地图片通过onAddForm成功传递给卡片
- [网络图片刷新测试](tests/test_network_image_refresh.ts)：验证网络图片通过onFormEvent成功下载并更新卡片
- [多图片显示测试](tests/test_multiple_images.ts)：验证同时显示多张图片（不超过限制）

### 辺界测试用例
- [图片大小限制测试](tests/test_image_size_limit.ts)：验证单张图片大小不超过2MB（API version 19）
- [图片数量限制测试](tests/test_image_count_limit.ts)：验证图片数量不超过5张（API version 19）
- [下载时间限制测试](tests/test_download_time_limit.ts)：验证网络下载在5秒内完成

### 异常测试用例
- [权限未申请测试](tests/test_permission_missing.ts)：验证未申请INTERNET权限时的错误处理
- [网络链接无效测试](tests/test_invalid_url.ts)：验证无效网络链接的错误处理
- [文件打开失败测试](tests/test_file_open_failed.ts)：验证文件打开失败时的错误处理
- [下载超时测试](tests/test_download_timeout.ts)：验证下载超过5秒时的降级处理