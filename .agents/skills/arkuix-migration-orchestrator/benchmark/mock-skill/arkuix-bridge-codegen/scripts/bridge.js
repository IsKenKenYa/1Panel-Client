#!/usr/bin/env node
/** mock-bridge：F3 替身。产物= bridge-artifact（1 项等价桥接+1 unmapped） */
import { writeFileSync, mkdirSync, appendFileSync } from 'node:fs';
import { join } from 'node:path';

let out = './arkuix-orchestrate/bridge';
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) if (argv[i] === '--out') out = argv[i + 1];

if (process.env.ARKUIX_MOCK_LOG) appendFileSync(process.env.ARKUIX_MOCK_LOG, 'bridge\n');
if (process.env.ARKUIX_MOCK_BRIDGE === 'fail') { console.error('mock-bridge 模拟失败'); process.exit(5); }

mkdirSync(out, { recursive: true });
const artifact = {
  schema_version: 1,
  artifacts: [{
    name: 'DeviceInfoUdid',
    symbol: 'udid',
    module: '@ohos.deviceInfo',
    category: 'equivalent_bridge',
    files: {
      interface: 'commons/deviceInfo/interface/DeviceInfoUdidInterface.ets',
      local: 'commons/deviceInfo/utils/DeviceInfoUdidLocal.ets',
      arkui_x: 'commons/deviceInfo/utils/DeviceInfoUdidArkUIX.ets',
      android: '.arkui-x/android/app/src/main/java/com/arkuix/bridge/BridgeDeviceInfoUdid.java',
      ios: '.arkui-x/ios/app/BridgeSrc/BridgeDeviceInfoUdid.h',
    },
    local_status: 'migrated',
  }],
  unmapped_native_apis: ['@ohos.nonsense::mysteryApi'],
};
writeFileSync(join(out, 'bridge-artifact.json'), JSON.stringify(artifact, null, 2) + '\n');
writeFileSync(join(out, 'bridge-report.md'), '# mock 桥接报告\n');
console.log('mock-bridge 完成');
