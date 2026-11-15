# 职达助手 · 基于 SpringBoot + Vue + AI 大模型的简历生成与职业推荐系统

一个面向求职者的智能简历平台：填写个人信息后由大模型生成 / 润色简历，支持导出 Word 与 PDF；同时基于技能标签与岗位库做匹配度计算，给出 Top 5 职位推荐并由大模型生成推荐理由。系统还提供岗位池管理、AI 实时对话（WebSocket 流式输出）与历史记录查询。

---

## 技术栈

### 后端 `spring-ai/spring-ai`

| 分类 | 选型 |
| --- | --- |
| 框架 | Spring Boot 3.4.0 / Java 17 |
| AI | Spring AI 1.0.0-M4（`spring-ai-openai-spring-boot-starter`），OpenAI 兼容协议 |
| 持久层 | MyBatis-Plus 3.5.9 |
| 数据库 | MySQL 8（库名 `springai`） |
| 实时通信 | Spring WebSocket（`/ws/chat`） |
| 响应式 | Spring WebFlux（流式对话） |
| 其他 | Spring Mail、Lombok |
| 端口 | `9090` |

### 前端 `vue-springAi`

| 分类 | 选型 |
| --- | --- |
| 框架 | Vue 3.5（`<script setup>`） |
| 构建 | Vite 5.4 |
| UI | Element Plus 2.8（含图标库） |
| 请求 | Axios（`src/utils/axios-config.js` 统一实例，baseURL `http://localhost:9090`） |
| 路由 | Vue Router 4 |
| 导出 | `docx` + `file-saver`（导出 Word）、`html2pdf.js`（导出 PDF） |
| 调试 | vite-plugin-vue-devtools |

---

## 功能模块

| 模块 | 说明 |
| --- | --- |
| 用户注册 / 登录 | 邮箱 + 密码登录，图形验证码校验，登录态写入 localStorage |
| 简历管理 | 教育经历、专业技能、工作经历、项目经历、获奖情况五段式表单，支持回显与保存 |
| AI 简历生成 | 调用大模型生成简历内容，支持逐段润色与实时对话修改 |
| 简历导出 | 一键导出 Word（docx）与 PDF（html2pdf） |
| 职业推荐 | 基于技能关键词与岗位库计算匹配度，叠加学历 / 经验 / 地点加权，输出 Top 5 及 AI 推荐理由 |
| 岗位池 | 职位分类与职位的增删改查（仅供内部维护） |
| AI 对话 | WebSocket 流式对话，`/ws/chat` |
| 历史记录 | 按用户查询历史问答 |

---

## 目录结构

```
基于SpringBoot+Vue+AI大模型的简历生成+职业推荐系统/
├── springai.sql                  # 建表脚本（5 张表，无数据）
├── 示例数据.sql                   # 演示数据（7 分类 / 15 职位 / 3 账号 / 3 简历 / 8 条问答）
├── spring-ai/
│   └── spring-ai/                # 后端工程
│       ├── pom.xml
│       ├── src/main/java/com/example/springai/
│       │   ├── SpringAiApplication.java
│       │   ├── config/           # WebConfig（CORS）、uuid 生成器
│       │   ├── controller/       # User / Resume / Job / JobRecommend / Recommend / Chat / History
│       │   ├── service/ + impl/  # 业务层，含 JobRecommendServiceImpl 匹配算法
│       │   ├── mapper/           # MyBatis-Plus Mapper（含 @Select 联表查询）
│       │   ├── model/ dto/
│       │   └── websocket/        # ChatWebSocketHandler、WebSocketConfig
│       └── src/main/resources/application.yml
└── vue-springAi/                 # 前端工程
    ├── package.json
    ├── vite.config.js
    ├── index.html
    └── src/
        ├── main.js
        ├── components/r-header.vue
        ├── router/index.js
        ├── utils/                # axios-config.js、SidentifyView.vue（图形验证码）
        └── views/                # Login、Register、indexView、Resume、recommend、jobPool、wsChatView、HistoryView
```

---

## 数据库

库名 **`springai`**，5 张表：

| 表 | 说明 |
| --- | --- |
| `user` | 用户（`email` + 明文 `password` 登录） |
| `history` | AI 问答历史 |
| `resume` | 简历主体，教育 / 技能 / 工作 / 项目 / 获奖以 JSON 文本存储 |
| `job_category` | 职位分类 |
| `job_position` | 职位信息，`category_id` 外键关联 `job_category` |

导入顺序（**必须先建库再执行脚本**）：

