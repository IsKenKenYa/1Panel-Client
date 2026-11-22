# JSError 故障模式库

本库用于 JS Crash / ArkTS 异常崩溃的三级根因匹配。输入来源是 appevent、errorManager 或 faultlogger 中的 `Reason`、
`Error name`、`Error message`、`Error code`、`Stacktrace`、`HybridStack` 等字段。

## 匹配规则

1. 优先用 `Reason` 或 `Error name` 匹配二级根因。
2. 再用 `Error message` 做三级根因匹配；带 `<name>`、`<string>`、`<size>`、`<heap-type>` 的条目按通配模板匹配。
3. 如果 `Error message` 只命中二级根因，三级根因输出为"未收录子类"，并继续结合调用栈判断责任代码。
4. `Stacktrace` / `HybridStack` 用于确认调用来源和责任模块；不能只凭错误类型定界。

## 一级根因

| 一级根因      | 说明                                          |
|-----------|---------------------------------------------|
| `JSError` | appevent、errorManager 上报的 ArkTS 异常导致应用异常崩溃。 |

## 二级根因索引

| 二级根因               | 说明                              |
|--------------------|---------------------------------|
| `TypeError`        | 类型错误：表示变量或参数不是预期类型              |
| `SyntaxError`      | 语法错误：语法错误也称为解析错误，表示不符合编程语言的语法规范 |
| `RangeError`       | 边界错误：表示超出有效范围时发生的异常             |
| `ReferenceError`   | 引用错误                            |
| `URIError`         | 无效URL                           |
| `Error`            | 自定义 Error 或builtins错误           |
| `OutOfMemoryError` | ArkTS虚拟机堆内存不足                   |
| `TerminationError` | 终止错误：通常由于进程被强制终止                |

## 三级根因库

