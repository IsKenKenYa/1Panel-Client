# 代码审查检查清单

## 使用说明

在审查代码时，按以下清单逐项检查，确保代码质量。
对于 .ets 文件，**必须额外检查 ArkTS 专项清单（第 7-8 节）**。

---

## 1. 代码规范检查清单

### 1.1 命名规范

- [ ] 类名使用 UpperCamelCase（如 `UserService`）
- [ ] 枚举名使用 UpperCamelCase（如 `UserType`）
- [ ] 命名空间名使用 UpperCamelCase（如 `Base64Utils`）
- [ ] 函数名使用 lowerCamelCase（如 `getUserInfo`）
- [ ] 变量名使用 lowerCamelCase（如 `userName`）
- [ ] 参数名使用 lowerCamelCase（如 `userId`）
- [ ] 常量使用 UPPER_SNAKE_CASE（如 `MAX_RETRY_COUNT`）
- [ ] 枚举值使用 UPPER_SNAKE_CASE（如 `TEACHER`）
- [ ] 布尔变量使用 is/has/can 前缀（如 `isLoading`, `hasError`）
- [ ] 无否定布尔变量名（如 `isNotError` 应改为 `isError`）
- [ ] 名称具有描述性，避免缩写

### 1.2 格式规范

- [ ] 使用 2 空格缩进（换行用 4 空格）
- [ ] 每行不超过 120 字符
- [ ] 条件/循环语句使用大括号
- [ ] 大括号与语句同行（非 Allman 风格）
- [ ] else/catch 与关闭括号 } 同行
- [ ] 运算符两侧有空格
- [ ] 逗号后有空格
- [ ] 建议使用单引号
- [ ] 对象属性超过 4 个需换行
- [ ] 无尾随空格
- [ ] 文件末尾有空行

### 1.3 注释规范

- [ ] 复杂函数有注释说明
- [ ] 注释与代码同步更新
- [ ] 无废弃的注释代码
- [ ] TODO 注释有负责人和日期

---

## 2. 逻辑正确性检查清单

### 2.1 语法检查

- [ ] 无未使用的变量
- [ ] 无未使用的导入
- [ ] 无未使用的函数
- [ ] 类型声明与使用一致
- [ ] 无重复的变量/函数声明

### 2.2 逻辑错误

- [ ] 条件判断逻辑正确（if/else/switch）
- [ ] 循环边界正确（无 off-by-one 错误）
- [ ] 赋值与比较操作正确区分（= vs ===）
- [ ] 短路求值使用正确（&& ||）
- [ ] 异步操作正确处理（async/await/Promise）

### 2.3 边界条件

- [ ] 处理空数组情况
- [ ] 处理 null/undefined 情况
- [ ] 处理 0、负数、最大值情况
- [ ] 处理空字符串情况
- [ ] 处理边界索引（首/尾元素）

### 2.4 异常处理

- [ ] 可能出错的代码有 try-catch
- [ ] 异常被正确捕获和处理
- [ ] 错误信息有意义
- [ ] 资源在 finally 中释放
- [ ] finally 块中无 return/break/continue/throw

---

## 3. 安全性检查清单

### 3.1 输入验证

- [ ] 用户输入经过验证
- [ ] 参数类型和范围检查
- [ ] 防止 SQL 注入（使用参数化查询）
- [ ] 防止 XSS（转义用户输入）
- [ ] 文件路径验证

### 3.2 敏感信息

- [ ] 无硬编码的密码/密钥
- [ ] 敏感数据不记录在日志中
- [ ] 敏感数据传输使用加密

### 3.3 权限控制

- [ ] 敏感操作有权限检查
- [ ] 最小权限原则

---

## 4. 性能检查清单

### 4.1 ArkTS 高性能编程

- [ ] 不变的变量使用 const 声明
- [ ] number 变量不混用整型和浮点型
- [ ] 无数值溢出风险
- [ ] 循环中不变量已提取到循环外
- [ ] 优先使用参数传递而非闭包
- [ ] 使用默认参数替代可选参数
- [ ] 纯数值数组考虑使用 TypedArray
- [ ] 无稀疏数组
- [ ] 无联合类型数组
- [ ] 性能敏感场景无频繁异常

### 4.2 通用性能

- [ ] 无循环中的 I/O 操作
- [ ] 大对象及时释放
- [ ] 连接/资源正确关闭
- [ ] 缓存策略合理
- [ ] 无明显的内存泄漏
- [ ] 事件监听器正确移除
- [ ] 定时器正确清除

---

## 5. 可维护性检查清单

### 5.1 代码结构

- [ ] 函数长度合理（< 50行警告，> 100行错误）
- [ ] 嵌套深度合理（< 3层警告，> 5层错误）
- [ ] 参数数量合理（< 5个）
- [ ] 单一职责原则

### 5.2 代码重复

- [ ] 无重复代码块
- [ ] 公共逻辑抽取为函数
- [ ] 使用常量替代魔法数字
- [ ] 使用枚举替代魔法字符串

---

## 6. ArkTS 类型系统检查清单（.ets 文件必检）

### 6.1 静态类型

- [ ] 无 `any` 类型（arkts-no-any-unknown）
- [ ] 无 `unknown` 类型
- [ ] 无 `var` 声明（arkts-no-var）
- [ ] 无 `@ts-ignore` / `@ts-nocheck`
- [ ] 函数参数有类型标注
- [ ] 函数返回值有类型标注（需要时）
- [ ] 严格 null 检查：null 不能赋给非可空类型

### 6.2 类型系统限制

