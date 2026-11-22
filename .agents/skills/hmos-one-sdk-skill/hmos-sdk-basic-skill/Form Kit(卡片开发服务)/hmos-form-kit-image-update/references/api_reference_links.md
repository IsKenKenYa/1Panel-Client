# API参考文档链接汇总

本文件汇总了ArkTS卡片图片刷新技能涉及的所有API参考文档链接。

## 核心API参考文档

### FormKit API

1. **FormExtensionAbility API参考**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formextensionability.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability
   - 主要内容：FormExtensionAbility卡片扩展模块，提供卡片创建、销毁、刷新等生命周期回调

2. **formBindingData API参考**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formbindingdata.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata
   - 主要内容：卡片数据绑定模块，提供FormBindingData对象的创建和数据传递能力

3. **formProvider API参考**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formprovider.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider
   - 主要内容：formProvider模块，提供获取卡片信息、更新卡片、设置卡片更新时间等能力

4. **formInfo API参考**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-forminfo
   - 主要内容：formInfo模块，提供卡片信息和状态等相关类型和枚举

### 相关Kit API

5. **fileIo API参考（CoreFileKit）**
   - 文档路径：应用框架/Core File Kit（文件基础服务）/ArkTS API/fileio相关文档
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-corefile-kit-fileio
   - 主要内容：文件IO操作，包括文件打开、读写、关闭等功能

6. **http API参考（NetworkKit）**
   - 文档路径：媒体/Network Kit（网络服务）/ArkTS API/http相关文档
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-network-kit-http
   - 主要内容：HTTP网络请求，用于下载网络图片

## 开发指南文档

7. **API开发指南：刷新本地图片和网络图片**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/ArkTS卡片提供方开发指导/ArkTS卡片页面刷新/刷新本地图片和网络图片/arkts-ui-widget-image-update.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-image-update
   - 主要内容：详细的开发步骤和示例代码，说明如何实现卡片图片刷新

8. **开发指南：声明权限**
   - 文档路径：`系统/安全/程序访问控制/应用权限管控/申请应用权限/声明权限/declare-permissions.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions
   - 主要内容：如何在module.json5中声明应用权限，包括INTERNET权限

## 错误码文档

9. **卡片错误码参考**
   - 文档路径：`应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md`
   - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-form
   - 主要内容：FormKit相关错误码定义和解决方法

10. **通用错误码参考**
    - 文档路径：`API参考概述/errorcode-universal.md`
    - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal
    - 主要内容：通用错误码定义，包括参数错误等常见错误

## 其他相关文档

11. **ArkTS卡片配置文件**
    - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/配置ArkTS卡片的配置文件/arkts-ui-widget-configuration.md`
    - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration
    - 主要内容：form_config.json配置文件说明

12. **卡片页面刷新概述**
    - 文档路径：`应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/ArkTS卡片提供方开发指导/ArkTS卡片页面刷新/ArkTS卡片页面刷新概述/arkts-ui-widget-interaction-overview.md`
    - 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview
    - 主要内容：卡片页面刷新的整体介绍

## API版本说明

- **API version 9**：FormExtensionAbility、formBindingData、formProvider、formInfo等核心API首次支持
- **API version 10**：ProxyData、LaunchReason、FormParam.PARAM_FORM_CUSTOMIZE_KEY等新增
- **API version 11**：元服务API支持、displayName、transparencyEnabled等新增
- **API version 12**：FormShape、DIMENSION_6_4等新增
- **API version 18**：openFormEditAbility、openFormManager、DIMENSION_2_3、DIMENSION_3_3等新增
- **API version 19**：图片限制5张、单张2MB
- **API version 20**：图片限制20张、总数据10MB、requestOverflow、cancelOverflow等新增

## 注意事项

1. **FormExtensionAbility存活时间限制**：
   - 创建后10秒内无操作会被清理
   - 网络下载必须在5秒内完成

2. **图片大小和数量限制**：
   - API version 19及之前：单张≤2MB，总数≤5张
   - API version 20：总数据≤10MB，总数≤20张

3. **不支持模块**：
   - 在FormExtensionAbility中不能引用音频、相机等模块
   - 参见FormExtensionAbility文档中的不支持模块列表

4. **文件描述符生命周期**：
   - fd在FormExtensionAbility进程销毁时自动释放
   - 需要使用fileIo.closeSync正确关闭文件

## 本地文档路径

所有API参考文档的本地路径位于：
```
D:\code\APIDevice\output\md_output\harmonyos-references\
```

开发指南文档的本地路径位于：
```
D:\code\APIDevice\output\md_output\harmonyos-guides\
```

可通过上述路径访问完整的API定义和详细说明。