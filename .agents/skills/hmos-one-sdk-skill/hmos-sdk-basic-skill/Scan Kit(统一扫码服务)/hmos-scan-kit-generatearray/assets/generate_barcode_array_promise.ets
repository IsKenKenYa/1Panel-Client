import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG: string = 'GenerateBarcodeFromArray';
const DOMAIN: number = 0x0001;

export async function generateBarcodeFromArrayPromise(
  hexContent: string,
  width: number,
  height: number,
  errorCorrectionLevel?: generateBarcode.ErrorCorrectionLevel
): Promise<image.PixelMap | undefined> {
  if (width < 200 || width > 4096 || height < 200 || height > 4096) {
    hilog.error(DOMAIN, TAG, 'Invalid width or height. Range: [200, 4096]');
    return undefined;
  }

  const contentBuffer: ArrayBuffer = buffer.from(hexContent, 'hex').buffer;
  const bufferSize = contentBuffer.byteLength;
  
  if (bufferSize > 2048) {
    hilog.error(DOMAIN, TAG, `Buffer size ${bufferSize} exceeds max limit 2048 bytes`);
    return undefined;
  }

  let level: generateBarcode.ErrorCorrectionLevel;
  if (errorCorrectionLevel) {
    level = errorCorrectionLevel;
  } else {
    if (bufferSize <= 1024) {
      level = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
    } else if (bufferSize <= 1536) {
      level = generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
    } else {
      level = generateBarcode.ErrorCorrectionLevel.LEVEL_M;
    }
  }

  const options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    width: width,
    height: height,
    margin: 1,
    level: level,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000
  };

  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    hilog.info(DOMAIN, TAG, 'Succeeded in generating barcode from array');
    hilog.info(DOMAIN, TAG, `PixelMap size: ${pixelMap.getImageInfoSync().size.width}x${pixelMap.getImageInfoSync().size.height}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate barcode. Code: ${err.code}, Message: ${err.message}`);
    return undefined;
  }
}

export async function generateBarcodeWithCustomOptions(
  hexContent: string,
  options: generateBarcode.CreateOptions
): Promise<image.PixelMap | undefined> {
  const contentBuffer: ArrayBuffer = buffer.from(hexContent, 'hex').buffer;
  
  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    hilog.info(DOMAIN, TAG, 'Succeeded in generating barcode with custom options');
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate barcode. Code: ${err.code}, Message: ${err.message}`);
    return undefined;
  }
}

export function validateBuffer(hexContent: string): boolean {
  try {
    const contentBuffer: ArrayBuffer = buffer.from(hexContent, 'hex').buffer;
    const bufferSize = contentBuffer.byteLength;
    
    if (bufferSize > 2048) {
      hilog.error(DOMAIN, TAG, `Buffer size ${bufferSize} exceeds max limit 2048 bytes`);
      return false;
    }
    
    if (bufferSize <= 0) {
      hilog.error(DOMAIN, TAG, 'Buffer size is zero');
      return false;
    }
    
    return true;
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Invalid hex content format');
    return false;
  }
}

export function getRecommendedErrorLevel(bufferSize: number): generateBarcode.ErrorCorrectionLevel {
  if (bufferSize <= 1024) {
    return generateBarcode.ErrorCorrectionLevel.LEVEL_H;
  } else if (bufferSize <= 1536) {
    return generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
  } else if (bufferSize <= 2048) {
    return generateBarcode.ErrorCorrectionLevel.LEVEL_M;
  }
  return generateBarcode.ErrorCorrectionLevel.LEVEL_L;
}