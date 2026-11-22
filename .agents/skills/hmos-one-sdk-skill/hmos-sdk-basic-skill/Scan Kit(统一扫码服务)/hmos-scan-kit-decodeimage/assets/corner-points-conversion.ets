export function scaleCornerPoints(
  convertedPoints: Array<{x: number, y: number}>,
  previewWidth: number = 1080,
  xComponentWidth: number,
  xComponentHeight: number
): Array<{x: number, y: number}> {
  const ratio = xComponentWidth / previewWidth;
  
  return convertedPoints.map(point => ({
    x: point.x * ratio,
    y: point.y * ratio
  }));
}

export function convertAndScaleCornerPoints(
  cornerPoints: Array<{x: number, y: number}>,
  previewWidth: number = 1080,
  xComponentWidth: number,
  xComponentHeight: number
): Array<{x: number, y: number}> {
  const convertedPoints = [
    { x: previewWidth - cornerPoints[0].y, y: cornerPoints[0].x },
    { x: previewWidth - cornerPoints[1].y, y: cornerPoints[1].x },
    { x: previewWidth - cornerPoints[2].y, y: cornerPoints[2].x },
    { x: previewWidth - cornerPoints[3].y, y: cornerPoints[3].x }
  ];
  
  return scaleCornerPoints(convertedPoints, previewWidth, xComponentWidth, xComponentHeight);
}