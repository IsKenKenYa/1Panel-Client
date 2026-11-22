# animateTo 动画前的状态修改

迁移到 V2 时，检查 `animateTo` 回调中受影响的状态变量。如果在动画开始前修改了这些变量，API 22+ 需要将这些动画前的修改一起包装进 `UIUtils.applySync` 闭包；API 12–21 使用全局 `animateToImmediately({ duration: 0 }, ...)`，然后再调用原 `animateTo`。

这也适用于回调中修改的文本、阶段标记等非插值状态。保留原动画参数和完成回调；没有动画前的状态修改时，无需增加同步准备调用。

下面假设 `@Local sideLength` 绑定尺寸、`@Local caption` 绑定文本，代码位于同一个事件回调中。

API 22+，从 `@kit.ArkUI` 导入 `UIUtils`：

```ts
UIUtils.applySync(() => {
  this.caption = 'Ready';
  this.sideLength = 96;
});
this.getUIContext().animateTo({ duration: 300 }, () => {
  this.caption = 'Expanded';
  this.sideLength = 192;
});
```

API 12–21，将上述同步准备调用替换为全局函数（无需导入），后续动画不变：

```ts
animateToImmediately({ duration: 0 }, () => {
  this.caption = 'Ready';
  this.sideLength = 96;
});
this.getUIContext().animateTo({ duration: 300 }, () => {
  this.caption = 'Expanded';
  this.sideLength = 192;
});
```