| 一级根因      | 二级根因               | 三级根因                                                                                                                          | 根因说明                                                            | 分析要点 / 修复方向 |
|-----------|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `JSError` | `TypeError`        | `Cannot read property <property-name> of undefined`                                                                                        | 尝试访问某个对象的属性时，对象为undefined                                       |             |
| `JSError` | `TypeError`        | `Cannot read property <property-name> of null`                                                                                             | 尝试访问某个对象的属性时，对象为null                                            |             |
| `JSError` | `TypeError`        | `<value> is not callable`                                                                                                                  | 试图以函数形式调用某个值，但该值并不是可调用对象                                        |             |
| `JSError` | `TypeError`        | `Cannot load property of null or undefined`                                                                                                | 尝试从null或undefined上读取属性，但这两种类型不支持属性访问                            |             |
| `JSError` | `TypeError`        | `Obj is not a Valid object`                                                                                                                | 接收到非对象类型的数据                                                     |             |
| `JSError` | `TypeError`        | `stack contains value, usually caused by circular structure`                                                                               | 在处理对象序列化时，检测到循环引用                                               |             |
| `JSError` | `TypeError`        | `Cannot convert a <from-type> value to a <to-type>`                                                                                        | 尝试将某种类型转换为不兼容的另一种类型，导致转换失败                                      |             |
| `JSError` | `TypeError`        | `Can not get Prototype on non ECMA Object`                                                                                                 | 获取原型的操作仅适用于ECMAScript对象，但当前值并非有效对象                              |             |
| `JSError` | `TypeError`        | `Cannot use 'in' operator in Non-Object`                                                                                                   | "in"运算符要求右侧必须为对象，但当前值为非对象                                       |             |
| `JSError` | `TypeError`        | `Get Property index out-of-bounds`                                                                                                         | 在访问数组元素时，使用的索引超出其可访问的范围，从而触发边界越界错误                              |             |
| `JSError` | `TypeError`        | `class constructor cannot called without 'new'`                                                                                            | 类的构造函数只能通过"new"关键字                                              |             |
| `JSError` | `SyntaxError`      | `Unexpected <text> in JSON`                                                                                                                | 解析JSON时遇到了不符合JSON语法规范的字符                                        |             |
| `JSError` | `SyntaxError`      | `the requested module <requested-module> does not provide an export name <export-name> which imported by <imported-module>`                | 某个模块在import时，引用了一个目标模块并没有导出的具名导出                                |             |
| `JSError` | `SyntaxError`      | `the requested module <requested-module> does not provide an export name <export-name> which exported by <exported-module>`                | 某个模块在做 re-export（export { x } from '...'）时，试图转导出一个目标模块并不存在的导出成员 |             |
| `JSError` | `SyntaxError`      | `extraneous characters at the end`                                                                                                         | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `nothing to repeat`                                                                                                                        | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `syntax error`                                                                                                                             | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `GroupName Syntax error.`                                                                                                                  | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Duplicate GroupName error.`                                                                                                               | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `? Syntax error.`                                                                                                                          | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `capture syntax error`                                                                                                                     | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Invalid repetition count`                                                                                                                 | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `unexpected end`                                                                                                                           | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `invalid backreference count`                                                                                                              | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `expecting group name.`                                                                                                                    | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `group name not defined`                                                                                                                   | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Invalid control letter`                                                                                                                   | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Invalid class escape`                                                                                                                     | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Invalid unicode escape`                                                                                                                   | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `invalid class range`                                                                                                                      | 正则解析异常                                                          |             |
| `JSError` | `SyntaxError`      | `Duplicate identifier`                                                                                                                     | 标识符重复                                                           |             |
| `JSError` | `RangeError`       | `Stack overflow!`                                                                                                                          | 栈溢出错误                                                           |             |
| `JSError` | `RangeError`       | `Invalid array length`                                                                                                                     | 边界错误                                                            |             |
| `JSError` | `RangeError`       | `getIndex +elementSize > viewSize`                                                                                                         | 边界错误                                                            |             |
| `JSError` | `RangeError`       | `The newByteLength is less than 0.`                                                                                                        | 边界错误                                                            |             |
| `JSError` | `RangeError`       | `The newByteLength is out of range.`                                                                                                       | 边界错误                                                            |             |
| `JSError` | `RangeError`       | `getIndex < 0`                                                                                                                             | 边界错误                                                            |             |
| `JSError` | `RangeError`       | `The byte length of <typed-array> should be a multiple of <element-size>`                                                                  | Typed array的长度必须是element size的整数倍，否则会抛出异常                       |             |
| `JSError` | `RangeError`       | `is infinity`                                                                                                                              | 传入参数为正无穷大                                                       |             |
| `JSError` | `RangeError`       | `Invalid time value`                                                                                                                       | 传入的时间值无效                                                        |             |
| `JSError` | `RangeError`       | `fraction must be 0 to 100`                                                                                                                | 传入的小数位数值必须在0-100之间                                              |             |
| `JSError` | `RangeError`       | `invalid locale`                                                                                                                           | 传入的locale字符串格式无效，不符合标准                                          |             |
| `JSError` | `ReferenceError`   | `<name> is not initialized`                                                                                                                | 变量在初始化之前不可访问                                                    |             |
| `JSError` | `ReferenceError`   | `cannot find record '<name>', in lazy load abc: <filename>`                                                                                | 模块查找失败                                                          |             |
| `JSError` | `ReferenceError`   | `cannot find record '<name>',please check the request path.'<filename>'.`                                                                  | 模块查找失败                                                          |             |
| `JSError` | `ReferenceError`   | `cannot find record '<name>' in basefileName '<filename>',from napi load module`                                                           | 模块查找失败                                                          |             |
| `JSError` | `ReferenceError`   | `Cannot find module '<request>' imported from '<current>'.`                                                                                | 模块查找失败                                                          |             |
| `JSError` | `ReferenceError`   | `Cannot find module '<name>' , which is application Entry Point`                                                                           | 模块查找失败                                                          |             |
| `JSError` | `ReferenceError`   | `undefinedsub-class must call super before use 'this'`                                                                                     | 子类构造函数中使用this之前，必须要调用super()                                    |             |
| `JSError` | `ReferenceError`   | `super() forbidden re-bind 'this'`                                                                                                         | 子类构造函数中不能多次调用super                                              |             |
| `JSError` | `ReferenceError`   | `<name> is not defined`                                                                                                                    | 尝试访问的变量未定义                                                      |             |
| `JSError` | `URIError`         | `DecodeURI: invalid character: <string>`                                                                                                   | URI解码异常                                                         |             |
| `JSError` | `Error`            | `The underlying ArrayBuffer is null or detached.`                                                                                          | ArrayBuffer被分离或释放                                               |             |
| `JSError` | `Error`            | `The ArkTS Map's constructor cannot be directly invoked.`                                                                                  | 不可直接调用map的构造函数                                                  |             |
| `JSError` | `OutOfMemoryError` | `OutOfMemory when trying to allocate <size> bytes function name: <name>, <heap-type> oom, total size <size> bytes, used size <size> bytes` | ArkTS虚拟机堆内存不足，产生OOM异常                                           | 用户提供 rawheap 或 heapsnapshot 时，调用 `jsleak-analysis` Skill 继续分析。 |
| `JSError` | `TerminationError` | `Terminate execution!`                                                                                                                     | 虚拟机被强制终止执行。可通过故障日志中的Stacktrace或HybridStack字段查看调用来源              |             |

## 输出要求

命中本库时，在报告的"关键证据链"中补充：

```text
错误模式匹配：JSError -> <二级根因> -> <Error message 模式>
三级根因：<三级根因说明>
```

如果只命中二级根因，输出：

```text
错误模式匹配：JSError -> <二级根因> -> 未收录子类
三级根因：需结合 Error message 与栈顶应用帧继续判断
```
