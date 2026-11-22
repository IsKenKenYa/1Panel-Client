---
name: hmos-map-kit-my-location
description: 在地图上显示和自定义我的位置图标,支持定位权限管理、位置获取、图标样式设置和图层顺序控制,需要位置权限,适用于地图导航、位置共享、周边服务查找场景
---

# 显示我的位置技能

## 功能描述

本技能实现在HarmonyOS地图上显示用户当前位置("我的位置")功能,包括启用/禁用我的位置图层、控制位置按钮显示、设置自定义位置图标样式、监听位置按钮点击事件以及调整我的位置图层相对于覆盖物的压盖顺序。支持Map Kit默认定位和Location Kit自定义定位两种方式,适用于地图导航、位置共享、周边服务查找等场景。

**核心功能**:
- 启用/禁用"我的位置"图层功能
- 控制位置按钮显示与隐藏
- 设置自定义位置坐标(Location Kit集成)
- 自定义位置图标样式(图标、锚点、填充色等)
- 监听位置按钮点击事件
- 调整我的位置图层压盖顺序

**技术特点**:
- 使用WGS84坐标系
- 支持Stage模型
- 需要位置权限(ohos.permission.LOCATION、ohos.permission.APPROXIMATELY_LOCATION)
- API版本要求: 4.1.0(11)及以上
- 支持元服务API(从4.1.0(11)开始)

## 使用场景

### 触发词
- "显示我的位置"
- "地图定位"
- "显示当前位置"
- "地图位置图标"
- "自定义位置图标"
- "我的位置按钮"
- "地图定位权限"

### 能做
- 在地图上显示用户当前位置的蓝色圆点图标
- 启用或禁用我的位置图层功能
- 显示或隐藏我的位置按钮
- 自定义位置图标样式(图标图片、锚点位置、精度圆填充色)
- 监听我的位置按钮点击事件并自定义处理逻辑
- 调整我的位置图层相对于其他覆盖物的显示顺序
- 集成Location Kit获取自定义定位结果并显示在地图上
- 申请和管理位置权限

### 绝不做
- 不处理与地图位置显示无关的功能(如路线规划、POI搜索)
- 不提供地图初始化和基础配置功能
- 不处理地理编码和逆地理编码功能
- 不提供地图标记、覆盖物等其他地图元素的管理
- 不处理地图相机移动和视角控制

### 补充
- 从6.0.1(21)开始支持更改我的位置相对覆盖物的顺序
- 我的位置图层功能开关打开后,位置按钮默认显示在地图右下角
- 点击我的位置按钮会在屏幕中心显示当前定位,以蓝色圆点形式呈现
- Map Kit默认使用系统的连续定位能力显示用户位置
- 如需定制定位频率或精度,需集成Location Kit获取位置后传给Map Kit
- 使用WGS84坐标系,需注意与其他坐标系的转换

## 调用规范和规则

### 输入约束
- 地图控制器对象: 必须是有效的map.MapComponentController实例
- 位置坐标: 使用WGS84坐标系,纬度范围[-90, 90],经度范围[-180, 180]
- 位置样式参数:
  - 图标文件: 支持常见图片格式(png, jpg等),存放在resources/rawfile目录
  - 锚点值: anchorU和anchorV范围为[0, 1]
  - 精度圆填充色: 32位ARGB颜色值(0xAARRGGBB)
- 权限配置: module.json5中必须声明位置权限

### 执行约束
- 最大定位超时: 5000毫秒(单次定位)
- 地图初始化: 必须在MapComponent初始化回调成功后才能调用位置相关API
- 权限校验: 必须在获得用户授权后才能启用我的位置功能
- 异步调用: setMyLocationStyle返回Promise,需使用await或then处理

### 内容约束
- 禁止在未获取地图控制器前调用位置相关API
- 禁止在未授权位置权限的情况下强制启用位置功能
- 禁止使用非WGS84坐标系的坐标数据
- 禁止在高频循环中调用setMyLocation(建议间隔≥1秒)
- 禁止在UI主线程执行耗时定位操作

### 降级约束
- 权限被拒绝: 提示用户位置功能不可用,提供手动设置引导
- 定位失败: 显示默认位置或提示定位失败,不阻塞地图其他功能
- 地图初始化失败: 记录错误日志,不执行位置相关操作
- 图标资源加载失败: 使用默认位置图标样式

