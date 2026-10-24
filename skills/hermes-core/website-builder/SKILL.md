---
name: website-builder
description: 当用户要求建站、发布网页、制作个人主页或产品展示页，或在平台能力开放后发布带后端及共享持久数据的网站时使用。
---

# Vela 建站 Skill

## 概述

本 Skill 指导 AI 通过 Vela API 创建、发布和访问网站。静态托管始终按套餐权益使用；
只有后端能力门禁明确开放 `fetch-v1` 时，才可以发布带后端的网站；
持久数据还须独立通过 `rivet-sql-v1` 数据能力门禁。
用户不需要任何云账号或密钥，Vela 统一托管网站资源。

**后端执行与数据存储是两项独立能力。** 只开放后端时，可提供所有者访问的计算与校验 API，
但没有共享持久化；同时开放数据能力时，同一网站可使用隔离的持久 SQL，所有者写入后，
持有效分享码的访客刷新可读取同一份数据。公开访客写入尚不支持，JS 内存也不保证保留。
必须先查询实际能力，再判断需求是否匹配，见「后端与数据能力检查」与「能力边界」。

## ⚠️ 面向用户的输出规范（最高优先级）

**以下所有技术细节仅供 AI 内部调用使用，严禁向用户展示。**

### 对用户说话时

- 把进度描述为简单的自然语言步骤，例如"正在为你创建网站…"、"正在生成网页…"、"正在部署…"、"部署完成！这是你的网站地址：…"
- 不要提及 API 路径、HTTP 方法、请求头、JSON 字段名、状态码、operation_id、release_id、bundle_id、pass_id 等内部标识
- 不要提及任何后端服务名称、云厂商名称、存储或托管产品名称。用户全程只需知道"Vela 帮你托管了网站"
- 不要展示 curl 命令、JSON 请求体、原始 API 响应
- 不要在代码块中输出 Python/JavaScript 脚本或 import 语句，用户不需要看到这些
- 不要输出"Running code"、"Updating tasks"等工具执行日志
- 用户问"怎么做到的"，回答"Vela 平台帮你托管了网站，你不需要关心底层细节"
- 遇到错误时根据服务端返回的具体原因，用用户能理解的话说明；保留错误中的限制信息，不猜测原因。
- 部署过程中用一句简单的话报告进度即可，不要输出中间步骤的代码或日志

**能力限制必须明确告知**：用户想要保存共享数据时，先检查实际的数据能力。
数据门禁开放且需求符合所有者写入、分享访客只读的范围时，可以实现共享持久数据的网站；
数据门禁未开放，或需求需要公开访客写入时，必须说明具体限制，获得用户确认后才可提供替代方案。
不要把已开放的后端或持久数据也描述成不可用。
这是能力边界，必须说清楚，见「能力边界」一节。

### AI 内部执行时

以下技术细节仅用于 AI 自身调用 API，AI 可以参考但不输出给用户。

## 认证与 API 地址

<!-- vela-website-credential-fallback:v1 -->

每个实例拥有一个由平台预置的永久凭据（`VELA_WEBSITE_KEY`）。
凭据格式为 `vik_<key_id>_<secret>`，权限范围绑定该实例及其所属用户，
只能调用建站相关接口，不暴露任何账号级权限；凭据不得复制或外泄。

**取值方式**（按顺序取第一个非空值）：

1. 当前执行环境中的 `VELA_WEBSITE_KEY`。
2. 环境变量缺失或为空时，在**同一次 terminal 命令的子 Shell** 中加载平台预置的 `/etc/vela/website-credential.env`，并 export `VELA_WEBSITE_KEY` 和 `VELA_API_BASE`。
3. 只有环境变量和文件兜底都不可用（文件缺失、不可读、加载失败或 Key 仍为空），才停下来提示用户需要通过 Vela 平台初始化实例，**不要继续调用 API**。

**环境变量为空不等于实例未初始化。必须先尝试凭据文件兜底，不要求用户重启 Agent、gateway 或实例。**

API 地址也优先使用当前环境中的非空 `VELA_API_BASE`，缺失时尝试同一凭据文件；
加载文件不得覆盖已有的非空环境变量。如果地址仍为空，按站点归属取生产默认值：
国内 `https://api.lightvela.com`、国际 `https://api.lightvela.ai`。
**只有 API 地址有默认值，凭据没有默认值。**

