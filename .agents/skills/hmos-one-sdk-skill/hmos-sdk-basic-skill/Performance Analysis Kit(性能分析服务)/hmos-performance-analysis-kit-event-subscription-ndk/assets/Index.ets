import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
    build() {
        Column() {
            Button('触发崩溃事件')
                .onClick(() => {
                    let result: object = JSON.parse('');
                })
            
            Button('触发按钮点击事件')
                .onClick(() => {
                    testNapi.writeButtonClickEvent();
                })
            
            Button('移除观察者')
                .onClick(() => {
                    testNapi.removeAllWatchers();
                })
            
            Button('销毁观察者')
                .onClick(() => {
                    testNapi.destroyAllWatchers();
                })
        }
    }
}