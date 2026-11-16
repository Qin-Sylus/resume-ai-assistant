# AI 可读项目说明 · 职达助手（resume-ai-assistant）

> 这份文档不是项目介绍，是**操作规程**：告诉接手的人（或 AI）这个项目由哪些模块组成、接口怎么约定、一个改动要动哪几个文件、改完怎么验证。
>
> **事实基准**：`main` 分支提交 `7c7ed6e`，按当时源码逐条核对。本文不写绝对行号（行号会随改动漂移），只写**类名 + 方法名 + 代码片段**，可用搜索直接定位。
>
> **维护纪律**：改动代码后必须回改本文对应条目，两者不一致时**以代码为准**，并立刻修正本文。

---

## 1. 一分钟速览

| 项 | 值 |
| --- | --- |
| 项目形态 | 前后端分离：Spring Boot 后端 + Vue 3 前端，同一仓库两个目录 |
| 后端目录 | `spring-ai/spring-ai/`（注意：两层同名，Maven 工程在第二层） |
| 前端目录 | `vue-springAi/` |
| 后端端口 | `9090`（`application.yml` 的 `server.port`） |
| 前端开发端口 | Vite 默认 `5173`，与后端 CORS 白名单一致 |
| WebSocket 路径 | `/ws/chat`（`WebSocketConfig` 注册） |
| 数据库 | MySQL，库名 `springai`，5 张表 |
| 后端规模 | 6 个 Controller / 5 个 Mapper / 6 个 Service(+6 个 Impl) / 6 个 model / 2 个 dto |
| 接口总数 | 18 个 HTTP 端点 + 1 个 WebSocket 端点 |
| 前端规模 | 8 个页面（`src/views`）+ 1 个验证码组件 + 1 个顶栏组件 |

**先看的三个文件**：`controller/ChatController.java`（AI 生成简历主流程）、`controller/RecommendController.java`（职位推荐主流程，27KB 最大的一个）、`service/impl/JobRecommendServiceImpl.java`（加权匹配算法）。

---

## 2. 技术栈与版本（以 pom.xml / package.json 为准）

### 后端 `spring-ai/spring-ai/pom.xml`

| 项 | 值 | 说明 |
| --- | --- | --- |
| Spring Boot | `3.4.0` | `spring-boot-starter-parent` 版本 |
| Java | `17` | `<java.version>`，**低于 17 编译会报「不支持发行版本 17」** |
| Spring AI | `1.0.0-M4` | `spring-ai-bom` 管理的版本；`OpenAiChatModel.call(String)` 返回 `String`、`stream(String)` 返回 `Flux<String>`，即此版本的 API 形态 |
| ORM | MyBatis-Plus（`mybatis-plus-spring-boot3-starter`） | `BaseMapper` + `@Select` 注解 SQL |
| Web | `spring-boot-starter-web` + `spring-boot-starter-webflux` | webflux 用于 `Flux` 流式 |
| WebSocket | `spring-boot-starter-websocket` | 原生 `WebSocketConfigurer` |
| 邮件 | `spring-boot-starter-mail` | `SendEmail` 服务，`application.yml` 的 host/username 为空，**默认不可用** |

### 前端 `vue-springAi/package.json`

| 项 | 值 |
| --- | --- |
| Vue | `^3.5.12` |
| Vite | `^5.4.10`（脚本：`dev` / `build` / `preview`，无 lint、无 test） |
| Element Plus | `^2.8.8` |
| vue-router | `^4.4.5`（`createWebHistory`） |
| axios | `^1.7.7` |
| 简历导出 | `docx@9.3.0`（Word）+ `html2pdf.js`（PDF）+ `file-saver`（保存文件） |

---

## 3. 目录与分层