**加载凭据和使用凭据必须放在同一次终端执行中。** 将 API 请求或子脚本放在下面子 Shell 的结尾，
不要先单独执行加载命令，再在另一次 terminal 调用中使用凭据；每次认证命令都要重复加载步骤。
子 Shell 内 export 的变量可供同一命令启动的 Python/Node/其他子脚本读取，不会修改外层会话。
禁止输出 Key、凭据文件内容或含凭据的原始响应，禁止写入聊天、日志、项目代码或上传文件；
凭据处理及后续 API 请求期间保持 `set +x`，不要开启 shell tracing，不需要重启。

读取示例（在同一个子 Shell 中继续执行建站 API 请求或脚本）：

```bash
(
  set +x
  _vela_env_key="${VELA_WEBSITE_KEY:-}"
  _vela_env_base="${VELA_API_BASE:-}"
  if [ -z "$_vela_env_key" ] || [ -z "$_vela_env_base" ]; then
    if [ -f /etc/vela/website-credential.env ] && [ -r /etc/vela/website-credential.env ]; then
      # 文件仅由平台维护；抑制加载输出，失败时丢弃部分加载的值。
      if ! . /etc/vela/website-credential.env >/dev/null 2>&1; then
        VELA_WEBSITE_KEY=
        VELA_API_BASE=
      fi
    fi
  fi
  VELA_WEBSITE_KEY="${_vela_env_key:-${VELA_WEBSITE_KEY:-}}"
  VELA_API_BASE="${_vela_env_base:-${VELA_API_BASE:-}}"
  unset _vela_env_key _vela_env_base
  if [ -z "$VELA_WEBSITE_KEY" ]; then
    printf '%s\n' 'website credential unavailable' >&2
    exit 1
  fi
  VELA_API_BASE="${VELA_API_BASE:-https://api.lightvela.com}"
  export VELA_WEBSITE_KEY VELA_API_BASE
  KEY="$VELA_WEBSITE_KEY"
  API_BASE="$VELA_API_BASE"

  # 在这里执行建站 API 请求或子脚本；不要打印 KEY，不要重新开启 set -x。
)
```

请求头：

```
Authorization: Vela-Instance-Key <key>
Content-Type: application/json
```

## 响应格式（所有接口统一）

所有成功响应的 HTTP 状态码为 200 或 201，响应体统一包裹为：

```json
{
  "code": "OK",
  "message": "success",
  "data": { ... },
  "request_id": "req-xxx"
}
```

**始终从 `data` 字段提取业务数据。** 错误响应的 `code` 为错误码字符串（见「错误处理」一节），`data` 可能为 null。

## 内部 API 参考（不向用户展示）

所有路径以 `/v1/websites` 为前缀，**不含** `/instance`。

| 方法 | 路径 | 用途 |
|------|------|------|
| GET | /v1/websites/capability | 查询建站权益和用量 |
| POST | /v1/websites | 创建站点 |
| GET | /v1/websites | 列出已有站点 |
| GET | /v1/websites/{siteId} | 查询站点详情 |
| POST | /v1/websites/{siteId}/releases | 创建发布 |
| GET | /v1/websites/{siteId}/releases | 列出发布历史 |
| GET | /v1/websites/{siteId}/operations/{opId} | 查询操作状态 |
| DELETE | /v1/websites/{siteId} | 删除站点 |

## 完整流程

### 第一步：查询权益（内部）

调用能力查询接口，确认当前开放的建站能力，然后按用户需求制作并发布网站。

```
GET {API_BASE}/v1/websites/capability
```

始终从响应的 `data` 读取实际能力；遇到错误时按服务端返回的原因处理，不展示原始 JSON。

### 后端与数据能力检查（内部）

- 检查完整响应中的 `data.backend.enabled`（后端执行）和 `data.data.enabled`（服务端数据）。
- **字段缺失、null、未知值或不是布尔 true，一律按 false / 不可用处理。** 旧服务未返回这些字段时继续静态流程，不猜测能力。
- 默认后端与数据能力关闭。仅当 `data.backend.enabled` 为布尔 true 且 `data.backend.contract` 严格等于 `fetch-v1` 时，允许执行下面的 Fullstack Beta 流程。其他版本一律不可猜测接口。`data.data.enabled` 仍须独立检查。
- 静态 release 请求声明 `"kind": "static"`；旧客户端省略 kind 仍按静态处理。`fullstack` 必须携带 `backend_sha256` 并通过能力门禁；未知 kind 为参数错误。
- 能力未开放时，先说明限制，不生成假接口或用 localStorage 冒充共享数据。`data.data.enabled` 为 false 时仅支持无状态、所有者访问的 API；为 true 且 contract 为 `rivet-sql-v1` 时支持按网站隔离的持久 SQL，并允许有效分享码会话只读访问。写入始终要求站点所有者登录；不支持公开访客写入。用户要求未开放或超出范围的能力时必须说明具体限制，不能静默缩减需求。得到用户确认后才改做静态/无状态替代方案。
- 收到 `WEBSITE_BACKEND_UNAVAILABLE`：这是能力未开放，**不要重试**；不要删除 kind、改成 static 或降级上传原来的服务端代码。向用户说明后端能力当前不可用。