- [ ] 无 structural typing（不同类即使 API 相同也不能互换）
- [ ] 无交叉类型 `&`（使用继承替代）
- [ ] 无条件类型 `T extends ? :`
- [ ] 无 `infer` 关键字
- [ ] 无 `this` 类型（使用显式类型）
- [ ] 无 `typeof` 用作类型（使用具体类型）
- [ ] 无映射类型
- [ ] 无索引访问类型
- [ ] 无 `as const` 断言
- [ ] 类型转换仅用 `as T`（不用 `<T>expr`）
- [ ] 对象字面量有显式类型标注
- [ ] 不用对象字面量声明类型（使用 class/interface）
- [ ] 泛型函数类型实参显式标注（无法推断时）
- [ ] 仅使用 Partial/Required/Readonly/Record utility 类型
- [ ] 避免 `!:` 确定赋值断言

### 6.3 对象布局

- [ ] 无 `delete` 运算符
- [ ] 无 `Symbol()` API
- [ ] 无索引签名 `[key: string]: type`
- [ ] 通过点操作符访问字段（不用 `obj['key']`）
- [ ] 无 `#` 私有字段（使用 `private`）
- [ ] 不在运行时添加/删除属性
- [ ] 不修改对象方法

---

## 7. ArkTS 语法限制检查清单（.ets 文件必检）

### 7.1 函数相关

- [ ] 无函数表达式（使用箭头函数）
- [ ] 无函数内声明函数（使用 lambda）
- [ ] 函数和静态方法中无 `this`
- [ ] 无生成器函数 `function*`
- [ ] 无参数解构
- [ ] 无 `Function.apply`/`Function.call`
- [ ] 无 `Function.bind`

### 7.2 类相关

- [ ] 不在 constructor 中声明字段
- [ ] 无类表达式
- [ ] 类不 `implements` 另一个类（只 implements 接口）
- [ ] 不修改对象方法
- [ ] 仅一个静态块
- [ ] 不在原型上赋值

### 7.3 接口相关

- [ ] 接口中无构造签名
- [ ] 接口不继承类
- [ ] 接口不继承有相同方法的两个接口
- [ ] 无声明合并

### 7.4 运算符相关

- [ ] 一元 `+` `-` `~` 仅用于数值（不用于字符串转换）
- [ ] 无 `in` 运算符（使用 `instanceof`）
- [ ] `instanceof` 左操作数为引用类型
- [ ] 逗号运算符仅在 for 循环中
- [ ] 展开运算符仅用于数组

### 7.5 其他语法

- [ ] 无解构赋值
- [ ] 无 `for...in`
- [ ] 无 `with` 语句
- [ ] 无 JSX
- [ ] `throw` 仅抛出 Error 实例
- [ ] `catch` 不标注类型
- [ ] 无 `new.target`
- [ ] 无 `globalThis`
- [ ] 枚举成员类型一致（不全 number 和 string 混合）
- [ ] 无 enum 声明合并
- [ ] 命名空间不作为对象使用
- [ ] 命名空间中无非声明语句

### 7.6 模块相关

- [ ] import 语句在最前面
- [ ] 无 `require()`
- [ ] 无 `export = ...`
- [ ] 无 ambient module 声明

### 7.7 标准库限制

- [ ] 无 `eval`
- [ ] 无 `Object.assign`/`Object.create`/`Object.freeze` 等
- [ ] 无 `Proxy`
- [ ] 无 `Reflect`
- [ ] 不滥用 `ESObject`

---

## 8. ArkUI 组件规范检查清单（.ets 文件必检）

### 8.1 装饰器

- [ ] 组件有 @Component 装饰器
- [ ] 页面入口有 @Entry 装饰器
- [ ] 状态变量使用正确的装饰器（@State/@Prop/@Link）
- [ ] 自定义组件名以大写字母开头

### 8.2 build() 方法

- [ ] 必须有 build() 方法
- [ ] 根节点仅一个子组件
- [ ] build() 内不声明本地变量
- [ ] build() 内不使用表达式

### 8.3 内存相关

- [ ] List/Grid/WaterFlow 的 cachedCount 设置合理
- [ ] LazyForEach 的 key 函数返回唯一值
- [ ] aboutToDisappear 中释放资源
- [ ] 图片资源合理加载

### 8.4 生命周期

- [ ] aboutToAppear 正确初始化
- [ ] aboutToDisappear 正确清理
- [ ] onPageShow/onPageHide 正确使用
- [ ] onBackPress 正确处理返回

---

## 9. 审查结果判定

### 通过标准

| 级别 | 标准 |
|------|------|
| PASS | 无 Critical/Error 问题 |
| PASS_WITH_WARNINGS | 无 Critical/Error，有 Warning |
| FAIL | 存在 Critical 或 Error 问题 |

### 问题处理

1. **Critical**: 必须立即修复
2. **Error**: 必须在合并前修复
3. **Warning**: 建议修复
4. **Info**: 可选修复

---

## 审查记录模板

```markdown
## 审查记录

**审查时间**: YYYY-MM-DD HH:mm
**审查文件**: file1.ets, file2.ets
**审查结果**: PASS / PASS_WITH_WARNINGS / FAIL

### 问题列表

| # | 级别 | 规则ID | 文件 | 行号 | 问题描述 | 状态 |
|---|------|--------|------|------|----------|------|
| 1 | Error | arkts-no-any-unknown | xxx.ets | 123 | 使用了 any 类型 | 待修复 |
| 2 | Warning | - | yyy.ets | 456 | 建议使用 const | 可选 |

### 审查人签名

- 代码审查: 通过
- 建议修复后合并
```