```
基于SpringBoot+Vue+AI大模型的简历生成+职业推荐系统/
├── springai.sql                     # 建库建表脚本（5 张表）
├── spring-ai/spring-ai/             # 后端 Maven 工程
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/example/springai/
│       │   ├── SpringAiApplication.java      # 启动类
│       │   ├── controller/   (6)             # HTTP 入口，只做参数提取与 try/catch
│       │   ├── service/      (6 接口)        # 业务语义
│       │   ├── service/impl/ (6 实现)        # 真实逻辑都在这里
│       │   ├── mapper/       (5)             # BaseMapper + 少量 @Select
│       │   ├── model/        (6)             # 与数据库表一一对应
│       │   ├── dto/          (2)             # EmailDTO、JobRecommendRequest
│       │   ├── websocket/    (3)             # WS 配置 / 处理器 / 流式模型封装
│       │   └── config/       (2)             # CORS 配置、UUID 生成器
│       └── resources/
│           ├── application.yml               # 本地真实配置（已被 .gitignore 排除）
│           └── application-example.yml       # 占位符模板（进仓库，供克隆者复制）
└── vue-springAi/                    # 前端
    ├── package.json
    └── src/
        ├── main.js                           # axios.defaults.baseURL = http://localhost:9090
        ├── App.vue
        ├── router/index.js                   # 路由表（9 条 path，含 1 条重定向）
        ├── router/history.js                 # ⚠ 未被引用，且路径写错（见 §8-4）
        ├── utils/axios-config.js             # 另一个 axios 实例，baseURL 同 9090
        ├── utils/SidentifyView.vue           # 图形验证码组件
        ├── components/r-header.vue           # 顶栏 + 「生成简历」调用 /ai/chat
        └── views/ (8)                        # 见 §4 前端模块表
```

**分层约定**（改代码时不要跨层）：Controller 只负责取参数、包 `try/catch`、拼返回体；业务判断在 `service/impl`；SQL 优先用 MyBatis-Plus 的 `BaseMapper`，复杂联表才写 `@Select`。

---

## 4. 模块清单

### 4.1 后端 Controller（6 个）

| 类 | 类级映射 | 职责 |
| --- | --- | --- |
| `UserController` | `/user` | 注册、登录 |
| `JobController` | `/api/job` | 职位分类与职位的增删改查 |
| `JobRecommendController` | `/api/job-recommend` | 基于 DTO 的加权推荐（**当前前端未调用**） |
| `RecommendController` | `/api/recommend` | 基于简历的推荐 + AI 理由 + 职业建议（**前端推荐页用的是这个**） |
| `HistoryController` | `/api/history` | 对话历史分页与详情 |
| `ChatController` | `/ai` | AI 生成简历、简历读取/更新 |

### 4.2 后端 Mapper（5 个）

| 类 | 表 | 有无自定义 SQL |
| --- | --- | --- |
| `UserMapper` | `user` | 无，纯 `BaseMapper` |
| `ResumeMapper` | `resume` | 无 |
| `HistoryMapper` | `history` | 无 |
| `JobCategoryMapper` | `job_category` | 无 |
| `JobPositionMapper` | `job_position` | **有**：`findJobs` 用 `@Select` 写 `<script>` 动态 SQL，联 `job_category` 取 `category_name` |

`findJobs` 的筛选条件是**并列可叠加**的：`keyword` 同时模糊匹配 `title`/`description`/`company_name`/`location` 四个字段；`categoryId` 精确匹配 `category_id`；排序固定 `create_time DESC`。

### 4.3 后端 Service（6 接口 + 6 实现）

| 接口 | 实现 | 关键行为 |
| --- | --- | --- |
| `UserService` | `UserServiceImpl` | `addUser` 用 `username OR email` 查重；`login` **按 email 查**，密码**明文 equals 比较** |
| `JobService` | `JobServiceImpl` | 分类删除前检查该分类下职位数，非 0 抛 `"该分类下还有职位，无法删除"` |
| `JobRecommendService` | `JobRecommendServiceImpl` | 加权匹配算法（见 §4.4） |
| `ResumeService` | `ResumeServiceImpl` | 简历的 5 个复杂字段序列化为 JSON 字符串入库；`updateResume` 找不到旧记录时**降级为新增** |
| `HistoryService` | `HistoryServiceImpl` | 历史分页、按 id 查详情 |
| `SendEmail` | `SendEmailImpl` | 邮件发送，当前配置缺失，视为不可用 |

### 4.4 推荐算法：两套，别搞混

**A. `RecommendController`（前端 `/recommend` 页实际使用的）**

