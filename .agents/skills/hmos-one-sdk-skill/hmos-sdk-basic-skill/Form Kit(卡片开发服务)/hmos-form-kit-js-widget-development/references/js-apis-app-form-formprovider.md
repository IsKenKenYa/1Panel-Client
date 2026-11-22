# @ohos.app.form.formProvider (formProvider)
---
# @ohos.app.form.formProvider (formProvider)
formProvider模块提供了获取卡片信息、更新卡片、设置卡片更新时间等能力。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/hJlWe9-jS-aHkIc3Cc-ZkQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=7F1DD1C0F3BDDF7D4203BBFF7C65412D5551C17A5B05F17FA97E9D8921D166F1)
本模块首批接口从API version 9开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
#### 导入模块
```
import { formProvider } from '@kit.FormKit';
```
#### formProvider.setFormNextRefreshTime
setFormNextRefreshTime(formId: string, minute: number, callback: AsyncCallback<void>): void
设置指定卡片的下一次更新时间，使用callback异步回调。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片标识。 |
| minute | number | 是 | 指定卡片多久之后更新，取值范围：大于等于5，单位：min。 |
| callback | AsyncCallback<void> | 是 | 回调函数。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501002 | The number of forms exceeds the maximum allowed. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
try {
  formProvider.setFormNextRefreshTime(formId, 5, (error: BusinessError) => {
    if (error) {
      console.error(`callback error, code: ${error.code}, message: ${error.message})`);
      return;
    }
    console.info(`formProvider setFormNextRefreshTime success`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.setFormNextRefreshTime
setFormNextRefreshTime(formId: string, minute: number): Promise<void>
设置指定卡片的下一次更新时间，使用Promise异步回调。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片标识。 |
| minute | number | 是 | 指定卡片多久之后更新，取值范围：大于等于5，单位：min。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501002 | The number of forms exceeds the maximum allowed. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
try {
  formProvider.setFormNextRefreshTime(formId, 5).then(() => {
    console.info(`formProvider setFormNextRefreshTime success`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.updateForm
updateForm(formId: string, formBindingData: formBindingData.FormBindingData, callback: AsyncCallback<void>): void
更新指定的卡片，使用callback异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0/v3/c0jZCMSjS5SmBVsM4w8DXA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=CD3A6E90EE418AB0F4E33D12BCA034F9003E8D153F7C3D30D9C1686047FE25F6)
从API version 20开始，如果卡片刷新的数据通过共享内存更新，刷新数据总大小不超过10MB，刷新图片数量不超过20张。API version 19及之前的版本，图片文件数量上限为5张，每张限制内存2MB，超出限制的图片会显示异常。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 请求更新的卡片标识。 |
| formBindingData | [formBindingData.FormBindingData](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formbindingdata.md) | 是 | 用于更新的数据。 |
| callback | AsyncCallback<void> | 是 | 回调函数。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
try {
  let param: Record<string, string> = {
    'temperature': '22c',
    'time': '22:00'
  }
  let obj: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
  formProvider.updateForm(formId, obj, (error: BusinessError) => {
    if (error) {
      console.error(`callback error, code: ${error.code}, message: ${error.message})`);
      return;
    }
    console.info(`formProvider updateForm success`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.updateForm
updateForm(formId: string, formBindingData: formBindingData.FormBindingData): Promise<void>
更新指定的卡片，使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4/v3/0ctlOBX6TGud1JG7ZlqkPA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=5E76E0777536BE5019E4229AAF5B90A51E918ED37549A460FD14955EBD063644)
从API version 20开始，如果卡片刷新的数据通过共享内存更新，刷新数据总大小不超过10MB，刷新图片数量不超过20张。API version 19及之前的版本，图片文件数量上限为5张，每张限制内存2MB，超出限制的图片会显示异常。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 请求更新的卡片标识。 |
| formBindingData | [formBindingData.FormBindingData](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formbindingdata.md) | 是 | 用于更新的数据。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
let param: Record<string, string> = {
  'temperature': '22c',
  'time': '22:00'
}
let obj: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
try {
  formProvider.updateForm(formId, obj).then(() => {
    console.info(`formProvider updateForm success`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getFormsInfo
getFormsInfo(callback: AsyncCallback<Array<formInfo.FormInfo>>): void
获取设备上当前应用程序的卡片信息，使用callback异步回调。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<Array<[formInfo.FormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)>> | 是 | 回调函数。返回查询到的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
try {
  formProvider.getFormsInfo((error, data) => {
    if (error) {
      console.error(`callback error, code: ${error.code}, message: ${error.message})`);
      return;
    }
    console.info(`formProvider getFormsInfo, data: ${JSON.stringify(data)}`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getFormsInfo
getFormsInfo(filter: formInfo.FormInfoFilter, callback: AsyncCallback<Array<formInfo.FormInfo>>): void
获取设备上当前应用程序的卡片信息，并筛选符合条件的信息，使用callback异步回调。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| filter | [formInfo.FormInfoFilter](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md) | 是 | 卡片信息过滤器。 |
| callback | AsyncCallback<Array<[formInfo.FormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)>> | 是 | 回调函数。返回查询到符合条件的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
const filter: formInfo.FormInfoFilter = {
  // get info of forms belong to module entry.
  moduleName: 'entry'
};
try {
  formProvider.getFormsInfo(filter, (error, data) => {
    if (error) {
      console.error(`callback error, code: ${error.code}, message: ${error.message})`);
      return;
    }
    console.info(`formProvider getFormsInfo, data: ${JSON.stringify(data)}`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getFormsInfo
getFormsInfo(filter?: formInfo.FormInfoFilter): Promise<Array<formInfo.FormInfo>>
获取设备上当前应用符合条件的卡片信息，使用Promise异步回调。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| filter | [formInfo.FormInfoFilter](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md) | 否 | 卡片信息过滤器, 默认为空，不进行过滤。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<[formInfo.FormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)>> | Promise对象。返回查询到符合条件的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types; 3.Parameter verification failed. |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
const filter: formInfo.FormInfoFilter = {
  // get info of forms belong to module entry.
  moduleName: 'entry'
};
try {
  formProvider.getFormsInfo(filter).then((data: formInfo.FormInfo[]) => {
    console.info(`formProvider getFormsInfo, data: ${JSON.stringify(data)}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.openFormEditAbility18+
openFormEditAbility(abilityName: string, formId: string, isMainPage?: boolean): void
打开卡片编辑页。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| abilityName | string | 是 | 编辑页的ability名称。 |
| formId | string | 是 | 卡片标识。 |
| isMainPage | boolean | 否 | 是否为主编辑页。- true：表示是主编辑页。- false：表示不是主编辑页。默认值：true。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 801 | Capability not supported.function openFormEditAbility can not work correctly due to limited device capabilities. |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501003 | The form cannot be operated by the current application. |
| 16501007 | Form is not trust. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
const TAG: string = 'FormEditDemo-Page] -->';
@Entry
@Component
struct Page {
  @State message: string = 'Hello World';
  aboutToAppear(): void {
    console.info(`${TAG} aboutToAppear.....`);
  }
  build() {
    RelativeContainer() {
      Text(this.message)
        .id('PageHelloWorld')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Top },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          console.info(`${TAG} onClick.....`);
          formProvider.openFormEditAbility('ability://EntryFormEditAbility', '1386529921');
        })
    }
    .height('100%')
    .width('100%')
  }
}
```
#### formProvider.openFormManager18+
openFormManager(want: Want): void
打开当前应用的卡片管理页面。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| want | [Want](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/通用能力的接口(推荐)/js-apis-app-ability-want.md) | 是 | 打开卡片管理页面的请求中的want参数，需包含以下字段。bundleName: 卡片所属应用的包名。abilityName: 卡片所属的ability名称。parameters:- ohos.extra.param.key.form_dimension:[卡片尺寸](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)。- ohos.extra.param.key.form_name: 卡片名称。- ohos.extra.param.key.module_name: 卡片所属的模块名称。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4c/v3/KgQtOX1iTu6ty0xJ_H7mlQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=2CA27A28023C62A3871661687632F42DE3147517DB6E5B178261434F04B11F7E)
如果parameters参数没有填完整或者指定的卡片不存在，就会默认展示 [form_config.json](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/配置ArkTS卡片的配置文件/arkts-ui-widget-configuration.md) 中配置的默认卡片。
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
const want: Want = {
  bundleName: 'com.example.formbutton',
  abilityName: 'EntryFormAbility',
  parameters: {
    'ohos.extra.param.key.form_dimension': 2,
    'ohos.extra.param.key.form_name': 'widget',
    'ohos.extra.param.key.module_name': 'entry'
  },
};
try {
  formProvider.openFormManager(want);
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getPublishedFormInfoById(deprecated)
getPublishedFormInfoById(formId: string): Promise<formInfo.FormInfo>
获取设备上当前应用程序已经加桌的指定卡片信息，使用Promise异步回调。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ba/v3/do8rrWJQSJCRqVVJVGTtng/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=1848DB81861CBED6A57112FD41347B1D808962B2A231B64B06E35BDBCF280884)
该字段从API version 18开始支持，从API version 20开始废弃，建议使用 [getPublishedRunningFormInfoById](#formprovidergetpublishedrunningforminfobyid20) 替代。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片标识。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[formInfo.FormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)> | Promise对象。返回查询到符合条件的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
const formId: string = '388344236';
try {
  formProvider.getPublishedFormInfoById(formId).then((data: formInfo.FormInfo) => {
    console.info(`formProvider getPublishedFormInfoById, data: ${JSON.stringify(data)}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getPublishedFormInfos(deprecated)
getPublishedFormInfos(): Promise<Array<formInfo.FormInfo>>
获取设备上当前应用程序所有已经加桌的卡片信息，使用Promise异步回调。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/cb/v3/1ASvbTvxQiSz6DMVGeSjXQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=53384FD780E9EDC0DD9E35B36CF7D1B80F5598EF2D387B6C1AF6340C71F86E01)
该字段从API version 18开始支持，从API version 20开始废弃，建议使用 [getPublishedRunningFormInfos](#formprovidergetpublishedrunningforminfos20) 替代。
**系统能力：** SystemCapability.Ability.Form
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<[formInfo.FormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)>> | Promise对象。返回查询到符合条件的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
try {
  formProvider.getPublishedFormInfos().then((data: formInfo.FormInfo[]) => {
    console.info(`formProvider getPublishedFormInfos, data: ${JSON.stringify(data)}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.requestOverflow20+
requestOverflow(formId: string, overflowInfo: formInfo.OverflowInfo): Promise<void>
卡片提供方发起互动卡片动效请求，只针对 [场景动效类型互动卡片](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/配置ArkTS卡片的配置文件/arkts-ui-widget-configuration.md) 生效，使用Promise异步回调。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/58/v3/OnG-mMf9Q4qe23TSWqZhpQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093142Z&HW-CC-Expire=86400&HW-CC-Sign=2D67D900B45234BD17EE8050536CB15B2A7B51E616C513B9993F268DDAC7D82F)
1. 该接口在省电模式场景下不可使用，会报16501000错误码。
2. 当设备热档位进入HOT场景并且没有点击事件的场景下，该接口会报16501000错误码；当热档位进入OVERHEATED时，任何情况下都会报16501000错误码。热档位信息具体可参考[热档位信息](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/设备管理/js-apis-thermal.md)。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片id标识。 |
| overflowInfo | [formInfo.OverflowInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md) | 是 | 动效请求参数信息。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 801 | Capability not supported.function requestOverflow can not work correctly due to limited device capabilities. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
| 16501011 | The form can not support this operation. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
let overflowInfo: formInfo.OverflowInfo = {
  area: {
    left: -10,
    top: -10,
    width: 180,
    height: 180
  },
  duration: 1000,
  useDefaultAnimation: false,
};
try {
  formProvider.requestOverflow(formId, overflowInfo).then(() => {
    console.info('requestOverflow succeed.');
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.cancelOverflow20+
cancelOverflow(formId: string): Promise<void>
卡片提供方发起取消互动卡片动效请求，只针对 [场景动效类型互动卡片](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/配置ArkTS卡片的配置文件/arkts-ui-widget-configuration.md) 生效，使用Promise异步回调。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片id。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无返回结果的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 801 | Capability not supported.function cancelOverflow can not work correctly due to limited device capabilities. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
| 16501011 | The form can not support this operation. |
**示例：**
```
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
try {
  formProvider.cancelOverflow(formId).then(() => {
    console.info('cancelOverflow succeed.');
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getFormRect20+
getFormRect(formId: string): Promise<formInfo.Rect>
查询卡片位置、尺寸，使用Promise异步回调。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片id标识。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[formInfo.Rect](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)> | Promise对象，返回卡片相对屏幕左上角的位置信息和卡片尺寸信息，单位vp。 |
**错误码：**
以下错误码的详细介绍请参见 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 801 | Capability not supported.function getFormRect can not work correctly due to limited device capabilities. |
| 16500050 | IPC connection error. |
| 16500060 | Service connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
let formId: string = '12400633174999288';
try {
  formProvider.getFormRect(formId).then((data: formInfo.Rect) => {
    console.info(`getFormRect succeed, data: ${JSON.stringify(data)}`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.getPublishedRunningFormInfoById20+
getPublishedRunningFormInfoById(formId: string): Promise<formInfo.RunningFormInfo>
获取当前应用已加桌卡片中指定的卡片信息，使用Promise异步回调。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| formId | string | 是 | 卡片标识。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[formInfo.RunningFormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)> | Promise对象。返回符合条件的卡片信息，包括卡片名称、尺寸等。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
| 16501001 | The ID of the form to be operated does not exist. |
| 16501003 | The form cannot be operated by the current application. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
const formId: string = '388344236';
try {
  formProvider.getPublishedRunningFormInfoById(formId).then((data: formInfo.RunningFormInfo) => {
    console.info(`formProvider getPublishedRunningFormInfoById, data: ${JSON.stringify(data)}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message}`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}`);
}
```
#### formProvider.getPublishedRunningFormInfos20+
getPublishedRunningFormInfos(): Promise<Array<formInfo.RunningFormInfo>>
获取所有已加桌的卡片信息，使用Promise异步回调。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<Array<[formInfo.RunningFormInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md)>> | Promise对象。返回符合条件的卡片信息。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16500050 | IPC connection error. |
| 16500100 | Failed to obtain the configuration information. |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
try {
  formProvider.getPublishedRunningFormInfos().then((data: formInfo.RunningFormInfo[]) => {
    console.info(`formProvider getPublishedRunningFormInfos, data: ${JSON.stringify(data)}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.reloadForms22+
reloadForms(context: UIAbilityContext, moduleName: string, abilityName: string, formName: string): Promise<number>
对于当前应用程序相同moduleName、abilityName、formName的卡片，多次加桌后会每张卡片会有不同的卡片id。卡片提供方可以通过本接口批量更新不同的卡片id但moduleName、abilityName、formName相同的卡片。在应用主进程通过本接口通知FormExtension进程进行批量更新，仅支持在 [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 中调用，使用Promise异步回调。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从API version 22开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| context | [UIAbilityContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext.md) | 是 | [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md)的上下文，做校验使用。 |
| moduleName | string | 是 | 指定卡片的moduleName。 |
| abilityName | string | 是 | 指定卡片的abilityName。 |
| formName | string | 是 | 指定卡片在[form_config.json](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Form Kit（卡片开发服务）/ArkTS卡片开发（推荐）/配置ArkTS卡片的配置文件/arkts-ui-widget-configuration.md)中配置的卡片名称。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | Promise对象。返回请求更新卡片的数量。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { formProvider } from '@kit.FormKit';
try {
  // 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext。
  let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // 请开发者替换为实际请求更新的卡片信息
  let moduleName: string = 'entry';
  let abilityName: string = 'EntryFormAbility';
  let formName: string = 'formName';
  formProvider.reloadForms(context, moduleName, abilityName, formName).then((reloadNum: number) => {
    console.info(`reloadForms success, reload number: ${reloadNum}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```
#### formProvider.reloadAllForms22+
reloadAllForms(context: UIAbilityContext): Promise<number>
在应用主进程通过本接口可以通知FormExtension进程批量更新当前应用程序下已经加桌的所有卡片，仅支持在 [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 中调用，使用Promise异步回调。
**模型约束：** 此接口仅可在Stage模型下使用。
**元服务API：** 从API version 22开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Ability.Form
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| context | [UIAbilityContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext.md) | 是 | [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md)的上下文，做校验使用。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<number> | Promise对象。返回请求更新卡片的数量。 |
**错误码：**
以下错误码的详细介绍请参见 [卡片错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/错误码/errorcode-form.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 16501000 | An internal functional error occurred. |
**示例：**
```
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { formProvider } from '@kit.FormKit';
try {
  // 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext。
  let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  formProvider.reloadAllForms(context).then((reloadNum: number) => {
    console.info(`reloadAllForms success, reload number: ${reloadNum}`);
  }).catch((error: BusinessError) => {
    console.error(`promise error, code: ${error.code}, message: ${error.message})`);
  });
} catch (error) {
  console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```