### Fullstack Beta：仅在 fetch-v1 能力门禁通过后执行

1. **先确认范围匹配。** 本版为 `fetch(Request, env, ctx) -> Response`。先独立检查数据能力：只有 `data.data.enabled === true` 且 `data.data.contract === "rivet-sql-v1"` 才有下面的持久 SQL；否则仍为无状态。JS 模块内存不保证保留。持久化后端写入须所有者登录；有效分享码会话可 GET/HEAD 读取同一网站的数据，不能写入。分享站点给别人时必须沿用平台分享码设置及链接，不能把所有者登录 Cookie、实例凭据或平台 Token 给别人。没有任意出网、定时任务、WebSocket、任意 Node 进程、文件系统或 Secret 绑定。需求不匹配时停止并解释，不静默降级。
2. 目录必须分离：`public/` 放静态文件，`backend/app.mjs` 放单个预打包 ES module。不要把后台源码、`.env`、私钥、平台凭据或后端 source map 放进 public。后端形态：

后端必须是单个 ESM 文件，默认导出含 `async fetch(request, env, ctx)` 方法的对象，返回标准 `Response`。
根据用户需求实现 `/api` 范围内的路由、HTTP 方法、输入校验和错误响应；未知路由返回 404，未知方法返回 405。
平台网关已在进入后端前校验登录、分享权限、真实 Origin 和发布版本。传入用户后端的 Request 仅保留 `Content-Type`、`Accept` 请求头；`X-Website-Release`、Authorization、Cookie、Origin 及内部控制头不会传入。后端不要因这些头缺失再次拒绝请求，也不要根据请求体中的身份字段替代平台鉴权；只处理业务路由、方法、输入和持久数据。前端仍须按下文发送发布版本头，分享访客的写入与 SQL 权限继续由平台拒绝。
不要预置固定业务示例，不依赖 Node.js 模块、实例文件系统或 JS 全局变量保存业务状态。

#### 持久 SQL：仅在 rivet-sql-v1 数据门禁通过时使用

- 使用 `await env.RIVET_STORAGE.sql.exec(sql, bindings)`，返回 `{ rows, columnNames, rowsRead, rowsWritten }`；使用参数绑定，不能拼接用户输入到 SQL。`await env.RIVET_STORAGE.sql.databaseSize()` 返回数据库字节数。
- 数据库绑定网站身份，而不是 release、浏览器或 JS 全局变量；同一网站的重新部署、回滚和运行时实例替换应保留数据。网站删除会终止其持久对象，不能重新创建旧身份。
- 数据请求失败时显示服务端返回的原因，不能用 localStorage 作兜底。
- 有效分享会话仅允许一个 SELECT 读取；不支持分享会话执行 DDL、INSERT、UPDATE、DELETE、WITH 或多语句。不要在 GET 内初始化数据库或写业务数据；在所有者写请求中初始化 schema。仅首次建站且业务表尚未创建时，GET 可返回空列表；存储超时、权限、配额或其他 SQL 错误必须明确报错，不得吞掉错误伪装成空数据。
- 按用户实际需求设计数据实体、字段、接口和页面，不复制预设业务应用。持久化代码写在 `backend/app.mjs`，只通过平台提供的 SQL 接口访问本站数据；不要预置与需求无关的表、路由或业务字段。
- 每个创建意图生成一次稳定的业务标识或幂等键；同一次意图重复提交时不得重复写入或更换标识。校验输入并使用参数绑定，以数据库约束和原子 SQL 保证一致性。写请求失败后先确认结果，不自动重放或偷偷新建记录。
- 重新部署的 schema 变更必须向后兼容，不删除已有业务数据；读请求不能承担迁移或初始化。代码回滚不等于数据 schema 回滚，旧版本必须仍能读取升级后的数据。
- 共享数据验收：用站点所有者登录会话执行需求规定的写入，再用第二个独立浏览器建立有效分享会话，刷新后核对同一条记录的业务标识和内容。重新部署、运行时恢复以及代码回滚后，继续通过页面和 API 验证原数据保留；分享访客写入必须拒绝。仅截图、自己刷新或浏览器 localStorage 不算验收。

