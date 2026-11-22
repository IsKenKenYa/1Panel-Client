# ArkTS 代码审查规则

> 来源：华为 HarmonyOS 官方文档
> - [ArkTS编程规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-coding-style-guide-0000001774279669)
> - [从TypeScript到ArkTS的适配规则](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/typescript-to-arkts-migration-guide)
> - [ArkTS高性能编程实践](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-high-performance-programming-0000001774279637)

---

## 一、强制静态类型规则

### 1.1 禁止 any/unknown 类型

**规则**: `arkts-no-any-unknown` | **级别**: Error | **错误码**: 10605008

ArkTS 不支持 `any` 和 `unknown` 类型，必须显式指定具体类型。

```typescript
// 错误
let value: any = someFunction();
let value2: unknown = getData();

// 正确
let value: string = someFunction();
let value2: Object = getData();
```

**审查要点**:
- 检查是否有 `any` 类型标注
- 检查是否有 `unknown` 类型标注
- 检查是否使用了隐式 any（如未标注类型的参数）
- 检查 API 返回值是否被隐式推断为 any

### 1.2 禁止 var

**规则**: `arkts-no-var` | **级别**: Error | **错误码**: 10605005

使用 `let` 而非 `var`。

### 1.3 禁止 @ts-ignore / @ts-nocheck

**规则**: `arkts-strict-typing-required` | **级别**: Error | **错误码**: 10605146

不允许通过注释关闭类型检查。

### 1.4 强制严格类型检查

**级别**: Error | **错误码**: 10605999

强制启用：
- `noImplicitReturns` — 所有代码路径必须返回值
- `strictFunctionTypes` — 函数类型严格检查
- `strictNullChecks` — null/undefined 严格检查
- `strictPropertyInitialization` — 类属性必须初始化

```typescript
// 错误：可能没有返回值
function foo(s: string): string {
  if (s != '') {
    return s;
  }
  // 缺少 return
}

// 正确
function foo(s: string): string {
  return s || '';
}

// 错误：null 不能赋给 number
let n: number = null;

// 正确
let n: number | null = null;
```

---

## 二、对象布局规则

### 2.1 禁止运行时修改对象布局

**规则**: 多个相关规则 | **级别**: Error

- 禁止添加/删除对象属性
- 禁止 `delete` 运算符 (`arkts-no-delete`, 错误码 10605059)
- 禁止 `Symbol()` API (`arkts-no-symbol`, 错误码 10605002)
- 禁止索引签名 (`arkts-no-indexed-signatures`, 错误码 10605017)
- 禁止通过索引访问字段 (`arkts-no-props-by-index`, 错误码 10605029)
- 禁止 `#` 私有字段 (`arkts-no-private-identifiers`, 错误码 10605003)

```typescript
// 错误：delete
delete obj.prop;

// 正确：赋值 null
obj.prop = null;

// 错误：索引访问
let val = obj['key'];

// 正确：点操作符
let val = obj.key;

// 错误：索引签名
interface I {
  [key: string]: string;
}

// 正确：使用 Map
let map = new Map<string, string>();
```

### 2.2 禁止修改对象方法

**规则**: `arkts-no-method-reassignment` | **级别**: Error | **错误码**: 10605052

```typescript
// 错误
obj.method = newMethod;

// 正确：使用继承
class Derived extends Base {
  method() {
    // override
  }
}
```

---

## 三、类型系统规则

### 3.1 不支持 structural typing

**规则**: `arkts-no-structural-typing` | **级别**: Error | **错误码**: 10605030

两个类即使有相同的 public API 也不能互相赋值，必须使用继承或接口。

```typescript
// 错误：X 和 Y 是独立的类
let x: X = new Y();

// 正确：使用接口
interface Z { n: number }
class X implements Z { n: number = 0 }
class Y implements Z { n: number = 0 }
let x: Z = new Y(); // OK
```

### 3.2 禁止交叉类型

**规则**: `arkts-no-intersection-types` | **级别**: Error | **错误码**: 10605019

使用继承替代交叉类型。

```typescript
// 错误
type Employee = Identity & Contact;

// 正确
interface Employee extends Identity, Contact {}
```

### 3.3 禁止条件类型

