import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '[ScanDecodeImage]';
const DOMAIN = 0x0001;

export class ScanDecodeImageExample {
  private imageReceiver: image.ImageReceiver | null = null;
  private cameraManager: camera.CameraManager | null = null;
  private cameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private photoOutput: camera.PhotoOutput | null = null;
  private cameraSession: camera.PhotoSession | null = null;
  private surfaceId: string = '';
  private previewWidth: number = 1080;
  private previewHeight: number = 1920;

  async initCamera(surfaceId: string): Promise<void> {
    try {
      this.surfaceId = surfaceId;
      this.cameraManager = camera.getCameraManager(globalThis.context);
      
      const cameras = this.cameraManager.getSupportedCameras();
      if (cameras.length === 0) {
        hilog.error(DOMAIN, TAG, 'No camera available');
        return;
      }
      
      const cameraDevice = cameras[0];
      this.cameraInput = this.cameraManager.createCameraInput(cameraDevice);
      await this.cameraInput.open();
      
      const outputCapability = this.cameraManager.getSupportedOutputCapability(cameraDevice, camera.SceneMode.NORMAL_PHOTO);
      
      const previewProfiles = outputCapability.previewProfiles;
      if (previewProfiles.length === 0) {
        hilog.error(DOMAIN, TAG, 'No preview profile available');
        return;
      }
      
      const previewProfile = previewProfiles[0];
      this.previewWidth = previewProfile.size.width;
      this.previewHeight = previewProfile.size.height;
      
      this.previewOutput = this.cameraManager.createPreviewOutput(previewProfile, surfaceId);
      
      this.imageReceiver = image.createImageReceiver(this.previewWidth, this.previewHeight, image.ImageFormat.JPEG, 8);
      const imageReceiverSurfaceId = await this.imageReceiver.getReceivingSurfaceId();
      
      const photoProfiles = outputCapability.photoProfiles;
      if (photoProfiles.length === 0) {
        hilog.error(DOMAIN, TAG, 'No photo profile available');
        return;
      }
      this.photoOutput = this.cameraManager.createPhotoOutput(photoProfiles[0], imageReceiverSurfaceId);
      
      this.cameraSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.cameraSession.beginConfig();
      this.cameraSession.addInput(this.cameraInput);
      this.cameraSession.addOutput(this.previewOutput);
      this.cameraSession.addOutput(this.photoOutput);
      await this.cameraSession.commitConfig();
      await this.cameraSession.start();
      
      hilog.info(DOMAIN, TAG, 'Camera initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init camera: ${error}`);
    }
  }

  startDecodeImage(): void {
    if (!this.imageReceiver) {
      hilog.error(DOMAIN, TAG, 'ImageReceiver not initialized');
      return;
    }
    
    this.imageReceiver.on('imageArrival', async () => {
      try {
        const imgComponent = await this.imageReceiver?.readNextImage();
        if (!imgComponent) {
          hilog.error(DOMAIN, TAG, 'Failed to read image');
          return;
        }
        
        await this.decodeImageBuffer(imgComponent);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to process image: ${error}`);
      }
    });
    
    hilog.info(DOMAIN, TAG, 'DecodeImage started');
  }

  private async decodeImageBuffer(imgComponent: image.ImageComponent): Promise<void> {
    const byteImg: detectBarcode.ByteImage = {
      byteBuffer: imgComponent.byteBuffer,
      width: this.previewHeight,
      height: this.previewWidth,
      format: detectBarcode.ImageFormat.NV21
    };
    
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: false
    };
    
    try {
      const result: detectBarcode.DetectResult = await detectBarcode.decodeImage(byteImg, options);
      
      hilog.info(DOMAIN, TAG, `DetectResult: ${JSON.stringify(result)}`);
      
      if (result.scanResults && result.scanResults.length > 0) {
        result.scanResults.forEach((scanResult, index) => {
          hilog.info(DOMAIN, TAG, 
            `Scan result ${index}: type=${scanResult.scanType}, value=${scanResult.originalValue}`);
          
          if (scanResult.scanCodeRect) {
            hilog.info(DOMAIN, TAG, 
              `Code rect: left=${scanResult.scanCodeRect.left}, top=${scanResult.scanCodeRect.top}, ` +
              `right=${scanResult.scanCodeRect.right}, bottom=${scanResult.scanCodeRect.bottom}`);
          }
          
          if (scanResult.cornerPoints && scanResult.cornerPoints.length === 4) {
            const convertedPoints = this.convertCornerPoints(scanResult.cornerPoints);
            hilog.info(DOMAIN, TAG, `Corner points: ${JSON.stringify(convertedPoints)}`);
          }
        });
      }
      
      if (result.zoomValue) {
        hilog.info(DOMAIN, TAG, `Zoom value: ${result.zoomValue}`);
        await this.adjustZoom(result.zoomValue);
      }
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 
        `Failed to decode image: Code=${err.code}, Message=${err.message}`);
    }
  }

  private convertCornerPoints(cornerPoints: Array<scanBarcode.Point>): Array<{x: number, y: number}> {
    const convertedPoints: Array<{x: number, y: number}> = [];
    
    if (cornerPoints && cornerPoints.length === 4) {
      convertedPoints.push({
        x: this.previewWidth - cornerPoints[0].y,
        y: cornerPoints[0].x
      });
      convertedPoints.push({
        x: this.previewWidth - cornerPoints[1].y,
        y: cornerPoints[1].x
      });
      convertedPoints.push({
        x: this.previewWidth - cornerPoints[2].y,
        y: cornerPoints[2].x
      });
      convertedPoints.push({
        x: this.previewWidth - cornerPoints[3].y,
        y: cornerPoints[3].x
      });
    }
    
    return convertedPoints;
  }

  private async adjustZoom(zoomValue: number): Promise<void> {
    try {
      if (!this.cameraSession) {
        hilog.error(DOMAIN, TAG, 'CameraSession not initialized');
        return;
      }
      
      const zoomRatioRange = this.cameraSession.getZoomRatioRange();
      if (zoomRatioRange.length < 2) {
        hilog.error(DOMAIN, TAG, 'Zoom ratio range not available');
        return;
      }
      
      const currentZoomRatio = zoomRatioRange[0];
      const targetZoomRatio = currentZoomRatio * zoomValue;
      
      const minZoom = zoomRatioRange[0];
      const maxZoom = zoomRatioRange[1];
      const clampedZoomRatio = Math.min(Math.max(targetZoomRatio, minZoom), maxZoom);
      
      await this.cameraSession.setZoomRatio(clampedZoomRatio);
      hilog.info(DOMAIN, TAG, `Zoom adjusted to: ${clampedZoomRatio}`);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to adjust zoom: ${error}`);
    }
  }

  async stopCamera(): Promise<void> {
    try {
      if (this.cameraSession) {
        await this.cameraSession.stop();
        await this.cameraSession.release();
        this.cameraSession = null;
      }
      
      if (this.cameraInput) {
        await this.cameraInput.close();
        this.cameraInput = null;
      }
      
      if (this.imageReceiver) {
        this.imageReceiver.release();
        this.imageReceiver = null;
      }
      
      hilog.info(DOMAIN, TAG, 'Camera stopped successfully');
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to stop camera: ${error}`);
    }
  }
}

export function createScanDecodeImageExample(): ScanDecodeImageExample {
  return new ScanDecodeImageExample();
}