3. `public/index.html` 在应用 JS 执行之前声明版本标记，deployer 只在私有校验成功后把完整引号包裹的标记值替换为本次 release ID，保留同名 JavaScript 变量。标记必须使用普通单引号或双引号，不能只声明同名变量而不赋值：

```html
<script>globalThis.__LIGHTVELA_RELEASE_ID__="__LIGHTVELA_RELEASE_ID__";</script>
```

所有前端 API 请求必须同源并带 `X-Website-Release`；不要在浏览器里加入平台 Authorization 或实例密钥。写请求由浏览器自动提供真实 Origin，不要通过伪造 Origin 绕过验证：

按实际需求确定 API 路径、HTTP 方法和请求数据；所有请求共用以下调用约束，不预置业务路由或字段：

- 请求路径限定为本站 `/api` 或 `/api/*`，不能指向外部地址。
- 使用 `credentials: "same-origin"`，并传入 `"X-Website-Release": globalThis.__LIGHTVELA_RELEASE_ID__`。
- 有 JSON 请求体时才添加 `Content-Type: application/json`，对实际业务数据执行 `JSON.stringify`；GET/HEAD 不发送请求体。
- 401：引导所有者完成站点登录后重新操作；不要自动重放写请求。
- 409：页面版本已过期，提示重新加载；不要用旧页面重试写操作。
- 429/502/503：显示暂时不可用，不把失败提示成已保存成功。


4. 使用当前 Profile 的 Skill 随附打包器。打包器不上传、不运行后端；输出仅包含可用于 CreateRelease 的非敏感元数据：

```bash
python3 "${HERMES_HOME:-$HOME/.hermes}/skills/website-builder/scripts/package_fullstack.py" \
  --static-dir ./public --backend ./backend/app.mjs \
  --output ./artifacts/site-v1.zip
```

脚本缺失时停止并说明 Skill 交付不完整，不自行改成静态 zip。产物布局为根目录静态文件与私有 `__backend/app.mjs`；deployer 不会把后者写入静态 COS 路径。不要覆盖历史 zip，保留上一成功 release ID 与制品以供回退。

5. 创建 release 时使用打包器原样输出的 `kind=fullstack`、`backend_sha256`、`artifact_hash`、`artifact_size`、`file_count`。沿用后文签名上传流程，`data.upload_headers` 逐项原样提交；不得输出 `upload_url`、`VELA_WEBSITE_KEY` 或包含凭据的原始响应。后端 API 位于同站点 `/api`、`/api/*`；其它路径仍为静态资源。
6. 轮询 operation 到真实 success，并核对站点和 release。后台未就绪、摘要错误、配额拒绝或发布失败时保持旧站，不能报告成功。不要把 operation 创建成功/HTTP 200 当成已经发布。
7. 在所有者已登录的真实浏览器验证：页面、GET/POST 结果、非所有者拒绝、错误输入、重新发布后旧页面 409、刷新后恢复。没有浏览器登录态时明确标记“尚未完成所有者浏览器验收”，不生成假 cookie、不以内部调用替代公网验证。
8. 回滚使用 `POST {API_BASE}/v1/websites/{siteId}/rollback`，正文 `{ "release_id": "<previous-successful-release>" }`，继续轮询返回的 operation。仅可回到仍保留的静态/后端版本；制品不在时会失败，应使用保留的旧 zip 重新发布，不能宣称回滚成功。回滚前后都核对实际页面和 API。停用后 API 必须拒绝访问。

**运行要求：** 后端执行和请求处理失败时，按服务端返回的具体原因处理。首版不转发应用 cookie、任意身份头或跨域头，不支持后端重定向。不要编写依赖这些能力的应用。

### 第二步：需求澄清（与用户交互）

用自然语言与用户确认：
- 网站类型（个人主页/产品展示/落地页/文档站/作品集/活动介绍页）
- 设计风格（简约/科技/活泼）
- 主要内容板块
- 语言（中文/英文/双语）

**在澄清阶段就要识别出“需要保存数据”的需求**，明确数据由谁写入、谁读取以及是否需要跨浏览器共享，
先查询「后端与数据能力检查」，判断能否按当前数据门禁和读写权限实现；
只有能力未开放或需求超出范围时，才说明限制并征求用户是否接受替代方案。
不要先答应下来、生成完了再解释。

如果用户描述比较模糊，主动追问 1-2 个关键问题，不要一次问太多。

### 第三步：生成静态产物

#### 3.1 先做设计决策（内部，写代码之前）

动手写 HTML 之前，先在内部明确三件事，各一句话：