## 调用流程和步骤

### 步骤1: 配置权限

**前置准备**:
在module.json5中声明位置权限,并在resources/base/element/string.json中添加权限说明文本。

**配置示例**:
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:location_permission",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:fuzzy_location_permission",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 步骤2: 初始化地图并校验权限

**初始化流程**:
1. 创建MapComponent组件并设置地图参数
2. 在初始化回调中获取MapComponentController
3. 校验应用是否已授予位置权限
4. 如未授权,向用户申请权限

**示例代码**:
```typescript
import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError, AsyncCallback } from '@kit.BasicServicesKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';

@Entry
@Component
struct MapLocationDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    // 设置地图中心点和缩放级别
    this.mapOptions = {
      position: {
        target: { latitude: 39.9, longitude: 116.4 },
        zoom: 10
      }
    };

    // 地图初始化回调
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        
        // 校验权限
        let permission = await this.checkPermissions();
        if (!permission) {
          this.requestPermissions();
          // 仅启用按钮,等待授权后再启用图层
          this.mapController?.setMyLocationControlsEnabled(true);
        }
      } else {
        console.error(`Map init failed: ${err.code}, ${err.message}`);
      }
    };
  }

  async checkPermissions(): Promise<boolean> {
    const permissions: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    for (let permission of permissions) {
      let grantStatus = await this.checkAccessToken(permission);
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        // 权限已授予,启用我的位置功能
        this.mapController?.setMyLocationEnabled(true);
        this.mapController?.setMyLocationControlsEnabled(true);
        return true;
      }
    }
    return false;
  }

  requestPermissions(): void {
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(
      this.getUIContext().getHostContext() as common.UIAbilityContext,
      ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION']
    ).then((data: PermissionRequestResult) => {
      // 用户授权后启用我的位置图层
      this.mapController?.setMyLocationEnabled(true);
    }).catch((err: BusinessError) => {
      console.error(`Permission request failed: ${err.code}, ${err.message}`);
    });
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager = abilityAccessCtrl.createAtManager();
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let tokenId = bundleInfo.appInfo.accessTokenId;
    return await atManager.checkAccessToken(tokenId, permission);
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%');
    }
  }
}
```

### 步骤3: 启用我的位置功能

**调用API**:
使用MapComponentController的setMyLocationEnabled和setMyLocationControlsEnabled方法。

**示例代码**:
```typescript
// 启用我的位置图层(使用Map Kit默认定位)
this.mapController?.setMyLocationEnabled(true);

// 启用我的位置按钮
this.mapController?.setMyLocationControlsEnabled(true);
```

**说明**:
- setMyLocationEnabled(true): 开启我的位置图层,使用系统连续定位显示用户位置
- setMyLocationControlsEnabled(true): 显示我的位置按钮(默认右下角)
- 必须在获得位置权限后才调用setMyLocationEnabled(true)

### 步骤4: 使用Location Kit自定义定位(可选)

**场景说明**:
如果需要自定义定位精度或频率,可使用Location Kit获取位置后传给Map Kit。

**示例代码**:
```typescript
import { geoLocationManager } from '@kit.LocationKit';

async setCustomLocation(): Promise<void> {
  try {
    // 获取用户位置(WGS84坐标系)
    let location = await geoLocationManager.getCurrentLocation();
    
    // 设置我的位置坐标
    this.mapController?.setMyLocation(location);
    
    console.info(`Location: ${location.latitude}, ${location.longitude}`);
  } catch (error) {
    console.error('Failed to get location:', error);
  }
}
```

### 步骤5: 自定义位置图标样式

**样式参数**:
- icon: 自定义图标文件路径(相对于resources/rawfile)
- anchorU: 锚点水平位置[0, 1]
- anchorV: 锚点垂直位置[0, 1]
- radiusFillColor: 精度圆填充色(32位ARGB)

**示例代码**:
```typescript
async customizeLocationIcon(): Promise<void> {
  let style: mapCommon.MyLocationStyle = {
    anchorU: 0.5,
    anchorV: 0.5,
    radiusFillColor: 0x66FF0000, // 半透明红色
    icon: 'custom_location.png'  // 图标存放在resources/rawfile/
  };
  
  await this.mapController?.setMyLocationStyle(style);
  console.info('Location style updated');
}
```

