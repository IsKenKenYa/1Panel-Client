# NetworkBoost_WeakSignalPrediction
---
# NetworkBoost_WeakSignalPrediction
#### 概述
弱信号预测相关信息。
**起始版本：** 5.1.0(18)
**相关模块：**  [NetworkBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| bool[isLastPredictionValid](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction) | 最近一次的弱信号预测是否有效，true表示最近一次的弱信号预测依旧有效，false表示最近一次的弱信号预测失效，此时startTime和duration参数忽略。 |
| uint32_t[startTime](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction) | 预计多长时间进入弱信号（单位：s），取值范围为0和任意正数。 |
| uint32_t[duration](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction) | 预计在弱信号区域停留时长（单位：s），取任意正数。取值0，此次预测结果无效。 |
#### 结构体成员变量说明
#### duration
```
uint32_t NetworkBoost_WeakSignalPrediction::duration
```
**描述**
预计在弱信号区域停留时长（单位：s），取任意正数。取值0，此次预测结果无效。
#### isLastPredictionValid
```
bool NetworkBoost_WeakSignalPrediction::isLastPredictionValid
```
**描述**
最近一次的弱信号预测是否有效，true表示最近一次的弱信号预测依旧有效，false表示最近一次的弱信号预测失效，此时startTime和duration参数忽略。
#### startTime
```
uint32_t NetworkBoost_WeakSignalPrediction::startTime
```
**描述**
预计多长时间进入弱信号（单位：s），取值范围为0和任意正数。