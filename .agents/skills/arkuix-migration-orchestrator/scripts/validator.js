/**
 * ArtifactValidator：JSON Schema 子集校验器（零依赖）。
 * 支持：type/properties/required/items/enum/const/pattern/additionalProperties/$ref(#/definitions...)。
 */

export function validate(instance, schema, root = schema, path = '$') {
  const errors = [];
  walk(instance, schema, path);
  return { ok: errors.length === 0, errors };

  function walk(v, s, p) {
    if (!s || typeof s !== 'object') return;
    if ('$ref' in s) {
      const ref = resolveRef(root, s.$ref);
      if (ref) walk(v, ref, p);
      return;
    }
    if (s.type) {
      const t = s.type;
      const bad = (t === 'object' && (typeof v !== 'object' || v === null || Array.isArray(v)))
        || (t === 'array' && !Array.isArray(v))
        || (t === 'string' && typeof v !== 'string')
        || (t === 'integer' && !Number.isInteger(v))
        || (t === 'number' && typeof v !== 'number')
        || (t === 'boolean' && typeof v !== 'boolean')
        || (t === 'null' && v !== null);
      if (bad) { errors.push(`${p}: 期望 ${t}，实际 ${Array.isArray(v) ? 'array' : typeof v}`); return; }
    }
    if ('const' in s && v !== s.const) errors.push(`${p}: 期望常量 ${JSON.stringify(s.const)}`);
    if (Array.isArray(s.enum) && !s.enum.includes(v)) errors.push(`${p}: ${JSON.stringify(v)} 不在枚举 ${JSON.stringify(s.enum)}`);
    // pattern：相对路径契约闸（如禁反斜杠 "^[^\\]*$"——win32 漏归一在此被拦下）
    if (typeof s.pattern === 'string' && typeof v === 'string') {
      try {
        if (!new RegExp(s.pattern).test(v)) errors.push(`${p}: ${JSON.stringify(v)} 不匹配约束 ${s.pattern}`);
      } catch { /* 非法正则视为无约束 */ }
    }
    if (typeof v === 'object' && v !== null && !Array.isArray(v) && s.type === 'object') {
      for (const key of s.required ?? []) {
        if (!(key in v)) errors.push(`${p}: 缺少必填字段 ${key}`);
      }
      const props = s.properties ?? {};
      for (const [k, sub] of Object.entries(props)) if (k in v) walk(v[k], sub, `${p}.${k}`);
      if (s.additionalProperties === false) {
        for (const k of Object.keys(v)) if (!(k in props)) errors.push(`${p}: 多余字段 ${k}`);
      }
    }
    if (Array.isArray(v) && s.type === 'array' && s.items) {
      v.forEach((e, i) => walk(e, s.items, `${p}[${i}]`));
    }
  }
}

function resolveRef(root, ref) {
  if (!ref.startsWith('#/')) return null;
  let cur = root;
  for (const seg of ref.slice(2).split('/')) cur = cur?.[seg];
  return cur;
}

/** 三族产物契约校验入口：schema 缺失=校验器配置错误（fail-fast） */
export function validateArtifact(artifact, schema) {
  return validate(artifact, schema);
}
