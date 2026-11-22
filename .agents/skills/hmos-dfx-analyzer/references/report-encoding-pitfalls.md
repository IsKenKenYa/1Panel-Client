# Windows/PowerShell 分节正文合并的 GBK 二次编码陷阱

适用范围：批量分析的分节正文在 Windows/PowerShell 下合并后再交给
`scripts/export_report.py` 的场景。

## 现象

最终 HTML 报告中**分析器正文全量中文乱码**（如「故障分析报告」→「鏁呴殰鍒嗘瀽鎶ュ憡」），
而分诊汇总表、标题、命令行参数传入的内容完全正常。

## 成因

PowerShell 5.1 的 `Get-Content` 缺省按 ANSI(GBK) 解码文件。用 shell 管道拼接合并
UTF-8 分节正文时（`Get-Content <分节> -Raw`、`Get-Content | Set-Content`、`Out-File`、
`cat > 合并文件` 等），UTF-8 字节被按 GBK 误解码再以 UTF-8 写回——形成二次编码。

三个特征使该污染**静默且难定位**：

1. 会话内文本全程正常（污染只发生在磁盘合并这一跳）；
2. 脚本严格 UTF-8 读取不报错（二次编码后的字节序列本身是合法 UTF-8）；
3. 命令行参数（如 `--title`）与脚本内联构造的内容不经该路径，保持正常——
   报告内乱码/正常内容的分界线精确暴露污染范围。

数学验证：`'故障分析报告'.encode('utf-8').decode('gbk')` = `鏁呴殰鍒嗘瀽鎶ュ憡`，
与实测乱码逐字吻合。

## 预防（唯一合法路径）

分节合并不走 shell——把「汇总表 → 各类型分节」的文件**按顺序逐一 `--input` 传给
export_report.py**，由脚本在 Python 内以 UTF-8 全链路拼接。`PYTHONIOENCODING`
只管 Python 进程的 stdin/stdout 编码，管不到 PowerShell 读盘解码，不能作为替代手段。

已有相关护栏（本 Skill 的既有约定，与本文件互补）：

- `Get-Content | python` 管道禁令（正文不经 shell 解码进脚本）；
- 报告正文优先 `--input` 文件参数传入（文件直读，UTF-8 无歧义）。

## 已污染报告的恢复

二次编码可逆：`乱码文本.encode('gbk').decode('utf-8')` 即还原原文。对整份已污染的
HTML 报告，用同变换批量还原后重新落盘即可恢复。