1. **用途**：这个站服务什么场景、给谁看
2. **美学方向**：例如克制的编辑风、明快的消费品风、硬朗的工业风、复古印刷风
3. **配色与字体**：具体到主色、强调色、正文字体族

没有这一步，模型会滑向默认模板，所有用户拿到的站长得一模一样。

**禁用清单**（除非用户明确要求）：

- 紫色 / 靛蓝 / 品红渐变背景
- `Inter`、`Roboto`、`system-ui` 作为主字体
- 纯居中的单卡片布局
- 用 emoji 充当图标

替代做法：从用途出发选字体（衬线体适合内容站、几何无衬线适合产品站）；主色从品牌或主题联想取，用同色系深浅拉层次而不是彩色渐变；布局按内容量决定，长内容用左对齐分栏而非居中卡片；需要图标时用内联 SVG。

#### 3.2 再生成文件

按用户需求和项目结构生成 HTML/CSS/JS 及所需资源，然后打包发布。

发布结构：
- **首页必须是根目录下的 `index.html`**（不能放在子目录里，否则会被拒绝）
- 所有资源使用相对路径
- 本节仅描述静态流程：不使用后端代码、数据库连接或 API 密钥。需要后端或持久 SQL 且能力门禁通过时，改用前述 Fullstack Beta 流程；
  页面里不需要也不允许出现任何凭据

**多页面必须用 hash 路由（`#/about`）或真实的 `.html` 文件。**
禁止使用 History 模式路由（`/about` 这种）——平台按对象路径直接返回文件，
没有"找不到就回退到 index.html"的能力，用户在子路由刷新页面会 404。

可以放一个根目录下的 `404.html`，访问不存在的路径时会自动生效。

### 第四步：创建站点（内部）

创建站点记录，拿到 `site_id` 和创建操作 ID（响应中的 `data.operation_id`）。
这个操作 ID 只代表站点记录的创建过程，记为 `create_operation_id`；
**它不是部署操作 ID，不要用它判断网站是否发布成功。**

**幂等键**：创建请求可带 `idempotency_key`。同一用户 + 同一幂等键最多只会建出一个站点，
由服务端唯一索引保证。**同一次建站任务的重试必须复用同一个 key**，
否则网络超时后的重试会重复建站并重复占用席位。
建议取值：本次建站任务的稳定标识（例如会话 ID + 站点名的哈希），不要每次随机生成。
不传该字段则不做去重。

**请求：**

```
POST {API_BASE}/v1/websites
```

请求体（JSON，字段名使用 snake_case）：

```json
{
  "name": "我的个人主页",
  "idempotency_key": "session-abc-我的个人主页"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 站点名称，最长 100 字符 |
| idempotency_key | string | 否 | 幂等键，同用户+同键只建一个站点 |

**响应（HTTP 201）：**

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "site_id": "ws-a1b2c3d4e5f6",
    "operation_id": "wo-x1y2z3w4"
  },
  "request_id": "req-xxx"
}
```

`data.site_id` 是站点的唯一标识，后续发布、查询、删除都用它。
`data.operation_id` 是站点创建操作 ID，记为 `create_operation_id`，**不要用它轮询部署状态**。

### 第五步：创建发布并上传（内部）

将静态文件打包为 zip，计算 sha256 哈希值和文件大小，创建发布并从响应中获取
`data.release_id`、`data.upload_url`、`data.upload_headers`、`data.upload_method` 和发布操作 ID
（`data.operation_id`，记为
`deploy_operation_id`），然后按 `data.upload_method` 上传 zip 到 `data.upload_url`。

`data.upload_url`、`VELA_WEBSITE_KEY` 和原始响应都属于敏感的内部操作数据，
不得输出、打印或写入日志。只从响应解析所需字段，不保留完整响应。

**后续只轮询 `deploy_operation_id`。** 创建站点和创建发布会各返回一个
`operation_id`，混用会把旧创建操作的结果误判为部署结果。

#### 5.1 打包并计算哈希

```bash
# 打包为 zip（确保 index.html 在根目录）
cd /tmp/website-build && zip -r site.zip . -x '*.DS_Store'

# 计算 sha256（64 位小写十六进制）
ARTIFACT_HASH=$(sha256sum site.zip | cut -d' ' -f1)

# 文件大小（字节数）
ARTIFACT_SIZE=$(stat -c%s site.zip)   # Linux
# ARTIFACT_SIZE=$(stat -f%z site.zip)  # macOS

# 文件数
FILE_COUNT=$(python3 -c 'import zipfile; print(sum(not entry.is_dir() for entry in zipfile.ZipFile("site.zip").infolist()))')
```