1. 入参只有 `userId`；用 `resumeService.getLatestResume(userId)` 取最新简历。
2. 从简历 JSON 里抽 `skills`（逗号切分）、`educationLevel`、`experience`（整数年）、`location`。
3. 用 `LambdaQueryWrapper` 对 `job_position` 做 **LIKE 粗筛**：每个技能 `like(required_skills)` 用 `OR` 连接；命中为空时放宽（只取第一个技能）；仍为空时兜底取全表前 9 条。
4. 粗筛后再算分，`calculateMatchScore` 是**整数分制**：

   | 项 | 加分 |
   | --- | --- |
   | 每个技能命中 `required_skills`（子串包含） | +10 |
   | 学历命中 `required_skills` 子串 | +15 |
   | 经验命中（匹配 `"{n} 年"` / `"{n}+ 年"` / `"低于 {n+1} 年"` 文案） | +20 |
   | `job.getLocation()` 非空 | +15（**无条件加分，这是个 bug，见 §8-2**） |

5. 降序排序，截断 **前 10**；
6. 只对**前 3** 调大模型：`generateRecommendationReason`（≤100 字理由）+ `generateResumeImprovementSuggestion`（简历优化建议）；
7. 最后 `generateCareerAdvice` 生成职业建议；
8. 返回 `{ "jobs": [...], "career_advice": {...} }`；若库中无职位，返回 `{"message": "数据库中没有职位数据，请先添加职位信息"}`。

**B. `JobRecommendServiceImpl`（`/api/job-recommend` 用的，前端未接）**

1. 入参 `JobRecommendRequest`（`skills[]` / `educationLevel` / `experienceYears` / `preferredLocation` / `resumeText`）。`skills` 为空但有 `resumeText` 时，用内置 ~60 个关键词做 `contains` 提取。
2. 全表 `selectList(null)` 逐条算分，**小数分制**：
   - 技能匹配：`required_skills` 按 `,|，|\s+` 切分并转小写，与用户技能做**双向子串匹配**（`jobSkill.contains(user) || user.contains(jobSkill)`），分数 = 命中数 / 用户技能数（0~1）。
   - 学历：等级表 `不限 0 / 高中 1 / 大专 2 / 本科 3 / 硕士 4 / 博士 5`，`userLevel >= jobLevel` 才 **+0.2**。
   - 经验：`Integer.parseInt` 解析，达标 **+0.2**、差一年 **+0.1**、非纯数字 → `NumberFormatException` → 0。
   - 地点：`job.getLocation().contains(preferredLocation)` **+0.1**。
3. 降序取 **前 5**；对每条调 AI 生成理由（失败兜底文案 `"这个职位与您的技能和经验非常匹配，值得考虑。"`）。
4. 返回 `{ "recommendations": [ { "job": {...}, "reason": "...", "matchScore": 0.x } ] }`。

> 两套算法结论：**前端展示走 A（整数分、前 10、带简历优化建议）**；B 是一套更"算法化"的实现但因前端未接，实际只作为接口存在的储备。

### 4.5 前端页面（8 个 views）

| 文件 | 路由 | 职责 | 调用的后端接口 |
| --- | --- | --- | --- |
| `Login.vue` | `/login` | 登录表单 + 图形验证码 | `POST user/login`（失败提示 400） |
| `Register.vue` | `/register` | 注册表单 | `POST user/add` |
| `indexView.vue` | `/index` | 布局壳：顶栏 + `router-view` | 无 |
| `wsChatView.vue` | `/wsChatView` | WebSocket 流式对话 + 历史侧栏 | `ws://localhost:9090/ws/chat`、`GET /api/history/list`、`GET /api/history/detail/{id}` |
| `HistoryView.vue` | `/history` | 历史记录分页表 | `GET /api/history/getHistory` |
| `Resume.vue` | `/resume` | 简历编辑 / 预览 / 导出 Word·PDF | `ws://localhost:9090/ws/chat`、`GET /ai/resume/latest`、`POST /ai/resume/update` |
| `jobPool.vue` | `/jobPool` | 职位池：列表、搜索、新增/编辑/删除、分类管理 | `GET api/job/categories`、`GET api/job/list`、`POST api/job/{add|update}`、`DELETE api/job/delete/{id}`、`POST api/job/category/add` |
| `recommend.vue` | `/recommend` | 职位推荐结果页 | `POST http://localhost:9090/api/recommend/jobs` |

**同一仓库里并存 3 种接口地址写法**（改地址时必须全改，否则局部 404）：