**规则**: `arkts-no-conditional-types` | **级别**: Error | **错误码**: 10605022

不支持条件类型别名和 `infer` 关键字。

### 3.4 禁止 this 类型

**规则**: `arkts-no-typing-with-this` | **级别**: Error | **错误码**: 10605021

```typescript
// 错误
interface I {
  getHead(): this;
}

// 正确
interface I {
  getHead(): I;
}
```

### 3.5 禁止 typeof 用作类型

**规则**: `arkts-no-type-query` | **级别**: Error | **错误码**: 10605060

```typescript
// 错误
let n2: typeof n1;

// 正确
let n2: number;
```

### 3.6 禁止映射类型

**规则**: `arkts-no-mapped-types` | **级别**: Error | **错误码**: 10605083

### 3.7 禁止索引访问类型

**规则**: `arkts-no-aliases-by-index` | **级别**: Error | **错误码**: 10605028

### 3.8 禁止 as const 断言

**规则**: `arkts-no-as-const` | **级别**: Error | **错误码**: 10605142

### 3.9 类型转换仅支持 as T

**规则**: `arkts-as-casts` | **级别**: Error | **错误码**: 10605053

```typescript
// 错误
let c = <Circle>shape;

// 正确
let c = shape as Circle;
```

### 3.10 显式标注对象字面量类型

**规则**: `arkts-no-untyped-obj-literals` | **级别**: Error | **错误码**: 10605038

```typescript
// 错误
let o1 = { n: 42, s: 'foo' };
let o2: Object = { n: 42, s: 'foo' };

// 正确
class C { n: number = 0; s: string = '' }
let o1: C = { n: 42, s: 'foo' };
```

### 3.11 对象字面量不能用于类型声明

**规则**: `arkts-no-obj-literals-as-types` | **级别**: Error | **错误码**: 10605040

```typescript
// 错误
let o: { x: number, y: number } = { x: 2, y: 3 };
type S = Set<{ x: number, y: number }>;

// 正确
class O { x: number = 0; y: number = 0 }
let o: O = { x: 2, y: 3 };
type S = Set<O>;
```

### 3.12 泛型函数需显式标注类型实参

**规则**: `arkts-no-inferred-generic-params` | **级别**: Error | **错误码**: 10605034

当无法从参数推断时，必须显式指定泛型类型。

### 3.13 限制 utility 类型

**规则**: `arkts-no-utility-types` | **级别**: Error | **错误码**: 10605138

仅支持：`Partial<T>`、`Required<T>`、`Readonly<T>`、`Record<K, V>`。不支持其他 TypeScript Utility Types。

### 3.14 禁止确定赋值断言

**规则**: `arkts-no-definite-assignment` | **级别**: Warning | **错误码**: 10605134

```typescript
// 警告
let x!: number;

// 正确
let x: number = 0;
```

---

## 四、函数规则

### 4.1 使用箭头函数

**规则**: `arkts-no-func-expressions` | **级别**: Error | **错误码**: 10605046

```typescript
// 错误
let f = function (s: string) { ... };

// 正确
let f = (s: string) => { ... };
```

### 4.2 禁止函数内声明函数

**规则**: `arkts-no-nested-funcs` | **级别**: Error | **错误码**: 10605092

使用 lambda 函数替代。

### 4.3 禁止函数和静态方法中使用 this

**规则**: `arkts-no-standalone-this` | **级别**: Error | **错误码**: 10605093

`this` 只能在类的实例方法中使用。

### 4.4 禁止生成器函数

**规则**: `arkts-no-generators` | **级别**: Error | **错误码**: 10605094

使用 `async/await` 替代 `function*`。

### 4.5 禁止参数解构

**规则**: `arkts-no-destruct-params` | **级别**: Error | **错误码**: 10605091

```typescript
// 错误
function drawText({ text = '', location: [x, y] = [0, 0] }) { ... }

// 正确
function drawText(text: string, location: number[]) {
  let x = location[0];
  let y = location[1];
}
```

### 4.6 禁止 Function.apply/call/bind

**规则**: `arkts-no-func-apply-call` / `arkts-no-func-bind` | **级别**: Error

### 4.7 限制省略函数返回类型

