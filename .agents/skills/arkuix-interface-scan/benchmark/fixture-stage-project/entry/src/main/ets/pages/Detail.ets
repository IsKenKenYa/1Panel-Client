import { publish } from '@ohos.notificationManager';
import { MapComponent } from '@hms.map';
import { doWork } from '@ohos.mockConflict';
import { onlyFn } from '@ohos.markedonly';
import { brandNewFn } from '@ohos.brandnew.module';

@Component
struct Detail {
  build() {
    Column() {
      Text('detail page')
    }
  }
}

// 动态加载（R-1）：字面量动态导入计入清单；变量形式仅报告提示
export async function lazyLoad(moduleName: string): Promise<object> {
  const literal = await import('@ohos.mockConflict2');
  const variable = await import(moduleName);
  return literal;
}
