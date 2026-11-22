import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '[BarcodeGenerateCallback]';
const DOMAIN = 0x0001;

export function generateQRCodeCallback(
  content: string,
  onSuccess: (pixelMap: image.PixelMap) => void,
  onError: (error: BusinessError) => void
): void {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, '内容不能为空');
    onError({ code: 401, message: '内容不能为空' } as BusinessError);
    return;
  }

  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: 400,
    width: 400,
    margin: 1,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000
  };

  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
        onError(err);
        return;
      }
      hilog.info(DOMAIN, TAG, `成功生成QR码，尺寸: ${pixelMap.getImageInfoSync().size}`);
      onSuccess(pixelMap);
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `调用失败，错误码: ${err.code}, 消息: ${err.message}`);
    onError(err);
  }
}

export function generateBarcodeCallback(
  content: string,
  scanType: scanCore.ScanType,
  onSuccess: (pixelMap: image.PixelMap) => void,
  onError: (error: BusinessError) => void
): void {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, '内容不能为空');
    onError({ code: 401, message: '内容不能为空' } as BusinessError);
    return;
  }

  let width: number = 400;
  let height: number = 200;

  if ([scanCore.ScanType.QR_CODE, scanCore.ScanType.DATAMATRIX_CODE, 
       scanCore.ScanType.AZTEC_CODE, scanCore.ScanType.PDF417_CODE].includes(scanType)) {
    width = 400;
    height = 400;
  }

  let options: generateBarcode.CreateOptions = {
    scanType: scanType,
    height: height,
    width: width
  };

  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
        onError(err);
        return;
      }
      hilog.info(DOMAIN, TAG, `成功生成码图，类型: ${scanType}, 尺寸: ${pixelMap.getImageInfoSync().size}`);
      onSuccess(pixelMap);
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `调用失败，错误码: ${err.code}, 消息: ${err.message}`);
    onError(err);
  }
}

export function generateEAN13Callback(
  content: string,
  onSuccess: (pixelMap: image.PixelMap) => void,
  onError: (error: BusinessError) => void
): void {
  if (!content || content.length !== 12) {
    hilog.error(DOMAIN, TAG, 'EAN-13内容必须是12位数字');
    onError({ code: 401, message: 'EAN-13内容必须是12位数字' } as BusinessError);
    return;
  }

  if (!/^\d{12}$/.test(content)) {
    hilog.error(DOMAIN, TAG, 'EAN-13内容只能包含数字');
    onError({ code: 401, message: 'EAN-13内容只能包含数字' } as BusinessError);
    return;
  }

  if (content.startsWith('0')) {
    hilog.error(DOMAIN, TAG, 'EAN-13内容首位不能为0');
    onError({ code: 401, message: 'EAN-13内容首位不能为0' } as BusinessError);
    return;
  }

  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.EAN13_CODE,
    height: 200,
    width: 400
  };

  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
        onError(err);
        return;
      }
      hilog.info(DOMAIN, TAG, '成功生成EAN-13条形码');
      onSuccess(pixelMap);
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `调用失败，错误码: ${err.code}, 消息: ${err.message}`);
    onError(err);
  }
}