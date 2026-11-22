# scanBarcode API参考说明

原始文档链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api

本文档提供默认界面扫码API的详细参考说明。

## 主要接口

### startScanForResult (Promise方式)

```typescript
startScanForResult(context: common.Context, options?: ScanOptions): Promise<ScanResult>
```

通过配置参数调用默认界面扫码,使用Promise异步回调返回解码结果。

**起始版本**: 4.1.0(11)

### startScanForResult (Callback方式)

```typescript
startScanForResult(context: common.Context, callback: AsyncCallback<ScanResult>): void
startScanForResult(context: common.Context, options: ScanOptions, callback: AsyncCallback<ScanResult>): void
```

启动默认界面扫码,使用Callback异步回调返回解码结果。

**起始版本**: 4.1.0(11)

## 数据结构

### ScanResult

扫码结果对象,包含:
- `scanType`: 码类型
- `originalValue`: 码识别内容结果
- `scanCodeRect`: 码识别位置信息(可选)
- `cornerPoints`: 码识别角点位置信息(可选)
- `isGS1`: 码图是否携带GS1数据(可选)
- `source`: 扫码结果来源(可选)

### ScanOptions

扫码、识码参数:
- `scanTypes`: 设置扫码类型,默认ALL
- `enableMultiMode`: 是否开启多码识别,默认false
- `enableAlbum`: 是否开启相册,默认true

### ScanCodeRect

码的位置信息:
- `left`: 码外接矩形左上角的x坐标
- `top`: 码外接矩形左上角的y坐标
- `right`: 码外接矩形右下角的x坐标
- `bottom`: 码外接矩形右下角的y坐标

### Point

点坐标:
- `x`: X轴坐标
- `y`: Y轴坐标

## 错误码

| 错误码ID | 错误信息 |
|---------|---------|
| 401 | Parameter error. Possible causes: 1. Incorrect parameter types; 2. Parameter verification failed. |
| 1000500001 | Internal error. |
| 1000500002 | The user canceled the barcode scanning. |

## 系统能力

SystemCapability.Multimedia.Scan.ScanBarcode

## 模型约束

此接口仅可在Stage模型下使用。

## 元服务API支持

从版本4.1.0(11)开始,该接口支持在元服务中使用。

详细内容请参考原始文档链接。