1. `src/main.js` → `axios.defaults.baseURL = 'http://localhost:9090'`（供 `import axios from 'axios'` 的页面：HistoryView、wsChatView、recommend 的 axios 部分）
2. `src/utils/axios-config.js` → `baseURL: 'http://localhost:9090/'`（供 Login、Register、jobPool）
3. **页面里写死全地址**：`r-header.vue`（`fetch('http://localhost:9090/ai/chat')`）、`Resume.vue`（`/ai/resume/latest`、`/ai/resume/update`）、`recommend.vue`（`/api/recommend/jobs`）

---

## 5. 数据模型（`springai.sql`，5 张表）

| 表 | 主键 | 关键字段 | 注意 |
| --- | --- | --- | --- |
| `user` | **无 PRIMARY KEY** | `id varchar(32)`、`username`、`password`、`email`、`phone` | `id` 由 `config/uuid` 生成 32 位串；密码明文；登录按 `email` 查 |
| `history` | **无 PRIMARY KEY** | `id varchar(32)`、`question text`、`result text`、`username`、`user_id varchar(32)`、`time timestamp` | 两条写入路径：HTTP `/ai/chat` 与 WebSocket 流结束后 |
| `resume` | `id bigint AUTO_INCREMENT` | `user_id`、`name`、`phone`、`email`、`job_status`、`job_title`、`salary_expectation`、`education`/`profession`/`work`/`project`/`award`（**均为 TEXT，存 JSON 字符串**）、`update_time` | 索引 `idx_user_id`、`idx_update_time`；"最新简历"= 按 `update_time` 倒序 LIMIT 1 |
| `job_category` | `id int AUTO_INCREMENT` | `name`、`description`、`create_time` | 被 `job_position` 外键引用 |
| `job_position` | `id bigint AUTO_INCREMENT` | `category_id`（外键 `fk_job_category`）、`title`、`description`、`required_skills`、`experience_requirement`、`education_requirement`、`salary_range`、`company_name`、`location`、`status tinyint default 1`、`create_time`、`update_time` | `required_skills` 是**自由文本**（逗号/空格分隔），不是结构化关联表——这是两套算法都靠"字符串包含"匹配的根本原因 |

> `resume` 的 5 个 TEXT 字段是"表里是字符串、内存里是 Map"的转换点：写入在 `ResumeServiceImpl.updateResumeFields`（`objectMapper.writeValueAsString`），读出在 `ChatController.convertResumeToMap`（`objectMapper.readValue`）。**动简历结构一定要两侧同时改**。

---

## 6. 接口约定（18 个端点）

> ⚠ 本项目**没有统一的返回包装**，四类风格并存。写前端或用 AI 改接口时，先确认在哪个 Controller。

### 风格一：`{success, data}` / `{success, error}`（`/api/job/*`）

| 方法 | 路径 | 入参 | 返回 |
| --- | --- | --- | --- |
| GET | `/api/job/categories` | — | `{success:true, data:[JobCategory]}` |
| GET | `/api/job/list` | query：`page`(默认1)、`size`(默认10)、`keyword`(可选)、`categoryId`(可选) | `{success:true, data:{list:[JobPosition], total:N}}` |
| GET | `/api/job/detail/{id}` | path：Long id | `{success:true, data:JobPosition}`，`categoryName` 由 Service 手动回填 |
| POST | `/api/job/add` | body：JobPosition | `{success, data}` |
| POST | `/api/job/update` | body：JobPosition（须带 id） | `{success, data}` |
| DELETE | `/api/job/delete/{id}` | path：Long | `{success}` |
| POST | `/api/job/category/add` | body：JobCategory | `{success:true, data}`（注意：这里**恒为 true**，不反映插入结果） |
| DELETE | `/api/job/category/delete/{id}` | path：Integer | 分类下有职位时 `{success:false, error:"该分类下还有职位，无法删除"}` |

### 风格二：原生返回（`/user/*`）

| 方法 | 路径 | 入参 | 返回 |
| --- | --- | --- | --- |
| POST | `/user/add` | body：`{username, email, password, phone}` | **纯文本** `"新增用户成功！"` 或 `"用户已存在"`（不是 JSON） |
| POST | `/user/login` | body：`{email, password}` | 成功 `200` + `User` JSON（**含 password 明文**）；失败 `400` + **空 body** |

> 前端 `Login.vue` 对 400 的判定要基于 `status`，不能靠 body 判断——body 是空的。

### 风格三：Map / 对象直出（`/api/history/*`）

