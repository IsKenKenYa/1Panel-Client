# openFormManager技能验证脚本

本目录包含用于验证openFormManager API调用参数的辅助脚本。

## 脚本列表

### validate_params.py

用于验证openFormManager API调用所需的参数。

#### 功能
- 验证form_config.json配置文件格式
- 验证want参数的完整性
- 检查卡片尺寸值是否有效

#### 使用方法

**验证配置文件**:
```bash
python validate_params.py --config path/to/form_config.json
```

**验证want参数**:
```bash
python validate_params.py --bundle com.example.app --ability EntryFormAbility
```

**完整参数验证**:
```bash
python validate_params.py \
  --bundle com.samples.formmanagerdemo \
  --ability EntryFormAbility \
  --form-name widget \
  --dimension 2 \
  --module entry
```

#### 输出格式

脚本输出JSON格式的验证结果:
```json
{
  "success": true,
  "errors": [],
  "warnings": [
    "参数不完整，将显示默认卡片"
  ]
}
```

#### 参数说明

| 参数 | 说明 | 必填 |
|------|------|------|
| --config | form_config.json文件路径 | 否 |
| --bundle | bundleName | 否 |
| --ability | abilityName | 否 |
| --form-name | 卡片名称 | 否 |
| --dimension | 卡片尺寸(1/2/3/4) | 否 |
| --module | 模块名称 | 否 |

## 使用场景

1. **开发阶段**: 验证卡片配置文件格式是否正确
2. **调试阶段**: 验证openFormManager参数是否完整
3. **测试阶段**: 自动化参数验证

## 注意事项

- 验证脚本只能检查参数格式，无法验证参数值是否与实际配置匹配
- 建议在调用openFormManager前先使用此脚本验证参数