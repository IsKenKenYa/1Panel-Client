import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '[BarcodeGeneratePromise]';
const DOMAIN = 0x0001;

export async function generateQRCodePromise(content: string): Promise<image.PixelMap | null> {
  try {
    if (!content || content.length === 0) {
      hilog.error(DOMAIN, TAG, '内容不能为空');
      return null;
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

    const pixelMap = await generateBarcode.createBarcode(content, options);
    hilog.info(DOMAIN, TAG, `成功生成QR码，尺寸: ${pixelMap.getImageInfoSync().size}`);
    return pixelMap;

  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
    return null;
  }
}

export async function generateBarcodePromise(content: string, scanType: scanCore.ScanType): Promise<image.PixelMap | null> {
  try {
    if (!content || content.length === 0) {
      hilog.error(DOMAIN, TAG, '内容不能为空');
      return null;
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

    const pixelMap = await generateBarcode.createBarcode(content, options);
    hilog.info(DOMAIN, TAG, `成功生成码图，类型: ${scanType}, 尺寸: ${pixelMap.getImageInfoSync().size}`);
    return pixelMap;

  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
    return null;
  }
}

export async function generateCustomQRCodePromise(
  content: string,
  width: number,
  height: number,
  margin: number,
  level: generateBarcode.ErrorCorrectionLevel,
  bgColor: number,
  pixelColor: number
): Promise<image.PixelMap | null> {
  try {
    if (width < 200 || width > 4096) {
      hilog.error(DOMAIN, TAG, '宽度必须在200-4096之间');
      return null;
    }

    if (height < 200 || height > 4096) {
      hilog.error(DOMAIN, TAG, '高度必须在200-4096之间');
      return null;
    }

    if (margin < 1 || margin > 10) {
      hilog.error(DOMAIN, TAG, '边距必须在1-10之间');
      return null;
    }

    let options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      height: height,
      width: width,
      margin: margin,
      level: level,
      backgroundColor: bgColor,
      pixelMapColor: pixelColor
    };

    const pixelMap = await generateBarcode.createBarcode(content, options);
    hilog.info(DOMAIN, TAG, '成功生成自定义QR码');
    return pixelMap;

  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
    return null;
  }
}