**规则**: `arkts-no-implicit-return-types` | **级别**: Error | **错误码**: 10605090

当 return 语句调用未标注返回类型的函数时，必须显式标注返回类型。

### 4.8 不支持构造函数类型

**规则**: `arkts-no-ctor-signatures-funcs` | **级别**: Error | **错误码**: 10605106

使用 lambda 函数替代。

---

## 五、类规则

### 5.1 禁止在 constructor 中声明字段

**规则**: `arkts-no-ctor-prop-decls` | **级别**: Error | **错误码**: 10605025

所有字段必须在 class 体内显式声明。

```typescript
// 错误
class Person {
  constructor(private name: string) {}
}

// 正确
class Person {
  private name: string;
  constructor(name: string) {
    this.name = name;
  }
}
```

### 5.2 禁止类表达式

**规则**: `arkts-no-class-literals` | **级别**: Error | **错误码**: 10605050

### 5.3 类不允许 implements

**规则**: `arkts-implements-only-iface` | **级别**: Error | **错误码**: 10605051

只有接口可以被 `implements`。

### 5.4 仅支持一个静态块

**规则**: `arkts-no-multiple-static-blocks` | **级别**: Error | **错误码**: 10605016

### 5.5 禁止原型赋值

**规则**: `arkts-no-prototype-assignment` | **级别**: Error | **错误码**: 10605136

### 5.6 class 不能用作对象

**规则**: `arkts-no-classes-as-obj` | **级别**: Warning | **错误码**: 10605149

### 5.7 添加类属性可访问修饰符

**建议级别**: 建议

```typescript
// 不建议
class C {
  count: number = 0
}

// 建议
class C {
  private count: number = 0
  public getCount(): number { return this.count }
}
```

---

## 六、接口规则

### 6.1 接口中不支持构造签名

**规则**: `arkts-no-ctor-signatures-iface` | **级别**: Error | **错误码**: 10605027

### 6.2 接口不能继承类

**规则**: `arkts-extends-only-class` | **级别**: Error | **错误码**: 10605104

接口只能继承其他接口。

### 6.3 接口不能继承有相同方法的两个接口

**规则**: `arkts-no-extend-same-prop` | **级别**: Error | **错误码**: 106050102

### 6.4 禁止声明合并

**规则**: `arkts-no-decl-merging` | **级别**: Error | **错误码**: 10605103

---

## 七、运算符规则

### 7.1 一元运算符仅适用于数值

**规则**: `arkts-no-polymorphic-unops` | **级别**: Error | **错误码**: 10605055

```typescript
// 错误
let b = +'5';   // 编译时错误
let d = -'5';   // 编译时错误
let f = ~'5';   // 编译时错误

// 正确
let b = +5;
let d = -5;
let f = ~5;
```

### 7.2 禁止 in 运算符

**规则**: `arkts-no-in` | **级别**: Error | **错误码**: 10605066

使用 `instanceof` 替代。

### 7.3 instanceof 限制

**规则**: `arkts-instanceof-ref-types` | **级别**: Error | **错误码**: 10605065

左操作数必须是引用类型。

### 7.4 逗号运算符仅用于 for 循环

**规则**: `arkts-no-comma-outside-loops` | **级别**: Error | **错误码**: 10605071

### 7.5 部分支持展开运算符

**规则**: `arkts-no-spread` | **级别**: Error | **错误码**: 10605099

仅支持展开数组、Array 子类和 TypedArray。

---

## 八、语法限制规则

### 8.1 禁止解构赋值

**规则**: `arkts-no-destruct-assignment` | **级别**: Error | **错误码**: 10605069

```typescript
// 错误
let [one, two] = [1, 2];
[one, two] = [two, one];
let { x, y } = point;

// 正确
let arr = [1, 2];
let one = arr[0];
let two = arr[1];
let x = point.x;
let y = point.y;
```

### 8.2 禁止解构变量声明

**规则**: `arkts-no-destruct-decls` | **级别**: Error | **错误码**: 10605074

### 8.3 禁止 for...in

**规则**: `arkts-no-for-in` | **级别**: Error | **错误码**: 10605080

使用普通 `for` 循环或 `for...of` 替代。

### 8.4 禁止 with 语句