| 方法 | 路径 | 入参 | 返回 |
| --- | --- | --- | --- |
| GET | `/api/history/getHistory` | query：`userId`(必填)、`pageNum`(默认1)、`pageSize`(默认10) | `{records:[History], total, current, size}` |
| GET | `/api/history/list` | 同 `getHistory` | 同上（**方法名不同的别名，实现直接复用**） |
| GET | `/api/history/detail/{historyId}` | path：String | `History` 对象；查不到返回 `404` 空 body |

### 风格四：业务对象 + error 分支（`/api/recommend`、`/ai`）

| 方法 | 路径 | 入参 | 返回 |
| --- | --- | --- | --- |
| POST | `/api/recommend/jobs` | body：`{userId}` | `{jobs:[...], career_advice:{...}}`；`userId` 空 → `400 {error}`；无简历 → `404 {error:"未找到用户简历信息，请先完善简历"}`；简历无技能 → `400 {error}` |
| POST | `/api/job-recommend/recommend` | body：`JobRecommendRequest` | `{recommendations:[{job, reason, matchScore}]}` |
| POST | `/ai/chat` | body：`{userId, username, resumeVersion, formData}`；`formData` 应届生版用 `major/position/extra`，其他版用 `experience/position/extra` | `{success:true, content:{...8 个简历字段...}}`；AI 解析失败 → `{success:false, error:"AI响应解析失败: ..."}` |
| GET | `/ai/resume/latest` | query：`userId` | `{success, content}`；无简历 → `{success:false, error:"No resume found"}` |
| POST | `/ai/resume/update` | body：`{userId, resumeData}` | `{success, content}` |

### WebSocket `/ws/chat`

- 注册方式：`WebSocketConfig.registerWebSocketHandlers` 里 `registry.addHandler(new ChatWebSocketHandler(...), "/ws/chat").setAllowedOrigins("*")`。
- 客户端**发送文本**：`ChatRequest` 的 JSON，字段 `text`（问题）、`userId`、`username`。
- 服务端**逐块下发**：`"data:" + chunk + "\n\n"`，流结束追加 `"data:[DONE]\n\n"`（SSE 风格，但走 WS 通道）。
- 流结束后把完整问答写入 `history` 表（`id` 用 `UUID.randomUUID().toString().replaceAll("-", "")`）。

### `/ai/chat` 的 AI 输出契约（最容易改坏的地方）

`buildResumePrompt` 要求模型**严格返回固定 JSON**，随后 `validateResumeData` 校验：

- 顶层 8 个必填字段：`jobStatus`、`jobTitle`、`salaryExpectation`、`education`、`profession`、`work`、`project`、`award`
- 嵌套必填：`education{school,major,degree}`、`profession{skill}`、`work{company,department,position,details}`、`project{name,details}`、`award{details}`

改 prompt 里任何一个字段名，必须同步改 `validateNestedObject` 的校验数组和 `convertResumeToMap` 的读取键，否则会一路报"缺少必要字段"。

---

## 7. 调用示例（Windows PowerShell，可直接粘贴执行）

> 前提：MySQL 已导入 `springai.sql`，后端已启动在 9090。

```powershell
# 0. 探活：能否连上后端
try { Invoke-RestMethod -Uri "http://localhost:9090/api/job/categories" -TimeoutSec 10 } catch { "后端未启动或接口异常" }

# 1. 登录（用邮箱，不是用户名）
$body = @{ email = "demo@zhida.com"; password = "123456" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:9090/user/login" -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8"

# 2. 职位分页（带关键词 + 分类）
Invoke-RestMethod -Uri "http://localhost:9090/api/job/list?page=1&size=5&keyword=Java" -TimeoutSec 10

# 3. 职位详情
Invoke-RestMethod -Uri "http://localhost:9090/api/job/detail/1" -TimeoutSec 10

# 4. 基于简历的推荐（需要该 userId 已有简历记录）
$body = @{ userId = "把登录返回的 id 填这里" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:9090/api/recommend/jobs" -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json; charset=utf-8" -TimeoutSec 60

# 5. 历史分页
Invoke-RestMethod -Uri "http://localhost:9090/api/history/getHistory?userId=你的id&pageNum=1&pageSize=10" -TimeoutSec 10
```

