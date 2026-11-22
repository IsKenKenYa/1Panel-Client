import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class DecodeImageExample {
  private options: scanBarcode.ScanOptions;
  
  constructor() {
    this.options = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: false
    };
  }
  
  async decodeImageBuffer(imgComponent: image.Component, width: number, height: number): Promise<void> {
    let byteImg: detectBarcode.ByteImage = {
      byteBuffer: imgComponent.byteBuffer,
      width: height,
      height: width,
      format: detectBarcode.ImageFormat.NV21
    };
    
    try {
      const result = await detectBarcode.decodeImage(byteImg, this.options);
      this.handleDecodeResult(result);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0001, '[DecodeImageExample]', 
        `Failed to decode image. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  private handleDecodeResult(result: detectBarcode.DetectResult): void {
    hilog.info(0x0001, '[DecodeImageExample]', 
      `Succeeded in decoding image, result: ${JSON.stringify(result)}`);
    
    if (result.scanResults && result.scanResults.length > 0) {
      for (let scanResult of result.scanResults) {
        hilog.info(0x0001, '[DecodeImageExample]', 
          `ScanType: ${scanResult.scanType}, Value: ${scanResult.originalValue}`);
        
        if (scanResult.cornerPoints) {
          const convertedPoints = this.convertCornerPoints(scanResult.cornerPoints, 1080);
          hilog.info(0x0001, '[DecodeImageExample]', 
            `Converted corner points: ${JSON.stringify(convertedPoints)}`);
        }
      }
    }
    
    if (result.zoomValue) {
      hilog.info(0x0001, '[DecodeImageExample]', 
        `Recommended zoom value: ${result.zoomValue}`);
    }
  }
  
  private convertCornerPoints(cornerPoints: Array<scanBarcode.Point>, previewWidth: number = 1080): Array<{x: number, y: number}> {
    return [
      { x: previewWidth - cornerPoints[0].y, y: cornerPoints[0].x },
      { x: previewWidth - cornerPoints[1].y, y: cornerPoints[1].x },
      { x: previewWidth - cornerPoints[2].y, y: cornerPoints[2].x },
      { x: previewWidth - cornerPoints[3].y, y: cornerPoints[3].x }
    ];
  }
}