**规则**: `arkts-no-with` | **级别**: Error | **错误码**: 10605084

### 8.5 禁止 JSX

**规则**: `arkts-no-jsx` | **级别**: Error | **错误码**: 10605054

### 8.6 限制 throw 语句

**规则**: `arkts-limited-throw` | **级别**: Error | **错误码**: 10605087

只能抛出 `Error` 类或其派生类的实例。

```typescript
// 错误
throw 4;
throw 'error';

// 正确
throw new Error('error');
```

### 8.7 catch 语句不能标注类型

**规则**: `arkts-no-types-in-catch` | **级别**: Error | **错误码**: 10605079

```typescript
// 错误
catch (a: unknown) { ... }

// 正确
catch (a) { ... }
```

### 8.8 不支持 new.target

**规则**: `arkts-no-new-target` | **级别**: Error | **错误码**: 10605132

### 8.9 不支持 globalThis

**规则**: `arkts-no-globalthis` | **级别**: Warning | **错误码**: 10605137

---

## 九、模块规则

### 9.1 import 语句必须在最前面

**规则**: `arkts-no-misplaced-imports` | **级别**: Error | **错误码**: 10605150

动态 import 除外。

### 9.2 .ets 可导入 .ets/.ts/.js，反向不允许

**规则**: `arkts-no-ts-deps` | **级别**: Error | **错误码**: 10605147

### 9.3 禁止 require

**规则**: `arkts-no-require` | **级别**: Error | **错误码**: 10605121

使用 `import` 替代。

### 9.4 禁止 export = ...

**规则**: `arkts-no-export-assignment` | **级别**: Error | **错误码**: 10605126

### 9.5 禁止 ambient module 声明

**规则**: `arkts-no-ambient-decls` | **级别**: Error | **错误码**: 10605128

---

## 十、枚举规则

### 10.1 枚举成员必须类型相同

**规则**: `arkts-no-enum-mixed-types` | **级别**: Error | **错误码**: 10605111

```typescript
// 错误：混合 number 和 string
enum E { A = 1, B = 'b' }

// 正确
enum E1 { A = 1, B = 2 }
enum E2 { A = 'a', B = 'b' }
```

### 10.2 禁止 enum 声明合并

**规则**: `arkts-no-enum-merging` | **级别**: Error | **错误码**: 10605113

---

## 十一、命名空间规则

### 11.1 命名空间不能用作对象

**规则**: `arkts-no-ns-as-obj` | **级别**: Error | **错误码**: 10605114

### 11.2 命名空间中不支持非声明语句

**规则**: `arkts-no-ns-statements` | **级别**: Error | **错误码**: 10605116

---

## 十二、高性能编程规则

### 12.1 使用 const 声明不变的变量

**级别**: 建议

```typescript
// 不建议
let index = 10000; // 后续未修改

// 建议
const index = 10000;
```

### 12.2 number 类型避免整型浮点型混用

**级别**: 建议

```typescript
// 不建议
let intNum = 1;
intNum = 1.1; // 声明为整型后赋值浮点型

// 建议
let intNum = 1;
let doubleNum = 1.1;
```

### 12.3 避免数值溢出

加法、减法、乘法、指数运算应避免结果大于 `INT32_MAX`(2147483647) 或小于 `INT32_MIN`(-2147483648)。

### 12.4 循环中常量提取

**级别**: 建议

```typescript
// 不建议
for (let i = 0; i < n; i++) {
  total += arr[obj.start + obj.offset];
}

// 建议
const base = obj.start + obj.offset;
for (let i = 0; i < n; i++) {
  total += arr[base];
}
```

### 12.5 使用参数传递而非闭包

**级别**: 建议

```typescript
// 不建议：使用闭包访问外部变量
let arr = [0, 1, 2];
function foo(): number {
  return arr[0] + arr[1];
}

// 建议：通过参数传递
function foo(array: number[]): number {
  return array[0] + array[1];
}
foo(arr);
```

### 12.6 避免使用可选参数

**级别**: 建议

使用默认参数替代可选参数。

```typescript
// 不建议
function add(left?: number, right?: number): number | undefined { ... }

// 建议
function add(left: number = 0, right: number = 0): number {
  return left + right;
}
```