> PowerShell 注意两点：① 中文 JSON 必须用 `[Text.Encoding]::UTF8.GetBytes()` 转字节再发，直接传字符串会乱码；② `Invoke-RestMethod` 在非交互环境要加 `-UseBasicParsing`（若报"朗读和提示功能不可用"）。

**WebSocket 手测**（浏览器控制台，先打开前端任意页面）：

```javascript
const ws = new WebSocket('ws://localhost:9090/ws/chat');
ws.onmessage = e => console.log(e.data);
ws.onopen = () => ws.send(JSON.stringify({ text: '你好，介绍一下你自己', userId: '你的id', username: '测试' }));
// 看到逐块 "data:..." 后，最后一条应为 data:[DONE]
```

---

## 8. 改动位置索引（改一个需求要动哪几个文件）

> 这一节是本文最核心的部分。每条都给出**完整改动面**和**验证方式**；只改一半就会出"点了没反应"或"数据不显示"。

### 8-1 新增一个业务接口

1. `controller/XxxController.java`：加 `@GetMapping/@PostMapping`，方法内 `try/catch`，异常时把 `e.getMessage()` 放进返回体（本项目惯例）。
2. `service/XxxService.java` + `service/impl/XxxServiceImpl.java`：业务逻辑。
3. `mapper/XxxMapper.java`：纯 CRUD 用 `BaseMapper`，联表才写 `@Select`。
4. 前端在 `src/views/` 对应页面调用；若跨域报错，检查 `config/WebConfig` 的 `allowedOrigins`（当前**只允许** `http://localhost:5173`）。
5. 验证：`Invoke-RestMethod` 直连新接口，看返回体是否符合预期风格。

### 8-2 调整推荐算法的权重（当前有已知 bug）

- 文件：`service/impl/JobRecommendServiceImpl.java`
  - 学历权重：`calculateEducationMatch` 返回值 `0.2`
  - 经验权重：`calculateExperienceMatch` 的 `0.2`（达标）/ `0.1`（差一年）
  - 地点权重：`contentBasedRecommendation` 里的 `score += 0.1`
  - 学历等级表：`calculateEducationMatch` 内的 `educationLevels` map
- 同一需求的另一端：`controller/RecommendController.java` 的 `calculateMatchScore`（整数分制 10/15/20/15）。**两处权重口径不同，别只改一处就宣称"调整了推荐算法"。**
- 已知 bug：`RecommendController.calculateMatchScore` 里 `if (jobLocation != null && !jobLocation.isEmpty()) score += 15;` —— 只判断职位有没有地点，**没有和用户期望地点比较**，等于所有有地点的职位都白拿 15 分。修法：把用户 `location` 传进该方法做 `contains` 比较。
- 验证：同一份简历（同一 `userId`）改前改后各调一次 `/api/recommend/jobs`，对比 `jobs[i].matchScore` 序列是否变化；再看排序是否随之改变。

### 8-3 给简历增加一个字段（7 处，缺一不可）

| # | 文件 | 要改什么 |
| --- | --- | --- |
| 1 | `springai.sql` | `resume` 表加列（简单字段加 `varchar`，结构化字段加 `TEXT`） |
| 2 | `model/Resume.java` | 加对应属性（MyBatis-Plus 自动映射下划线→驼峰） |
| 3 | `service/impl/ResumeServiceImpl.updateResumeFields` | 简单字段直接 `set`；结构化字段 `objectMapper.writeValueAsString` |
| 4 | `controller/ChatController.buildResumePrompt` | 在要求模型返回的 JSON 模板里加字段 |
| 5 | `controller/ChatController.validateResumeData`（及其嵌套校验数组） | 加必填校验，否则字段缺失不会被发现 |
| 6 | `controller/ChatController.convertResumeToMap` | 读出时把它放进返回 Map |
| 7 | `vue-springAi/src/views/Resume.vue` | 表单控件 + 提交 `resumeData` 时带上该字段 |

验证：调 `/ai/chat` 生成一次简历 → 查库里 `resume` 新列是否有值 → 调 `/ai/resume/latest` 看返回 `content` 是否含新字段 → 前端 `/resume` 页能否显示并导出。

### 8-4 修 `src/router/history.js`（当前是死代码 + 路径错误）

