# 测试提示词

以下是 hmos-dfx-analyzer 的典型使用提示词，用于验证技能功能。

## 崩溃日志分析

请使用 hmos-dfx-analyzer skill，分析这个 JSCrash 日志：jscrash-com.example.app-5678.log

## 冻屏日志分析

我的应用卡死没响应，这是冻屏日志 /data/log/faultlog/faultlogger/appfreeze-sample.log，帮我分析

## Native 崩溃修复

请修复当前 HarmonyOS 应用在运行时发生的崩溃（疑似 Native/C++ 崩溃），并完成编译。

## 无日志症状

点击应用就闪退，没有日志

## 非崩溃白屏

冷启动一直白屏但应用没退出，不要先复现，直接定位并修复。

## 批量分析

/analyze /data/log/faultlog/faultlogger/ 目录

## 修复意图（诊断后承接）

定位完顺便帮我修了：分析 cppcrash-sample.log

## 范围外输入（应拒答）

DevEco 里我的 ArkTS 代码编译报错了：Property 'name' does not exist on type，帮我修一下