### 12.7 数值数组推荐 TypedArray

**级别**: 建议

```typescript
// 不建议
const arr = new Array<number>(1, 2, 3);

// 建议
const typedArray = Int32Array.from([1, 2, 3]);
```

### 12.8 避免稀疏数组

**级别**: 建议

```typescript
// 不建议
let result = new Array(100000);
result[9999] = 0;

// 建议：使用连续数组
let result: number[] = [];
for (let i = 0; i < 100000; i++) {
  result.push(0);
}
```

### 12.9 避免联合类型数组

**级别**: 建议

```typescript
// 不建议
let arr: (number | string)[] = [1, 'hello'];
let arrNum: number[] = [1, 1.1, 2]; // 混合整型和浮点型

// 建议：类型分离
let arrInt: number[] = [1, 2, 3];
let arrStr: string[] = ['hello', 'world'];
```

### 12.10 避免频繁抛出异常

**级别**: 建议

在性能敏感场景（如 for 循环）中，使用条件判断替代 try-catch。

---

## 十三、限制使用标准库

**规则**: `arkts-limited-stdlib` | **级别**: Error | **错误码**: 10605144

禁止使用的接口：
- `eval`
- `Object.__proto__`, `Object.assign`, `Object.create`, `Object.defineProperty`, `Object.freeze`, `Object.seal`, `Object.is` 等
- `Reflect.apply`, `Reflect.construct` 等
- `Proxy` 及其所有 handler 方法

---

## 十四、ESObject 使用限制

**规则**: `arkts-limited-esobj` | **级别**: Warning | **错误码**: 10605151

- 避免在非跨语言调用场景使用 `ESObject`
- `ESObject` 类型仅用于标注来自 .ts/.js 的动态对象

---

## 十五、编码风格规则

### 15.1 命名规范

| 类型 | 风格 | 示例 |
|------|------|------|
| 类名 | UpperCamelCase | `UserService` |
| 枚举名 | UpperCamelCase | `UserType` |
| 命名空间 | UpperCamelCase | `Base64Utils` |
| 变量名 | lowerCamelCase | `userName` |
| 方法名 | lowerCamelCase | `getUserInfo` |
| 参数名 | lowerCamelCase | `userId` |
| 常量名 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 枚举值 | UPPER_SNAKE_CASE | `TEACHER` |
| 布尔变量 | is/has/can 前缀 | `isLoading` |

### 15.2 避免否定布尔变量名

```typescript
// 不建议
let isNoError = true;
let isNotFound = false;

// 建议
let isError = false;
let isFound = true;
```

### 15.3 格式规范

- 2 空格缩进（换行用 4 空格）
- 行宽不超过 120 字符
- 条件/循环语句使用大括号
- `switch` 的 `case` 缩进一层
- 运算符放行末
- 每行只声明一个变量
- 单引号字符串
- 对象属性超过 4 个需换行
- `else`/`catch` 与关闭括号同行
- 大括号与语句同行

### 15.4 使用 T[] 表示数组

```typescript
// 不建议
let x: Array<number> = [1, 2, 3];

// 建议
let x: number[] = [1, 2, 3];
```

### 15.5 使用 Number.isNaN()

```typescript
// 错误
if (foo == Number.NaN) { ... }

// 正确
if (Number.isNaN(foo)) { ... }
```

### 15.6 数组遍历优先使用 Array 方法

```typescript
// 不建议
for (let i = 0; i < arr.length; i++) {
  result.push(arr[i] + 1);
}

// 建议
const result = arr.map(x => x + 1);
```

### 15.7 不要在控制条件中赋值

```typescript
// 错误
if (isFoo = false) { ... }

// 正确
const isFoo = false;
if (isFoo) { ... }
```

### 15.8 finally 块中禁止 return/break/continue/throw

```typescript
// 错误
try {
  return 1;
} finally {
  return 3; // 影响返回值
}

// 正确
try {
  return 1;
} finally {
  console.info('cleanup');
}
```

### 15.9 不省略浮点数前后的 0

```typescript
// 不建议
const num = .5;
const num = 2.;

// 建议
const num = 0.5;
const num = 2.0;
```

---

## 十六、ArkUI 组件规则

### 16.1 装饰器规范

