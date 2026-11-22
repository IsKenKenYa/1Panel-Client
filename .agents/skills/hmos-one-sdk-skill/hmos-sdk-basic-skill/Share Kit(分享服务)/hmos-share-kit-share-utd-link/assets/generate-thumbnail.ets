import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export async function generateThumbnail(
  imagePath: string,
  quality: number = 30
): Promise<Uint8Array> {
  try {
    let imageSource: image.ImageSource = image.createImageSource(imagePath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: quality
    });
    
    console.info(`缩略图生成成功,大小: ${buffer.byteLength} bytes`);
    
    return new Uint8Array(buffer);
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(`缩略图生成失败: code ${businessError.code}, message ${businessError.message}`);
    throw businessError;
  }
}

export async function compressThumbnail(
  thumbnail: Uint8Array,
  targetSizeKB: number = 32
): Promise<Uint8Array> {
  let currentSizeKB = thumbnail.length / 1024;
  
  if (currentSizeKB <= targetSizeKB) {
    console.info('缩略图大小符合要求,无需压缩');
    return thumbnail;
  }
  
  console.info(`当前缩略图大小: ${currentSizeKB} KB,目标大小: ${targetSizeKB} KB`);
  
  try {
    let imageSource: image.ImageSource = image.createImageSource(thumbnail.buffer);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    
    let quality = Math.floor((targetSizeKB / currentSizeKB) * 100);
    quality = Math.max(10, Math.min(quality, 100));
    
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: quality
    });
    
    console.info(`缩略图压缩成功,新大小: ${buffer.byteLength / 1024} KB,质量: ${quality}`);
    
    return new Uint8Array(buffer);
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(`缩略图压缩失败: code ${businessError.code}, message ${businessError.message}`);
    throw businessError;
  }
}