- 该文件 `getHistoryList` 请求 `'history/getHistory'`，缺 `/api` 前缀，若被启用必然 404；且**全项目没有任何文件 import 它**（历史页 `HistoryView.vue` 自己用 `axios.get("/api/history/getHistory")`）。
- 处置建议：要么删掉，要么改成 `'/api/history/getHistory'` 并让 `HistoryView.vue` 改用它，避免两份实现漂移。

### 8-5 新增前端页面

1. `src/views/Xxx.vue`（页面组件）。
2. `src/router/index.js` 加路由；若要在顶栏下作为子页面，挂到 `/index` 的 `children` 里。
3. `src/components/r-header.vue` 加入口（菜单项 / 按钮）。
4. 调接口时**优先沿用现有地址来源**（`axios-config` 或 `main.js` 的 default），不要再写死 `http://localhost:9090`。
5. 验证：`npm run dev` 后访问新路由；F12 确认无 404、无 CORS 报错。

### 8-6 给职位列表加筛选条件

1. `mapper/JobPositionMapper.findJobs`：`<script>` 里加 `<if>` 条件（**注意 XML 中 `<` 要写成 `&lt;`**）。
2. `controller/JobController.getJobList`：加 `@RequestParam`。
3. `service/JobService` + `JobServiceImpl.getJobList`：签名同步加参数。
4. `vue-springAi/src/views/jobPool.vue`：查询参数对象加字段、加控件。
5. 验证：`GET /api/job/list?...&新参数=x` 返回 `data.total` 变化；不带该参数时结果与改前一致（防回归）。

### 8-7 改后端服务地址（端口/域名变了）

必须全改：**2 份后端配置 + 6 个前端文件**。

| 文件 | 位置 |
| --- | --- |
| `spring-ai/.../resources/application.yml` | `server.port`（本地配置，不进仓库） |
| `spring-ai/.../resources/application-example.yml` | 同上（进仓库，供他人复制） |
| `vue-springAi/src/main.js` | `axios.defaults.baseURL` |
| `vue-springAi/src/utils/axios-config.js` | `baseURL` |
| `vue-springAi/src/components/r-header.vue` | `fetch('http://localhost:9090/ai/chat')` |
| `vue-springAi/src/views/Resume.vue` | `/ai/resume/latest`、`/ai/resume/update` 两处全地址 + `ws://localhost:9090/ws/chat` |
| `vue-springAi/src/views/recommend.vue` | `/api/recommend/jobs` 全地址 |
| `vue-springAi/src/views/wsChatView.vue` | `ws://localhost:9090/ws/chat` |

同时改 `config/WebConfig` 的 `allowedOrigins`（前端端口变了也要改）。

---

## 9. 检查方法（可执行，按顺序做）

### 9-1 数据库

```powershell
# 建库建表（首次）
& "D:\Mysql mianyangzheng\bin\mysql.exe" -uroot --password=zheng springai -e "source D:/.../springai.sql"

# 检查 5 张表是否齐全
& "D:\Mysql mianyangzheng\bin\mysql.exe" -uroot --password=zheng springai -e "show tables;"

# 检查职位数据量（推荐功能必须有数据才看得见效果）
& "D:\Mysql mianyangzheng\bin\mysql.exe" -uroot --password=zheng springai -e "select count(*) from job_position;"

# 检查最新简历的 5 个 JSON 字段是否为空
& "D:\Mysql mianyangzheng\bin\mysql.exe" -uroot --password=zheng springai -e "select id,user_id,update_time,education is null as edu_null from resume order by update_time desc limit 3;"
```

### 9-2 后端编译与启动（Java 必须是 17）

```powershell
$env:JAVA_HOME = "D:\javaidea"     # 改成你本机 JDK17 的路径
java -version                      # 必须显示 17.x
cd "D:\...\spring-ai\spring-ai"
mvn -q clean compile               # 编译通过 = 源码无语法级错误
mvn spring-boot:run                # 启动；日志出现 "Tomcat started on port 9090" 为成功
```

常见失败对照：

| 报错 | 原因 |
| --- | --- |
| `不支持发行版本 17` | `JAVA_HOME` 指向了 JDK8/11，切到 JDK17 |
| `Access denied for user 'root'` | `application.yml` 密码与本机 MySQL 不一致 |
| `Unknown database 'springai'` | 未执行建表脚本 |
| 启动卡住/401 | `spring.ai.openai.api-key` 失效（中转站 key 会过期）；AI 相关接口先跳过，非 AI 接口仍可测 |

