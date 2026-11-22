/**
 * List数据源实现示例
 * 功能：展示IDataSource接口的标准实现和降级处理
 */

import { IDataSource, DataChangeListener } from '@ohos.arkui';

/**
 * 标准数据源实现
 */
class StandardListDataSource implements IDataSource {
  private list: number[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  totalCount(): number {
    return this.list.length;
  }
  
  getData(index: number): number {
    if (index < 0 || index >= this.list.length) {
      throw new Error('Index out of bounds: ' + index);
    }
    return this.list[index];
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {}
  unregisterDataChangeListener(listener: DataChangeListener): void {}
}

/**
 * 安全数据源实现（带降级处理）
 */
class SafeListDataSource implements IDataSource {
  private list: number[] = [];
  private fallbackValue: number = -1;
  
  constructor(list: number[], fallback?: number) {
    this.list = list;
    if (fallback !== undefined) {
      this.fallbackValue = fallback;
    }
  }
  
  totalCount(): number {
    // 降级处理：返回最小值0
    return Math.max(0, this.list.length);
  }
  
  getData(index: number): number {
    try {
      // 边界检查和降级处理
      if (this.list.length === 0) {
        console.warn('Empty data source, returning fallback value');
        return this.fallbackValue;
      }
      
      const safeIndex = Math.max(0, Math.min(index, this.list.length - 1));
      return this.list[safeIndex];
      
    } catch (error) {
      console.error('getData failed, using fallback:', error.message);
      return this.fallbackValue;
    }
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {
    // 可选：实现数据变化监听
  }
  
  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 可选：实现监听器注销
  }
}

/**
 * 可监听数据源实现（支持数据变化通知）
 */
class ObservableListDataSource implements IDataSource {
  private list: number[] = [];
  private listeners: DataChangeListener[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  totalCount(): number {
    return this.list.length;
  }
  
  getData(index: number): number {
    if (index < 0 || index >= this.list.length) {
      console.warn('Invalid index: ' + index);
      return 0;
    }
    return this.list[index];
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }
  
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }
  
  /**
   * 添加数据项
   * @param item 新数据项
   */
  addData(item: number): void {
    this.list.push(item);
    // 通知所有监听器数据已添加
    this.listeners.forEach(listener => {
      listener.onDataAdd(this.list.length - 1);
    });
  }
  
  /**
   * 删除数据项
   * @param index 删除索引
   */
  deleteData(index: number): void {
    if (index >= 0 && index < this.list.length) {
      this.list.splice(index, 1);
      // 通知所有监听器数据已删除
      this.listeners.forEach(listener => {
        listener.onDataDelete(index);
      });
    }
  }
  
  /**
   * 刷新所有数据
   */
  reloadData(): void {
    // 通知所有监听器重新加载数据
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }
}

// 使用示例
export { 
  StandardListDataSource, 
  SafeListDataSource, 
  ObservableListDataSource 
};