#### 5.2 创建发布

**请求：**

```
POST {API_BASE}/v1/websites/{siteId}/releases
```

请求体（JSON，字段名使用 snake_case，**三个字段全部必填**）：

```json
{
  "kind": "static",
  "artifact_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "artifact_size": 45678,
  "file_count": 3
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| kind | string | 否 | 静态填写 static；省略兼容旧静态客户端；fetch-v1 能力通过时可填 fullstack |
| backend_sha256 | string | fullstack 必填 | 私有 app.mjs 的小写 SHA-256，静态发布不传 |
| artifact_hash | string | 是 | zip 文件的 sha256 哈希值，64 位小写十六进制 |
| artifact_size | int64 | 是 | zip 文件大小（字节数） |
| file_count | int | 是 | zip 内文件总数 |

**响应（HTTP 201）：**

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "release_id": "wr-a1b2c3d4",
    "operation_id": "wo-v9w8x7y6",
    "version": 1,
    "upload_url": "https://cos-bucket.cos.ap-shanghai.myqcloud.com/sites/ws-xxx/wr-xxx.zip?sign=xxx&expires=xxx",
    "upload_method": "PUT",
    "upload_headers": {
      "Content-Length": "45678",
      "x-cos-meta-artifact-sha256": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
    }
  },
  "request_id": "req-xxx"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| release_id | string | 发布 ID |
| operation_id | string | 发布操作 ID，记为 `deploy_operation_id`，用于轮询部署状态 |
| version | int | 发布版本号，从 1 递增 |
| upload_url | string | 文件上传地址，敏感数据，不得输出 |
| upload_method | string | 上传 HTTP 方法（通常为 `PUT`） |
| upload_headers | map<string,string> | 服务端签名的上传请求头，必须原样使用 |

#### 5.3 上传 zip 文件

使用 `data.upload_method`（通常为 `PUT`）向 `data.upload_url` 发送请求：

```bash
curl -X PUT \
  -H "Content-Length: ${ARTIFACT_SIZE}" \
  -H "x-cos-meta-artifact-sha256: ${ARTIFACT_HASH}" \
  -H "Content-Type: application/zip" \
  --data-binary @site.zip \
  "${UPLOAD_URL}"
