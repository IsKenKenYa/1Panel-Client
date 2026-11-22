# B-S3 验证工程：native库缺失（UnsatisfiedLinkError 闪退）

## 场景
删除 APK 中 `lib/arm64-v8a/libarkui_android.so` → 真实 `dlopen failed` → `UnsatisfiedLinkError: No implementation found for ... nativeInitAppMode` → `FATAL EXCEPTION` 闪退。

## skill 预期
- 症状：闪退（FATAL EXCEPTION，栈：MyApplication.onCreate → initApplication → nativeInitAppMode）
- FAQ：**A-1** 命中（`UnsatisfiedLinkError: No implementation found for ...` + `dlopen failed: library "libarkui_android.so" not found`）
- 维度①：链断点 pre-S1 段（lib加载失败，#5 StageActivity 后无后续锚点）

## 复现步骤
```powershell
# 1. 构建正常demo（用 test-case 的 bs-normal 工程或任意正常工程）
ace build apk
# 2. 删so重打包（resources.arsc必须STORED）
python -c "
import zipfile,shutil
src=r'<apk路径>'; tmp=src+'.tmp'
with zipfile.ZipFile(src,'r') as zin:
    with zipfile.ZipFile(tmp,'w') as zout:
        for item in zin.infolist():
            if 'libarkui_android.so' in item.filename: continue
            data=zin.read(item.filename)
            if 'resources.arsc' in item.filename:
                zi=zipfile.ZipInfo(item.filename); zi.compress_type=zipfile.ZIP_STORED
                zout.writestr(zi,data)
            else: zout.writestr(item,data)
shutil.move(tmp,src)"
# 3. zipalign + apksigner 签名 + 安装 + 启动
```

## 实测关键日志（2026-10 实证）
```
E/LibraryLoader: Could not load android ace lib. Exception:dlopen failed: library "libarkui_android.so" not found
E/StageApplicationDelegate: System.load failed dlopen failed: library ".../libarkui_android.so" not found
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: java.lang.UnsatisfiedLinkError: No implementation found for void ohos.ace.adapter.AppModeConfig.nativeInitAppMode() ...
```
