# WEBSITE 模块API端点详细分析

> 基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 自动生成
> 生成时间: 2026-03-13 16:41:48

## API端点总览

- 端点数量: **87**
- 方法总数: **90**

| 方法 | 数量 |
|------|------|
| GET | 16 |
| POST | 74 |

## API端点详情

### `/websites`

#### POST

**摘要**: Create website

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/:id`

#### GET

**摘要**: Search website by id

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/:id/config/:type`

#### GET

**摘要**: Search website nginx by id

**标签**: Website Nginx

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/:id/https`

#### GET

**摘要**: Load https conf

**标签**: Website HTTPS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

#### POST

**摘要**: Update https conf

**标签**: Website HTTPS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/acme`

#### POST

**摘要**: Create website acme account

**标签**: Website Acme

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/acme/del`

#### POST

**摘要**: Delete website acme account

**标签**: Website Acme

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/acme/search`

#### POST

**摘要**: Page website acme accounts

**标签**: Website Acme

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/acme/update`

#### POST

**摘要**: Update website acme account

**标签**: Website Acme

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/path`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/path/update`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/auths/update`

#### POST

**摘要**: Get AuthBasic conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/batch/group`

#### POST

**摘要**: Batch set website group

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/batch/https`

#### POST

**摘要**: Batch set HTTPS for websites

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/batch/operate`

#### POST

**摘要**: Batch operate websites

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca`

#### POST

**摘要**: Create website ca

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/del`

#### POST

**摘要**: Delete website ca

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/download`

#### POST

**摘要**: Download CA file

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/obtain`

#### POST

**摘要**: Obtain SSL

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/renew`

#### POST

**摘要**: Obtain SSL

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/search`

#### POST

**摘要**: Page website ca

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ca/{id}`

#### GET

**摘要**: Get website ca

**标签**: Website CA

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/websites/check`

#### POST

**摘要**: Check before create website

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/config`

#### POST

**摘要**: Load nginx conf

**标签**: Website Nginx

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/config/update`

#### POST

**摘要**: Update nginx conf

**标签**: Website Nginx

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/cors/update`

#### POST

**摘要**: Update CORS Config

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/cors/{id}`

#### GET

**摘要**: Get CORS Config

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/websites/crosssite`

#### POST

**摘要**: Operate Cross Site Access

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/databases`

#### GET

**摘要**: Get databases

**标签**: Website

**响应**:

- `200`: OK

---

#### POST

**摘要**: Change website database

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/default/html/:type`

#### GET

**摘要**: Get default html

**标签**: Website

**响应**:

- `200`: OK

---

### `/websites/default/html/update`

#### POST

**摘要**: Update default html

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/default/server`

#### POST

**摘要**: Change default server

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/del`

#### POST

**摘要**: Delete website

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dir`

#### POST

**摘要**: Get website dir

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dir/permission`

#### POST

**摘要**: Update Site Dir permission

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dir/update`

#### POST

**摘要**: Update Site Dir

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dns`

#### POST

**摘要**: Create website dns account

**标签**: Website DNS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dns/del`

#### POST

**摘要**: Delete website dns account

**标签**: Website DNS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dns/search`

#### POST

**摘要**: Page website dns accounts

**标签**: Website DNS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/dns/update`

#### POST

**摘要**: Update website dns account

**标签**: Website DNS

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains`

#### POST

**摘要**: Create website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/:websiteId`

#### GET

**摘要**: Search website domains by websiteId

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| websiteId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/del`

#### POST

**摘要**: Delete website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/domains/update`

#### POST

**摘要**: Update website domain

**标签**: Website Domain

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/exec/composer`

#### POST

**摘要**: Exec Composer

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs`

#### GET

**摘要**: Get website upstreams

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs/create`

#### POST

**摘要**: Create website upstream

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs/del`

#### POST

**摘要**: Delete website upstream

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs/file`

#### POST

**摘要**: Update website upstream file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/lbs/update`

#### POST

**摘要**: Update website upstream

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/leech`

#### POST

**摘要**: Get AntiLeech conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/leech/update`

#### POST

**摘要**: Update AntiLeech

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/list`

#### GET

**摘要**: List websites

**标签**: Website

**响应**:

- `200`: OK

---

### `/websites/log`

#### POST

**摘要**: Operate website log

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/nginx/update`

#### POST

**摘要**: Update website nginx conf

**标签**: Website Nginx

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/operate`

#### POST

**摘要**: Operate website

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/options`

#### POST

**摘要**: List website names

**标签**: Website

**响应**:

- `200`: OK

---

### `/websites/php/version`

#### POST

**摘要**: Update php version

**标签**: Website PHP

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxies`

#### POST

**摘要**: Get proxy conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxies/file`

#### POST

**摘要**: Update proxy file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxies/update`

#### POST

**摘要**: Update proxy conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxy/clear`

#### POST

**摘要**: Clear Website proxy cache

**标签**: Website

**响应**:

- `200`: OK

---

### `/websites/proxy/config`

#### POST

**摘要**: update website proxy cache config

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/proxy/config/{id}`

#### GET

**摘要**: Get website proxy cache config

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/websites/realip/config`

#### POST

**摘要**: Set Real IP

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/realip/config/{id}`

#### GET

**摘要**: Get Real IP Config

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/websites/redirect`

#### POST

**摘要**: Get redirect conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/redirect/file`

#### POST

**摘要**: Update redirect file

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/redirect/update`

#### POST

**摘要**: Update redirect conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/resource/{id}`

#### GET

**摘要**: Get website resource

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | id |

**响应**:

- `200`: OK

---

### `/websites/rewrite`

#### POST

**摘要**: Get rewrite conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/rewrite/custom`

#### GET

**摘要**: List custom rewrite

**标签**: Website

**响应**:

- `200`: OK

---

#### POST

**摘要**: Operate custom rewrite

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/rewrite/update`

#### POST

**摘要**: Update rewrite conf

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/search`

#### POST

**摘要**: Page websites

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl`

#### POST

**摘要**: Create website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/:id`

#### GET

**摘要**: Search website ssl by id

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| id | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/del`

#### POST

**摘要**: Delete website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/download`

#### POST

**摘要**: Download SSL  file

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/obtain`

#### POST

**摘要**: Apply  ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/resolve`

#### POST

**摘要**: Resolve website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/search`

#### POST

**摘要**: Page website ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/update`

#### POST

**摘要**: Update ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/upload`

#### POST

**摘要**: Upload ssl

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/ssl/upload/file`

#### POST

**摘要**: Upload SSL file

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| type | formData | unknown | 是 | type |
| description | formData | unknown | 否 | description |
| sslID | formData | unknown | 否 | sslID |
| privateKeyFile | formData | unknown | 是 | privateKeyFile |
| certificateFile | formData | unknown | 是 | certificateFile |

**响应**:

- `200`: OK

---

### `/websites/ssl/website/:websiteId`

#### GET

**摘要**: Search website ssl by website id

**标签**: Website SSL

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| websiteId | path | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/stream/update`

#### POST

**摘要**: Update Stream Config

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---

### `/websites/update`

#### POST

**摘要**: Update website

**标签**: Website

**参数**:

| 名称 | 位置 | 类型 | 必填 | 描述 |
|------|------|------|------|------|
| request | body | unknown | 是 | request |

**响应**:

- `200`: OK

---