### 9-3 接口冒烟

```powershell
# 6 个必须返回 200 的只读接口
$urls = @(
  "http://localhost:9090/api/job/categories",
  "http://localhost:9090/api/job/list?page=1&size=5",
  "http://localhost:9090/api/job/detail/1",
  "http://localhost:9090/api/history/getHistory?userId=test&pageNum=1&pageSize=10",
  "http://localhost:9090/ai/resume/latest?userId=test",
  "http://localhost:9090/api/job/list?page=1&size=5&categoryId=1"
)
foreach ($u in $urls) {
  try { $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15; "$($r.StatusCode)  $u" }
  catch { "FAIL  $u  ->  $($_.Exception.Response.StatusCode.value__)" }
}
```

### 9-4 前端

```powershell
cd "D:\...\vue-springAi"
npm run dev            # 期望 http://localhost:5173，页面可打开、登录不报 CORS
npm run build          # 期望 dist/ 生成且无 ENOENT（缺文件会在构建期暴露）
```

### 9-5 端到端最小验收（5 步）

1. `/login` 用 `demo@zhida.com / 123456` 登录成功 → 拿到 `user.id`。
2. `/jobPool` 列表有数据、搜索/分类筛选生效。
3. `/resume` 点生成（走 WS）→ 出现逐块输出 → 页面字段被填 → 能导出 `.docx` 与 `.pdf`。
4. `/recommend` 能看到职位卡片 + 推荐理由 + 简历优化建议（需第 3 步先有简历）。
5. `/history` 能看到第 3 步产生的对话记录。

---

## 10. 已知问题与陷阱（真实存在，改动前先看）

| # | 位置 | 问题 | 影响 | 建议 |
| --- | --- | --- | --- | --- |
| 1 | `config/WebConfig` | `allowedOrigins` 只放行 `http://localhost:5173` | GitHub Pages 上的前端（`qin-sylus.github.io`）**调不到本地后端**，预览页只能看界面 | 需要真机联调时把 Pages 域名加进白名单；面试演示用本地 5173 |
| 2 | `RecommendController.calculateMatchScore` | 地点 `+15` 无条件加分 | 推荐结果被"有地点"的职位普遍抬高 | 传用户期望地点做 `contains` 比较 |
| 3 | `/api/job-recommend/*` | 前端零调用 | 两套推荐算法并存，容易误改/误讲 | 展示算法能力用它，实际路径讲清楚是 A |
| 4 | `src/router/history.js` | 未被引用，且 URL 缺 `/api` | 一旦有人"顺手启用"就 404 | 删除或修正 |
| 5 | `UserServiceImpl.login` | 明文 `equals` 比较密码，且 `login` 返回体含 `password` | 安全风险：密码以明文落库与返回 | 建议改为 BCrypt 哈希校验 + JWT 返回 token |
| 6 | `springai.sql` 的 `user` / `history` | 两张表没有主键 | 无法主键去重/更新，`selectOne` 遇到重复行会抛 `TooManyResultsException` | 补 `PRIMARY KEY` |
| 7 | `application.yml` | AI `base-url` 指向中转站，key 会失效 | AI 接口 401/超时；`/recommend` 的理由与建议退化为兜底文案 | 换官方 key 或本地 mock |
| 8 | `gh-pages` 分支 | 预览说明条（黄色 banner）只存在于**构建产物**里，源码没有 | 重新构建部署会丢这条说明 | 若要长期保留，应把 banner 写进源码模板 |
| 9 | `POST /api/job/category/add` | 恒返回 `success:true`，不校验插入结果 | 插入失败时前端仍显示成功 | 改成 `success = saved != null` |

---

## 11. 改完代码之后（提交前自检清单）

1. 每一个被改的接口，按 §9-3 跑一遍，状态码与返回体结构不变。
2. 涉及简历结构 → 按 §8-3 的 7 处逐条比对，跑 §9-5 第 3、4 步。
3. 涉及前端地址 → 按 §8-7 的 6 处确认，启动后 F12 无 404 / 无 CORS。
4. **回改本文**：改动的文件、接口、已知问题条目同步更新，`事实基准` 里的提交号改成新 HEAD。
5. 提交信息建议明确到层：`feat(job): 职位列表增加地点筛选（mapper/controller/service/jobPool.vue 四处）`。