### 步骤6: 监听位置按钮点击事件

**事件监听**:
通过MapEventManager监听myLocationButtonClick事件。

**示例代码**:
```typescript
setupLocationButtonListener(): void {
  let callback = () => {
    console.info('My location button clicked');
    // 自定义点击处理逻辑
  };
  
  this.mapEventManager?.on('myLocationButtonClick', callback);
}

// 取消监听
removeLocationButtonListener(): void {
  let callback = () => {
    console.info('My location button clicked');
  };
  
  this.mapEventManager?.off('myLocationButtonClick', callback);
}
```

**说明**:
- 设置监听后,点击位置按钮将执行自定义逻辑,不再执行默认行为(移动到用户位置)
- 未设置监听时,点击按钮会自动将地图中心移动到当前用户位置

### 步骤7: 调整位置图层顺序

**功能说明**:
从API 6.0.1(21)开始,支持更改我的位置图层相对于覆盖物的压盖顺序。

**示例代码**:
```typescript
// true: 我的位置图层位于覆盖物之下
// false: 我的位置图层位于覆盖物之上(默认)
this.mapController?.changeMyLocationLayerOrder(true);
```

### 步骤8: 隐藏我的位置按钮

**示例代码**:
```typescript
// 隐藏位置按钮
this.mapController?.setMyLocationControlsEnabled(false);

// 禁用我的位置图层
this.mapController?.setMyLocationEnabled(false);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 检查module.json5中是否声明ohos.permission.LOCATION权限,并引导用户授权 |
| 401 | 参数类型错误 | 检查传入参数类型是否正确,Location对象需包含latitude和longitude字段 |
| 801 | 该设备不支持此API | 检查设备系统版本是否满足API最低版本要求(4.1.0(11)) |
| 1900001 | 地图服务内部错误 | 检查MapComponent是否初始化成功,查看日志获取详细错误信息 |
| 1900002 | 地图服务网络错误 | 检查网络连接状态,确保设备能访问地图服务 |
| 1900003 | 地图服务未初始化 | 确保在MapComponent初始化回调成功后再调用地图API |
| 3301000 | 位置服务不可用 | 检查设备位置开关是否打开,位置服务是否正常 |
| 3301100 | 定位失败 | 检查位置权限、网络连接、GPS信号等,尝试重新定位 |
| 3301200 | 地理编码失败 | 检查输入的地址信息是否合法,确保网络连接正常 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**:
```json
{
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.LocationKit": "^4.1.0",
    "@kit.AbilityKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: 4.1.0(11)及以上
- DevEco Studio: 4.0及以上
- 目标设备: 支持Stage模型的HarmonyOS设备
- 开发语言: ArkTS

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.MapKit' or its corresponding type declarations.
```
**解决方法**: 确保在oh-package.json5中添加MapKit依赖,并运行`ohpm install`

**问题2: 权限类型错误**
```
Error: Type 'string' is not assignable to type 'Permissions'.
```
**解决方法**: 使用正确的权限类型导入:
```typescript
import { Permissions } from '@kit.AbilityKit';
const permissions: Permissions[] = ['ohos.permission.LOCATION'];
```

**问题3: MapComponent未找到**
```
Error: Cannot find name 'MapComponent'.
```
**解决方法**: 确保正确导入MapComponent:
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
```

**问题4: Location类型不匹配**
```
Error: Type 'Location' is not assignable to parameter of type 'Location'.
```
**解决方法**: 确保使用geoLocationManager.Location类型:
```typescript
import { geoLocationManager } from '@kit.LocationKit';
let location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation();
```

## 常见问题与解决方法

### Q1: 地图上不显示我的位置图标
**原因**: 
- 未授予位置权限
- 未调用setMyLocationEnabled(true)
- 地图初始化失败

**解决方法**:
1. 检查module.json5中是否声明位置权限
2. 在运行时向用户申请权限
3. 确认MapComponent初始化回调成功后再启用位置功能
4. 查看日志确认是否有错误信息

### Q2: 点击我的位置按钮无反应
**原因**: 
- 未启用我的位置图层
- 位置按钮未显示
- 定位服务未开启

**解决方法**:
1. 确保调用setMyLocationEnabled(true)
2. 确保调用setMyLocationControlsEnabled(true)
3. 检查设备位置服务是否开启
4. 检查是否设置了myLocationButtonClick监听(会覆盖默认行为)

### Q3: 自定义位置图标不显示
**原因**: 
- 图标文件路径错误
- 图标文件格式不支持
- 图标文件未放在resources/rawfile目录

**解决方法**:
1. 确认图标文件已正确放置在resources/rawfile目录
2. 检查icon参数是否为相对于rawfile的路径(不含rawfile前缀)
3. 使用常见的图片格式(png, jpg)
4. 检查图标文件大小是否合理(建议<100KB)

### Q4: 定位精度低或定位失败
**原因**: 
- 设备GPS信号弱
- 网络定位不可用
- 位置服务未开启
- 未授予精确定位权限

**解决方法**:
1. 确保设备位置服务已开启
2. 在室外或靠近窗户处测试GPS定位
3. 检查网络连接状态
4. 授予ohos.permission.LOCATION权限(精确定位)
5. 可通过Location Kit设置更高的定位精度参数

### Q5: 位置权限申请被拒绝
**原因**: 
- 用户拒绝了权限申请
- reason字段未配置或配置不正确

**解决方法**:
1. 在module.json5中正确配置reason字段
2. 在resources/base/element/string.json中添加权限说明文本
3. 在申请权限前向用户解释为何需要位置权限
4. 引导用户到设置页面手动授予权限

### Q6: 我的位置图层被其他覆盖物遮挡
**原因**: 
- 默认情况下,我的位置图层在其他覆盖物之上
- 从API 6.0.1(21)开始可调整图层顺序

**解决方法**:
```typescript
// 设置我的位置图层位于覆盖物之下
this.mapController?.changeMyLocationLayerOrder(true);
```

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "function": "显示我的位置",
  "apis_used": [
    "MapComponentController.setMyLocationEnabled",
    "MapComponentController.setMyLocationControlsEnabled",
    "MapComponentController.setMyLocation",
    "MapComponentController.setMyLocationStyle",
    "MapComponentController.changeMyLocationLayerOrder",
    "MapEventManager.on('myLocationButtonClick')",
    "MapEventManager.off('myLocationButtonClick')",
    "geoLocationManager.getCurrentLocation"
  ],
  "permissions_required": [
    "ohos.permission.LOCATION",
    "ohos.permission.APPROXIMATELY_LOCATION"
  ],
  "min_api_version": "4.1.0(11)",
  "coordinate_system": "WGS84"
}
```

## 参考文档

- [API开发指南: 显示我的位置](references/map-location-guide.md)
- [API参考: MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考: geoLocationManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)
- [API参考: MyLocationStyle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考: MapEventManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapeventmanager)
- [开发指导: 申请位置权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)

## 完整示例代码

- [ArkTS示例: 显示我的位置](assets/map-location-demo.ets)
- [权限配置示例](assets/module.json5)
- [字符串资源配置](assets/string.json)

## 测试用例

### 正向测试用例
- [测试: 启用我的位置功能](tests/test_enable_my_location.ets) - 验证我的位置图层和按钮正常显示
- [测试: 自定义位置图标](tests/test_custom_location_icon.ets) - 验证自定义图标样式生效
- [测试: Location Kit集成定位](tests/test_location_kit_integration.ets) - 验证自定义定位结果显示
- [测试: 监听位置按钮点击](tests/test_location_button_listener.ets) - 验证按钮点击事件正常触发

### 边界测试用例
- [测试: 权限被拒绝场景](tests/test_permission_denied.ets) - 验证权限拒绝时的降级处理
- [测试: 定位失败场景](tests/test_location_failed.ets) - 验证定位失败时的错误处理
- [测试: 地图未初始化场景](tests/test_map_not_initialized.ets) - 验证未初始化时的API调用防护

### 异常测试用例
- [测试: 无效坐标参数](tests/test_invalid_coordinates.ets) - 验证非法坐标值的错误处理
- [测试: 图标资源不存在](tests/test_icon_not_found.ets) - 验证图标文件缺失时的降级方案
- [测试: 网络异常场景](tests/test_network_error.ets) - 验证网络异常时的容错处理