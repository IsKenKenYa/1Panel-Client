# Phase A 全量适配审计结果（2026-04-12）

## 脚本执行状态

- check_module_api_updates.py --all --json: exit 0
- check_module_client_coverage.py --all --json: exit 2（存在非 aligned 模块）

## 状态分布

- API 更新状态: {'unchanged': 15, 'updated': 12}
- 客户端覆盖状态: {'aligned': 2, 'extra_in_client': 1, 'missing_in_client': 24}

## 非理想模块清单

- API updated/missing_baseline: app, auth, container, file, group, host, log, process, setting, ssl, website, website_ssl
- 覆盖非 aligned: system_ssl, app, auth, backup, command, container, cronjob, dashboard, database, device, domains, file, firewall, group, host, log, openresty, process, runtime, setting, ssh, ssl, toolbox, website, website_ssl

## Top 10 风险模块

| 模块 | 覆盖状态 | 更新状态 | missing | extra | score |
|---|---|---|---:|---:|---:|
| website | missing_in_client | updated | 92 | 0 | 9220 |
| host | missing_in_client | updated | 45 | 0 | 4520 |
| database | missing_in_client | unchanged | 43 | 1 | 4301 |
| container | missing_in_client | updated | 41 | 1 | 4121 |
| runtime | missing_in_client | unchanged | 31 | 0 | 3100 |
| app | missing_in_client | updated | 25 | 0 | 2520 |
| backup | missing_in_client | unchanged | 25 | 7 | 2507 |
| file | missing_in_client | updated | 24 | 1 | 2421 |
| log | missing_in_client | updated | 19 | 0 | 1920 |
| ssh | missing_in_client | unchanged | 17 | 0 | 1700 |

### website

- 缺失端点（最多5条）:
  - GET /websites/:id
  - GET /websites/:id/config/:type
  - GET /websites/:id/https
  - GET /websites/ca/{id}
  - GET /websites/cors/{id}

### host

- 缺失端点（最多5条）:
  - GET /hosts/components/{name}
  - GET /hosts/disks
  - GET /hosts/monitor/setting
  - GET /hosts/tool/supervisor/process
  - POST /hosts/disks/mount

### database

- 缺失端点（最多5条）:
  - GET /databases/db/:name
  - GET /databases/db/item/:type
  - GET /databases/db/list/:type
  - GET /websites/databases
  - POST /databases
- 额外端点（最多5条）:
  - POST /databases/update

### container

- 缺失端点（最多5条）:
  - GET /containers/daemonjson
  - GET /containers/daemonjson/file
  - GET /containers/docker/status
  - GET /containers/image
  - GET /containers/image/all
- 额外端点（最多5条）:
  - POST /containers/command

### runtime

- 缺失端点（最多5条）:
  - GET /runtimes/:id
  - GET /runtimes/installed/delete/check/:id
  - GET /runtimes/php/:id/extensions
  - GET /runtimes/php/config/:id
  - GET /runtimes/php/container/:id

### app

- 缺失端点（最多5条）:
  - GET /apps/:key
  - GET /apps/checkupdate
  - GET /apps/detail/:appId/:version/:type
  - GET /apps/detail/node/:appKey/:version
  - GET /apps/details/:id

### backup

- 缺失端点（最多5条）:
  - GET /backups/local
  - GET /backups/options
  - GET /core/backups/client/:clientType
  - POST /backups
  - POST /backups/backup
- 额外端点（最多5条）:
  - POST /settings/snapshot
  - POST /settings/snapshot/del
  - POST /settings/snapshot/description/update
  - POST /settings/snapshot/import
  - POST /settings/snapshot/recover

### file

- 缺失端点（最多5条）:
  - GET /containers/daemonjson/file
  - GET /files/download
  - GET /logs/system/files
  - POST /backups/search/files
  - POST /containers/files/content
- 额外端点（最多5条）:
  - POST /files/download

### log

- 缺失端点（最多5条）:
  - GET /containers/search/log
  - GET /logs/system/files
  - GET /logs/tasks/executing/count
  - POST /ai/agents/channel/weixin/login
  - POST /containers/clean/log

### ssh

- 缺失端点（最多5条）:
  - GET /settings/ssh/conn
  - POST /hosts/ssh/cert
  - POST /hosts/ssh/cert/delete
  - POST /hosts/ssh/cert/search
  - POST /hosts/ssh/cert/sync