| 装饰器 | 用途 | 检查项 |
|--------|------|--------|
| `@Entry` | 页面入口组件 | 每个页面文件仅一个 |
| `@Component` | 自定义组件 | 所有自定义组件必须有 |
| `@State` | 组件内状态 | 值变化触发 UI 刷新 |
| `@Prop` | 父组件单向传递 | 不可在子组件修改 |
| `@Link` | 双向数据绑定 | 父子组件双向同步 |
| `@Builder` | 轻量 UI 复用 | 用于封装 UI 描述 |
| `@BuilderParam` | UI 占位 | 用于组件插槽 |
| `@Extend` | 扩展原生组件样式 | 仅扩展原生组件 |
| `@Styles` | 样式复用 | 提取通用样式 |

### 16.2 build() 方法规范

- 必须有 `build()` 方法
- 根节点必须且仅有一个子组件
- 不允许声明本地变量
- 不允许在 if/else 外使用 if
- 不允许使用表达式

### 16.3 生命周期

| 方法 | 触发时机 | 注意事项 |
|------|----------|----------|
| `aboutToAppear` | 组件即将出现 | 初始化数据，订阅事件 |
| `aboutToDisappear` | 组件即将销毁 | 释放资源，取消订阅 |
| `onPageShow` | 页面显示 | 页面级 |
| `onPageHide` | 页面隐藏 | 页面级 |
| `onBackPress` | 返回键按下 | 返回 true 拦截 |

### 16.4 LazyForEach 规范

- `key` 函数必须返回唯一值
- 数据源必须实现 `IDataSource` 接口
- `cachedCount` 应根据设备内存动态设置

---

## 审查快速对照表

### 编译会失败的规则（Error 级别，必须检查）

| # | 规则 | 关键词 |
|---|------|--------|
| 1 | 禁止 any/unknown | `: any`, `: unknown` |
| 2 | 禁止 var | `var ` |
| 3 | 禁止 @ts-ignore | `@ts-ignore`, `@ts-nocheck` |
| 4 | 禁止解构赋值 | `let {`, `let [` |
| 5 | 禁止 for...in | `for (let x in` |
| 6 | 禁止函数表达式 | `function (` 赋值 |
| 7 | 禁止函数内声明函数 | 嵌套 `function` |
| 8 | 禁止 delete | `delete ` |
| 9 | 禁止 in 运算符 | `'x' in obj` |
| 10 | 禁止索引访问字段 | `obj['key']` |
| 11 | 禁止交叉类型 | `&` 用于类型 |
| 12 | 禁止条件类型 | `extends ? :` 用于类型 |
| 13 | 禁止映射类型 | `[Property in keyof]` |
| 14 | 禁止 constructor 属性声明 | `constructor(private` |
| 15 | 禁止类表达式 | `const X = class` |
| 16 | 禁止 implements 类 | `implements ClassName` |
| 17 | 禁止 new.target | `new.target` |
| 18 | 禁止 with | `with (` |
| 19 | 禁止 throw 非Error | `throw 'xxx'`, `throw 1` |
| 20 | 禁止 catch 类型标注 | `catch (e: ` |
| 21 | 类型转换仅 as T | `<Type>expr` |
| 22 | 禁止 as const | `as const` |
| 23 | 禁止 require | `require(` |
| 24 | import 必须在最前 | import 前有其他语句 |
| 25 | 禁止一元运算符用于非数值 | `+'string'` |

### 建议优化的规则（Warning/建议级别）

| # | 规则 | 说明 |
|---|------|------|
| 1 | 使用 const | 不变的变量声明为 const |
| 2 | 避免闭包 | 用参数传递替代闭包 |
| 3 | 避免可选参数 | 用默认参数替代 |
| 4 | 使用 TypedArray | 纯数值数组用 TypedArray |
| 5 | 避免稀疏数组 | 不创建大空数组 |
| 6 | 循环常量提取 | 提取循环外的不变计算 |
| 7 | 添加访问修饰符 | 类属性添加 public/private |
| 8 | 使用 T[] | 不用 Array<T> |
| 9 | 使用 Number.isNaN() | 不用 == NaN |
| 10 | Array 方法遍历 | 不用手写 for 循环遍历 |