```

上传注意：
- `data.upload_headers` 是服务端签名的上传契约，必须同时包含
  `Content-Length` 和 `x-cos-meta-artifact-sha256`
- 校验 `Content-Length` 等于本地 zip 的实际字节数，校验
  `x-cos-meta-artifact-sha256` 等于本地计算出的 64 位小写 sha256
- PUT 时把 `data.upload_headers` 中每一项逐项原样作为请求头发送，再加
  `Content-Type: application/zip`；不要自行推导、改名、规范化或丢弃服务端返回的值
- `data.upload_headers` 缺失、上述任一必需头缺失或出现未知头时，按协议异常立即停止发布；
  不要尝试上传，也不要重新创建站点或发布

**上传成功后 COS 返回 HTTP 200，响应体为空。** 非 200 状态码视为上传失败。

#### 5.4 轮询部署状态

使用第五步拿到的 `deploy_operation_id`（不是创建站点的 `create_operation_id`）轮询：

**请求：**

```
GET {API_BASE}/v1/websites/{siteId}/operations/{deploy_operation_id}
```

无请求体。

**响应 `data` 字段：**

```json
{
  "operation_id": "wo-v9w8x7y6",
  "status": "success",
  "error_message": ""
}
```

| status 值 | 含义 | 动作 |
|-----------|------|------|
| created | 操作已创建，等待执行 | 继续轮询 |
| running | 正在执行 | 继续轮询 |
| success | 执行成功 | 部署完成，告知用户站点地址 |
| failed | 执行失败 | 停止，查看 error_message 并告知用户 |
| dead | 超过最大重试次数，终止 | 停止，告知用户部署失败 |

**轮询间隔：每 3 秒一次。** 等待较久时简短告知用户仍在处理中，继续查询同一个 operation，直到终态；等待本身不算失败，不能据此新建站点或重复提交发布。

#### 5.5 上传时机

- **创建发布后要尽快上传**：拿到 `upload_url` 后立即 PUT；失败时读取服务端返回，不假定发布成功。
- 上传完成后不需要额外通知服务端，deployer 会自动检测文件并继续部署。

### 第六步：验证站点可访问（内部）

部署成功后，查询站点详情获取访问地址：

```
GET {API_BASE}/v1/websites/{siteId}
```

从响应 `data.PublicURL` 字段（PascalCase）取出站点地址。
**创建站点的响应不包含此字段**——创建只返回 `site_id` 和 `operation_id`。

**首次访问可能延迟 10 秒左右**（DNS / CDN 刷新）。如果首次访问返回 404，
等待 10 秒后重试一次。不要把首次 404 当作部署失败。

### 部署完成后向用户输出

只用一句自然语言告知用户站点地址，不要输出任何技术细节：

> ✅ 网站已上线！访问地址：https://ws-xxx.lightvela.site/

## 列出已有站点（内部）

**请求：**

```
GET {API_BASE}/v1/websites?page=1&page_size=20
```

**响应 `data` 字段：**

```json
{
  "sites": [
    {
      "SiteID": "ws-a1b2c3d4",
      "Name": "我的个人主页",
      "Status": "active",
      "PublicURL": "https://ws-xxx.lightvela.site/",
      "CloudPath": "sites/ws-xxx/",
      "StorageBytes": 45678
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20
}
```

**注意：`sites` 数组中的站点对象字段名为 PascalCase**（Go 默认序列化），与请求体和显式结果结构体的 snake_case 不同。主要字段：`SiteID`、`Name`、`Status`、`PublicURL`、`CloudPath`、`StorageBytes`。

## 查询站点详情（内部）

```
GET {API_BASE}/v1/websites/{siteId}
```

**响应 `data` 字段**（PascalCase，同上）：

```json
{
  "SiteID": "ws-a1b2c3d4",
  "Name": "我的个人主页",
  "Status": "active",
  "PublicURL": "https://ws-xxx.lightvela.site/",
  "CloudPath": "sites/ws-xxx/",
  "StorageBytes": 45678
}
```

站点 `Status` 可能的值：`active`（正常）、`suspended`（暂停，套餐过期）、`deleting`（删除中）。

## 列出发布历史（内部）

```
GET {API_BASE}/v1/websites/{siteId}/releases?page=1&page_size=10
```

**响应 `data` 字段：**

```json
{
  "releases": [
    {
      "ReleaseID": "wr-a1b2c3d4",
      "SiteID": "ws-xxx",
      "Version": 1,
      "Status": "active",
      "ArtifactHash": "a1b2...",
      "ArtifactSize": 45678,
      "FileCount": 3
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 10
}
```

**注意：`releases` 数组中的字段名同样是 PascalCase。**

## 删除网站流程

用户要求删除网站时，调用删除接口，然后确认删除成功。

**请求：**

```
DELETE {API_BASE}/v1/websites/{siteId}
```

无请求体。

**响应（HTTP 200）：**

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "operation_id": "wo-d1e2f3g4"
  },
  "request_id": "req-xxx"
}
```

`data.operation_id` 是删除操作 ID。按上面的同一套状态契约轮询：
`created` / `running` 继续，`success` 完成，`failed` / `dead` 停止并报告失败；
超时只表示删除仍在处理中，不要再次调用删除接口，也不要声称已经删除。

删除会清除站点的全部静态文件，不可恢复。页面内容重要时提醒用户先自行留一份。

**输出示例：**

> 🗑️ 网站已删除，相关资源已清理。

## 错误处理（翻译为用户语言）

错误响应的 HTTP 状态码为 4xx 或 5xx，响应体中的 `code` 字段为错误码字符串：

```json
{
  "code": "WEBSITE_QUOTA_EXCEEDED",
  "message": "quota exceeded",
  "data": null,
  "request_id": "req-xxx"
}
```

| 内部错误码 | 对用户说的话 |
|------------|-------------|
| WEBSITE_QUOTA_EXCEEDED | 根据服务端返回的具体原因说明当前无法发布 |
| WEBSITE_ARTIFACT_TOO_LARGE | 根据服务端返回的 message 和 details 说明原因及可行的调整 |
| WEBSITE_FILE_COUNT_EXCEEDED | 根据服务端返回的 message 和 details 说明原因及可行的调整 |
| WEBSITE_PASS_INACTIVE | 你的套餐已过期，续费后可以继续使用 |
| WEBSITE_NO_QUOTA | 你当前的套餐不包含建站功能，升级套餐即可使用 |
| WEBSITE_NOT_ACTIVE | 这个网站当前不可用，可能已暂停或正在删除 |
| WEBSITE_NOT_FOUND | 没有找到这个网站，可能已经被删除了 |
| WEBSITE_BACKEND_UNAVAILABLE | 当前还不能发布带后端的网站，可以先做纯静态版本 |
| WEBSITE_INVALID_PARAM | 网站配置有点问题，我调整一下重试 |

**WEBSITE_INVALID_PARAM 特别说明**：服务端会在响应顶层 `details.reason` 附上具体原因，
例如 `"name is required"`、`"artifact_hash is required"` 等。遇到此错误时检查请求体
是否缺少必填字段或字段名拼写错误（字段名必须是 snake_case），修正后重试。

### 重试上限（必须遵守）

- **任何情况下都不要为了重试而新建站点。** 重新发布用现有 site_id，保留原站点地址。
- **首次访问 404 不算失败**，先按上文等 10 秒再自检，不要触发重试。
- 同一个站点**发布失败 2 次后停止重试**，转为告诉用户具体原因并给出可执行的建议
  不要继续自动重发。不变的失败制品不要盲重试，也不要擅自删减用户内容。
- 同一个原因连续出现 3 次，停止逐个打补丁，直接向用户说明根因。

## 能力边界

### 按实际能力区分，不做一概否定

| 实际门禁 | 可做的范围 |
|---|---|
| 后端未开放 | 静态展示；不能生成假后端接口 |
| 仅 `fetch-v1` 后端开放 | 所有者访问的计算与校验 API；不能保存共享数据 |
| 后端与 `rivet-sql-v1` 数据都开放 | 按网站隔离的持久数据；所有者维护数据，持有效分享码的访客只读同一份数据 |

后端与持久数据都开放时，**所有者写入后，另一独立浏览器通过有效分享会话刷新读到同一份服务端数据**，才是共享数据验收；同一浏览器刷新不是这个验收的替代品。重新部署同一站点不能清空数据。

### 当前仍不能做的功能

- 未登录所有者的访客写入：公开留言、访客报名、公开投票或购物车写入等。
- 自建用户注册、登录、个人中心或多用户权限体系；平台所有者登录不是自建账号系统。
- 在线支付、库存交易等未提供的业务能力。
- 任意外部数据库连接、文件系统、任意出网、定时任务和 WebSocket。

需求涉及以上能力时，解释具体限制，并让用户明确选择可行的替代方案；不要把“所有者可写、分享访客只读”说成所有访客都可写。

**⛔ 禁止用 localStorage / sessionStorage / IndexedDB / cookie 冒充服务端共享数据。**
这些存储是各设备、各浏览器自己的数据，不能证明分享者看到同一份记录，也不能证明重部署后服务端数据保留。门禁不开放时不可偷偷退回浏览器存储来声称已经实现；单机应用须先明确数据仅在本设备、清缓存会丢失，并取得用户确认。

| 不匹配的需求 | 经用户确认后可提供的替代 |
|---|---|
| 公开留言 / 评论区 | 展示页加邮箱等联系方式 |
| 访客报名 / 问卷 / 预约 | 链接到受信任的第三方表单 |
| 在线支付 / 下单 | 商品展示和询价联系方式 |
| 自建账号体系 | 无自建账号的内容页 |
| 需要共享持久数据但数据门禁未开放 | 说明共享数据暂不可用，不默认为单机版 |

**不要替用户假装做到了。** 必须以实际能力和跨浏览器、重新部署验收为准。

## 注意事项

- 用户不需要也不应该接触任何云厂商密钥、环境标识或底层资源标识
- 站点访问地址由平台发布后返回，且**在站点生命周期内固定不变**；只使用接口返回值，不要自行拼接
- 站点 ID 为随机生成，不可被枚举
- **套餐到期后站点会真正下线**（访问地址不可用），网站内容被保留；续费后平台自动恢复，地址不变。
  用户问"过期了网站还在吗"时可以回答"内容会保留，续费后自动恢复访问"
- 套餐到期或销毁后站点会下线，但网站内容会保留；重新获得有效套餐后可以恢复访问
- 建站服务是否接受本次发布，以服务端实际返回为准。异步发布失败时读取 operation 的 `error_message`，说明原因并保留旧站。
- 所有技术过程（API 调用、文件上传、状态轮询）对用户透明，AI 用"正在部署…"等自然语言描述进度即可
- 部署过程中不要输出代码块、脚本内容或工具日志给用户
- **字段名大小写**：请求体（JSON）使用 snake_case（如 `artifact_hash`、`artifact_size`、`file_count`、`idempotency_key`）；响应中显式结果结构体也使用 snake_case（如 `site_id`、`operation_id`、`upload_url`）；但站点和发布实体对象使用 PascalCase（如 `SiteID`、`Name`、`Status`、`PublicURL`、`ReleaseID`、`Version`）。调用时注意区分，不要混用。