```powershell
$mysql = "D:\Mysql mianyangzheng\bin\mysql.exe"   # 换成本机 mysql.exe 路径
& $mysql -uroot -p -e "CREATE DATABASE IF NOT EXISTS springai DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
& $mysql -uroot -p springai --execute="source D:/.../springai.sql"
& $mysql -uroot -p springai --execute="source D:/.../示例数据.sql"
```

在 Navicat 中则需：双击选中 `springai` 库 → 右键该库 →「运行 SQL 文件」，否则会报 `1046 No database selected`。

**重复导入前必须先清空**，否则主键冲突（`1062 Duplicate entry`）：

```sql
DELETE FROM job_position; DELETE FROM job_category;
DELETE FROM resume; DELETE FROM user; DELETE FROM history;
ALTER TABLE job_category AUTO_INCREMENT = 1;
ALTER TABLE job_position AUTO_INCREMENT = 1;
ALTER TABLE resume AUTO_INCREMENT = 1;
```

> 注意：不能对 `job_category` 用 `TRUNCATE`，它被 `job_position` 外键引用，MySQL 会报 `1701`。

---

## 本地运行

### 环境要求

- JDK 17 及以上（本项目用 17 编译；JDK 8 会报 `不支持发行版本 17`）
- Maven 3.9+
- MySQL 8.0+
- Node.js 18+（Vite 5 要求）

### 1. 后端

```powershell
$env:JAVA_HOME = "D:\javaidea"     # 或任意 JDK 17+ 路径
cd "D:\...\spring-ai\spring-ai"
mvn clean spring-boot:run
```

启动成功标志：`Started SpringAiApplication`，服务地址 `http://localhost:9090`。

**配置准备**：仓库中没有 `application.yml`（内含数据库密码与 API Key，已加入 `.gitignore`）。首次运行请先复制模板，再改成本机参数：

```powershell
cd src\main\resources
copy application-example.yml application.yml
```

需要修改的字段：

```yaml
spring:
  ai:
    openai:
      base-url: https://api.openai.com/   # 换成你可用的 OpenAI 兼容服务地址
      api-key: sk-xxxx                    # 换成有效 Key，否则 AI 功能报 401
  datasource:
    url: jdbc:mysql://localhost:3306/springai?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai
    username: root
    password: 你的MySQL密码
```

> 也可以改用环境变量注入：`api-key: ${AI_API_KEY}`、`password: ${DB_PASSWORD}`，避免明文落盘。

### 2. 前端

```powershell
cd "D:\...\vue-springAi"
npm install      # node_modules 已存在时通常可跳过
npm run dev
```

访问 **http://localhost:5173**（`vite.config.js` 未指定端口，用 Vite 默认值）。

### 3. 演示账号

登录框填**邮箱**，不是用户名：

| 邮箱 | 密码 | 简历预设 |
| --- | --- | --- |
| `demo@zhida.com` | `123456` | Java 后端方向 |
| `zhengqiang@zhida.com` | `123456` | Vue 前端方向 |
| `xiaoyu@zhida.com` | `123456` | 数据分析方向 |

---

## 已知问题

已修复（本次整理中处理）：

| 问题 | 位置 | 处理方式 |
| --- | --- | --- |
| 登录表单缺 `rules` 校验定义，且登录失败无任何提示 | `src/views/Login.vue` | 补齐邮箱 / 密码校验规则，改为校验通过才请求；后端返回 400 时提示“邮箱或密码不正确” |
| WebSocket 端口写成 8080 | `src/views/Resume.vue` | 已改为 `ws://localhost:9090/ws/chat`，与后端一致 |
| 数据源驱动为 MySQL 5 旧类名 `com.mysql.jdbc.Driver` | `application-example.yml` | 已删除该行，交由 Spring Boot 按 url 自动推断 Connector/J 8 驱动 |
| 时区设为 `UTC` | `application-example.yml` | 已改为 `Asia/Shanghai`，避免时间字段差 8 小时 |

仍存在的限制：

| 问题 | 位置 | 说明 |
| --- | --- | --- |
| 密码明文存储 | `user.password` + `UserServiceImpl.login` | 学习项目未加密，生产环境需改为 BCrypt |
| 邮件配置为空 | `application.yml` 的 `spring.mail.*` | 未配置 SMTP 时邮件功能一调用即异常 |
| AI 依赖外部 Key | `application-example.yml` 的 `api-key` | Key 失效或额度耗尽时，AI 生成与推荐理由会返回 401 |

---

## 安全提醒

仓库中**不包含** `application.yml`，该文件已加入 `.gitignore`；仓库内提供 `application-example.yml` 作为模板。请勿将含真实数据库密码与 API Key 的配置文件提交到公开仓库。

---

## 说明

本项目为课程实践作品，用于学习与作品展示。