import { existsSync, readdirSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, join } from 'node:path';

/**
 * SDK 探测：候选序（目录一律经开发者确认，不自作主张）
 * 1. 显式参数（--sdk-dir，视同确认；指向多版本根时由 scan 层展开呈报）
 * 2. 环境变量 OH_SDK_DIR / OHOS_SDK_HOME / DEVECO_SDK_HOME（版本级直取；根级展开子版本）
 * 3. 平台默认安装位置（macOS/Windows/Linux 常规路径）
 * 全部候选统一按**推荐序**排序：kits 能力优先 + 语义化版本降序（最新在前）；
 * origin 仅做溯源（env 候选不再天然排前——DevEco 旧管理模式 SDK 不再抢首位）。
 */
export function detectSdkCandidates(explicitPath) {
  const candidates = [];
  if (explicitPath) {
    candidates.push({ path: explicitPath, origin: 'explicit' });
    return candidates;
  }
  for (const envVar of ['OH_SDK_DIR', 'OHOS_SDK_HOME', 'DEVECO_SDK_HOME']) {
    if (process.env[envVar]) {
      candidates.push(...sdkCandidatesOfRoot(process.env[envVar], `env:${envVar}`));
    }
  }
  const home = homedir();
  const defaultRoots = [
    join(home, 'Library', 'OpenHarmony', 'Sdk'),
    join(home, 'AppData', 'Local', 'OpenHarmony', 'Sdk'),
    join(home, '.openharmony', 'sdk'),
    join(home, 'Library', 'Huawei', 'Sdk'),
    join(home, 'AppData', 'Local', 'Huawei', 'Sdk')
  ];
  for (const root of defaultRoots) {
    candidates.push(...sdkCandidatesOfRoot(root, `default:${root}`));
  }
  return sortRecommended(candidates);
}

/** 根目录展开为版本候选（版本级直取单条；根级枚举有效子版本；不可读/无效返回空） */
export function sdkCandidatesOfRoot(path, origin) {
  const out = [];
  if (isValidSdkDir(path)) {
    out.push({ path, origin });
    return out;
  }
  try {
    const versions = readdirSync(path).filter((v) => isValidSdkDir(join(path, v)));
    for (const v of versions) out.push({ path: join(path, v), origin });
  } catch { /* 不存在/不可读 */ }
  return out;
}

/** 推荐序排序：kits 能力优先，同能力按语义化版本降序（最新在前） */
export function sortRecommended(candidates) {
  return [...candidates].sort((a, b) => {
    const ka = hasKitsDir(a.path) ? 1 : 0;
    const kb = hasKitsDir(b.path) ? 1 : 0;
    if (kb !== ka) return kb - ka;
    return compareSdkVersions(sdkVersionOf(b.path), sdkVersionOf(a.path));
  });
}

/** 语义化版本比较（数字段逐段，非字典序：'26.0.0' > '9' > '10'） */
export function compareSdkVersions(a, b) {
  const pa = String(a ?? '').split('.').map((s) => Number(s) || 0);
  const pb = String(b ?? '').split('.').map((s) => Number(s) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d;
  }
  return 0;
}

/** ：ets/kits 聚合目录在场（@kit.*.d.ts 展开能力判定） */
export function hasKitsDir(sdkPath) {
  return existsSync(join(sdkPath, 'ets', 'kits'));
}

/** 目录有效性校验：含 ets/api 且存在 @ohos.*.d.ts */
export function validateSdkDir(path) {
  try {
    const stat = statSync(path);
    if (!stat.isDirectory()) return { ok: false, reason: '不是目录' };
  } catch {
    return { ok: false, reason: '目录不存在或不可读' };
  }
 // 允许直接指到 SDK 根或其 ets/api 父级
  const apiDir = resolveApiDir(path);
  if (!apiDir) {
    return { ok: false, reason: '目录中未找到 ets/api 的 @ohos.*.d.ts（应为 OpenHarmony SDK 根目录）' };
  }
  return { ok: true, apiDir };
}

export function resolveApiDir(path) {
  const tries = [
    join(path, 'ets', 'api'),
    join(path, 'api')
  ];
  for (const dir of tries) {
    if (!existsSync(dir)) continue;
    try {
      const hasOhos = readdirSync(dir).some((f) => f.startsWith('@ohos.') && f.endsWith('.d.ts'));
      if (hasOhos) return dir;
    } catch {
      continue;
    }
  }
  return null;
}

function isValidSdkDir(path) {
  return resolveApiDir(path) !== null;
}

export function sdkVersionOf(path) {
  return basename(path) || 'unknown';
}
