# HarmonyOS SDK 检索 scripts 替换包

本目录可整体替换 `hmos-one-sdk-skill/scripts/`。预编译入口不依赖本仓库根目录中的 `data/`、`evaluate/`、`tests/`、`dist/`、`node_modules/` 或 TypeScript 编译器。

要求：Node.js 24 或更高版本。目标文档集原有 `package.json` 已声明 `"type": "module"`，无需修改，也无需安装 npm 依赖。

运行时只执行 JavaScript：稳定入口为 `scripts/search.js`、`scripts/build_index.js` 和 `scripts/server.js`，它们只加载 `scripts/runtime/*.js`。不要直接执行同目录下的 `.ts` 源文件，也不需要 TypeScript 运行器。

## 替换

在目标文档集根目录操作：

```bash
mv scripts scripts.baseline
cp -a /path/to/this-branch/scripts ./scripts
node scripts/search.js "Wear Engine Kit P2P_COMMUNICATION" --top 5 --json
```

验证完成后可自行删除 `scripts.baseline`。本包没有自动删除旧目录的安装脚本。

## 兼容接口

```js
import { search } from './scripts/search.js';

const [hits, documents, queryTerms, elapsedSeconds, totalSearched] =
  search('Wear Engine Kit P2P_COMMUNICATION', 10, undefined, false);
```

前四个参数和五元素返回值与基线一致。可选第五参数为拒答模式：

- `default`：默认档，278 条正样本全部保留。
- `conservative`：比默认更宽松。
- `aggressive`：更严格，允许少量正样本损失。

CLI 保留 `--top`、`--category`、`--snippet`、`--json`，新增 `--mode default|conservative|aggressive`。JSON 字段与基线一致；拒答表现为 `count: 0, results: []`。

非 JSON 模式触发拒答时返回：`建议选择其他检索方法`。

## 建库与摘要

```bash
node scripts/build_index.js
node scripts/build_index.js --force
node scripts/build_index.js --check
node scripts/build_index.js --snapshot
```

默认语料是文档集根目录，递归读取 `SUB_SKILL.md`。读取时会把文档集使用的 `#Uxxxx` 中文路径转义规范化为 Unicode。也可用 `--source` 和 `--output` 指定路径。普通调用在索引已是最新时直接跳过；旧版或过期索引需显式指定 `--force` 后安全地完整重建。

默认不生成正文快照。第一次使用 `--snippet` 时若 `scripts/index/corpus.json.gz` 不存在，会校验语料指纹并全量生成；`--snapshot` 可在建库时预生成。

`index/` 是可直接检索的预建索引；`data/jieba-0.42.1/` 仅在重新建库时加载，日常检索不会加载完整词典或 HMM。第三方来源和许可证见 `THIRD_PARTY_NOTICES.md`。

`runtime/` 是已经生成的纯 JavaScript 运行时；日常使用不需要仓库根目录的 `package.json` 或任何 npm 依赖。顶层 `.js` 文件是稳定入口，`.ts` 文件仅供维护和审阅，不参与运行。维护者修改源码后可在完整开发仓库运行 `npm run package:dropin` 重新生成运行时。
