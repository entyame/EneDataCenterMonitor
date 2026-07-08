# EneDataCenterMonitor — 数据中心运行监控大屏

> **课程项目：大数据专题 — 数据中心运行监控大屏**  
> 全栈项目：Docker + MySQL 数仓 → Node.js API → Vue3 + ECharts 可视化大屏

---

## 🖥️ 运行界面

![数据中心运行监控大屏](doc/运行界面截图.png)

---

## 📋 项目概述

基于 4 个原始监控数据文件（`.dat`），构建完整的企业级数据中心监控大屏：

```
原始 .dat 文件 (79,200 行)
      │
      ▼
Docker MySQL 8.0 容器 — 建表 → LOAD DATA 导入 → 清洗 → 聚合
      │
      ▼
9 张 dashboard_* 结果表（预聚合，前端直查）
      │
      ▼
Node.js + Express 后端 API — 9 个 REST 接口 (端口 8080)
      │
      ▼
Vue3 + Vite + ECharts 可视化大屏 — 科技感 HUD (端口 5173)
```

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 数据库 | MySQL 8.0 (Docker) | 星型模型数仓，4 张原始表 → 9 张结果表 |
| 后端 | Node.js + Express + mysql2 | RESTful API，连接池，端口 8080 |
| 前端 | Vue 3 + Vite + ECharts 5 + Axios | SPA 大屏，端口 5173 |
| 部署 | Docker Compose | 一键启动 MySQL，自动初始化建表+导入 |

---

## 🗂️ 项目目录结构

```
EneDataCenterMonitor/
├── README.md
├── .gitignore
│
├── data/                              # 原始数据（老师提供的 .dat 文件）
│   ├── host_detail.dat                #   主机信息 (20台)
│   ├── mod_detail.dat                 #   指标字典 (55个指标)
│   ├── pref_tsar.dat                  #   性能监控 (67,200 行)
│   └── disk_tsar.dat                  #   磁盘监控 (12,000 行)
│
├── docker/                            # Docker 环境
│   ├── docker-compose.yml             #   MySQL 8.0 容器编排
│   └── my.cnf                         #   MySQL 调优配置
│
├── sql/                               # SQL 脚本（按流程编号执行）
│   ├── 01_create_tables.sql           #   ① DDL：建库 + 2张维度表 + 2张事实表
│   ├── 02_import_data.sql             #   ② LOAD DATA INFILE 导入
│   ├── 03_clean_data.sql              #   ③ 时间转换 + 异常检测 + 一致性验证
│   ├── 04_statistics.sql              #   ④ 16 个统计分析查询（可选查看）
│   └── 05_result_tables.sql           #   ⑤ 生成 9 张 dashboard_* 结果表
│
├── backend/                           # Node.js + Express API 服务
│   ├── package.json
│   ├── server.js                      #   入口（端口 8080）
│   ├── config/
│   │   └── db.js                      #   MySQL 连接池配置
│   ├── routes/
│   │   └── dashboard.js               #   9 条 API 路由
│   └── controllers/
│       └── dashboardController.js     #   9 个 SQL 查询函数
│
├── frontend/                          # Vue3 + Vite + ECharts 大屏
│   ├── package.json
│   ├── index.html
│   ├── vite.config.js                 #   API 代理到 :8080
│   └── src/
│       ├── main.js
│       ├── App.vue                    #   主布局（左栏 + 右区域）
│       ├── api/
│       │   └── dashboard.js           #   Axios 封装 9 个接口
│       ├── assets/
│       │   └── global.css             #   全局 HUD 主题样式
│       └── components/
│           ├── GlassPanel.vue         #   通用玻璃面板（四角边框 + 发光）
│           ├── KpiCard.vue            #   KPI 数字卡片
│           ├── CpuTrend.vue           #   CPU 5线趋势图
│           ├── MemoryTrend.vue        #   内存堆叠面积图
│           ├── NetworkTrend.vue       #   网络双轴折线图
│           ├── DiskTrend.vue          #   磁盘 IO 趋势图
│           ├── LoadTrend.vue          #   系统负载趋势图
│           ├── CpuRank.vue            #   CPU TOP10 横向柱状图
│           └── RoomDist.vue           #   机房分布环形饼图
│
├── scripts/                           # 辅助脚本
│   ├── setup.sh                       #   一键部署：启动 Docker + 执行全量 SQL
│   └── run_all.sh                     #   全量重跑 SQL（已有容器时使用）
│
└── doc/                               # 文档
    ├── prompt/                        #   原始需求文档
    ├── 数据字典.md                     #   字段说明、关联关系
    ├── 大屏指标设计文档.md             #   大屏布局 + 指标清单 + 告警阈值
    ├── API接口文档.md                  #   curl 命令 + 返回格式 + 错误排查
    └── 运行界面截图.png                #   大屏实际运行效果截图
```

---

## 🚀 完整启动步骤

### 前置条件

| 工具 | 用途 | 安装 |
|------|------|------|
| Docker Desktop | 运行 MySQL 容器 | [下载](https://www.docker.com/products/docker-desktop) |
| Node.js 18+ | 后端 + 前端 | [下载](https://nodejs.org/) |
| Git Bash | Windows 下执行脚本 | 安装 Git 时自带 |

### 步骤 1：克隆项目

```bash
git clone git@github.com:entyame/EneDataCenterMonitor.git
cd EneDataCenterMonitor
```

### 步骤 2：部署 MySQL 数据库（Docker）

```bash
bash scripts/setup.sh
```

脚本自动完成：
- 启动 MySQL 8.0 容器（端口 3306）
- 建表 + 导入 79,200 行原始数据
- 时间转换 + 数据清洗（0异常、0空值、100%完整）
- 生成 9 张 `dashboard_*` 结果表

验证导入结果：
```bash
docker exec -i ene_dc_monitor_mysql mysql -h 127.0.0.1 -u root -proot123456 -e "
  SELECT 'dim_host' AS tbl, COUNT(*) FROM ene_datacenter.dim_host
  UNION ALL SELECT 'dim_mod', COUNT(*) FROM ene_datacenter.dim_mod
  UNION ALL SELECT 'fact_pref', COUNT(*) FROM ene_datacenter.fact_pref_tsar
  UNION ALL SELECT 'fact_disk', COUNT(*) FROM ene_datacenter.fact_disk_tsar;
"
# 预期：20 | 55 | 67200 | 12000
```

### 步骤 3：启动后端 API

```bash
cd backend
npm install
npm start
# → http://localhost:8080
# 验证：curl http://localhost:8080/api/kpi
```

### 步骤 4：启动前端大屏

```bash
cd frontend
npm install
npm run dev
# → http://localhost:5173
```

浏览器打开 **http://localhost:5173** 即可看到完整的数据中心监控大屏。

---

## 🔌 服务端口一览

| 服务 | 端口 | 地址 | 状态检查 |
|------|------|------|----------|
| MySQL (Docker) | 3306 | `localhost:3306` | `docker ps \| grep ene_dc_monitor` |
| 后端 API | 8080 | `http://localhost:8080` | `curl localhost:8080/` |
| 前端大屏 | 5173 | `http://localhost:5173` | 浏览器打开 |

MySQL 连接信息：

| 参数 | 值 |
|------|-----|
| 地址 | `localhost:3306` |
| 数据库 | `ene_datacenter` |
| 用户 | `ene_user` / `ene_pass_2026` |
| Root | `root` / `root123456` |
| 字符集 | `utf8mb4` |

---

## 🎨 前端设计

### 布局

```
┌──────────────────────────────────────────────┐
│              标题栏 + 实时时钟                  │
├─────────┬────────────────────────────────────┤
│ CPU     │ KPI₁ │ KPI₂ │ KPI₃ │ KPI₄ │ KPI₅   │
│ 排名    ├────────────────────────────────────┤
│ TOP10   │       CPU 使用率趋势（全宽）         │
│         ├──────────────────┬─────────────────┤
│ 机房     │   内存使用趋势    │   网络流量趋势    │
│ 分布     ├──────────────────┼─────────────────┤
│ (饼图)   │   磁盘 IO 趋势    │   系统负载趋势    │
├─────────┴──────────────────┴─────────────────┤
│              告警滚动条 (红色)                  │
└──────────────────────────────────────────────┘
```

### 视觉风格

| 元素 | 实现 |
|------|------|
| 背景 | 深色 `#0a0a1a` + 动态粒子网络 + 网格扫描线 |
| 面板 | 半透明玻璃质感 + `backdrop-filter: blur(12px)` |
| 边框 | 紫色渐变发光 + 四角 HUD 切割边框 |
| 配色 | 紫 `#7c3aed` + 金 `#f59e0b` + 绿 `#10b981` + 青 `#06b6d4` |
| 数据 | 等宽字体 + 发光阴影 + 每 60 秒自动刷新 |
| 告警 | 红色闪烁滚动条 |

---

## 🧱 数据库设计

采用**星型模型**数仓架构：

```
        ┌──────────┐         ┌──────────┐
        │ dim_host │         │ dim_mod  │
        │  20 行   │         │  55 行   │
        └────┬─────┘         └────┬─────┘
             │ 1:N                │ 1:N
             ▼                    ▼
    ┌────────────────┐  ┌────────────────┐
    │ fact_pref_tsar │  │ fact_disk_tsar │
    │   67,200 行    │  │   12,000 行    │
    └───────┬────────┘  └───────┬────────┘
            │  清洗 + 聚合        │
            ▼                    ▼
    ┌─────────────────────────────────────┐
    │        9 张 dashboard_* 结果表        │
    │  (KPI / 趋势 / 排名 / 分布 / 告警)    │
    └─────────────────────────────────────┘
```

| 结果表 | 大屏组件 | 行数 |
|--------|----------|------|
| `dashboard_kpi_summary` | 顶部 KPI 数字卡片 ×5 | 12 |
| `dashboard_cpu_hour` | CPU 五线趋势折线图 | 168 |
| `dashboard_mem_hour` | 内存堆叠面积图 | 168 |
| `dashboard_net_hour` | 网络双轴折线图 | 168 |
| `dashboard_load_hour` | 系统负载趋势图 | 168 |
| `dashboard_disk_hour` | 磁盘 IO 趋势图 | 1000 |
| `dashboard_host_rank` | CPU/内存/磁盘 TOP10 | 57 |
| `dashboard_room_summary` | 机房分布饼图 | 5 |
| `dashboard_alert_detail` | 告警滚动列表 | 3 |

---

## 📡 API 接口

| 接口 | 查询表 | 说明 |
|------|--------|------|
| `GET /api/kpi` | `dashboard_kpi_summary` | 首页 KPI（1h + 24h 两组） |
| `GET /api/cpu/hour` | `dashboard_cpu_hour` | CPU 24h 趋势（user/sys/wait/usage/idle） |
| `GET /api/memory/hour` | `dashboard_mem_hour` | 内存 24h 趋势（used/free/buff/cache/swap） |
| `GET /api/network/hour` | `dashboard_net_hour` | 网络流量（入站/出站 + 数据包） |
| `GET /api/load/hour` | `dashboard_load_hour` | 系统负载（load1/5/15） |
| `GET /api/disk/hour` | `dashboard_disk_hour` | 磁盘 IO（读/写/使用率/延迟） |
| `GET /api/hosts/rank?type=cpu&top=10` | `dashboard_host_rank` | 服务器排名 |
| `GET /api/rooms` | `dashboard_room_summary` | 机房分布 |
| `GET /api/alerts` | `dashboard_alert_detail` | 实时告警 |

详细文档 → [doc/API接口文档.md](doc/API接口文档.md)，含 curl 示例和返回格式。

---

## 📊 数据概览

| 维度 | 详情 |
|------|------|
| 主机数量 | 20 台（host001 ~ host020） |
| 机房数量 | A / B / C / D / E 共 5 个机房 |
| 服务器型号 | Dell R750/R740, HP DL388, Huawei 2288H, Lenovo SR650/SR860 |
| 监控指标 | CPU(5) + 内存(5) + 网络(4) + 负载(3) + 进程(3) + 磁盘(35) = **55 个** |
| 磁盘数量 | 每台 5 块（sda / sdb / sdc / sdd / sde） |
| 时间范围 | 性能: 2026-06-30 ~ 2026-07-06（7天 × 168小时）；磁盘: 约 42 天 |
| 数据总量 | 性能 67,200 + 磁盘 12,000 = **79,200 行** |
| 数据质量 | 0 异常值 · 0 空值 · 0 孤立ID · 100% 完整性 |

---

## 🐳 Docker 的作用

Docker 在本项目中负责**运行 MySQL 数据库**，核心价值：

1. **免安装** — 不需要下载 MySQL 安装包、配环境变量、折腾 Windows 服务
2. **环境一致** — `docker-compose.yml` 固定了 MySQL 8.0 + utf8mb4 + 时区，任何人跑都一样
3. **数据不丢** — Volume 持久化存储，`docker compose down` 删容器不删数据
4. **自动初始化** — `sql/` 挂载到 `/docker-entrypoint-initdb.d/`，首次启动自动建表+导入
5. **一键启停** — `up` 启动、`down` 停止，比管理 Windows 服务简单得多

```bash
cd docker
docker compose up -d       # 启动
docker compose down        # 停止
docker compose ps          # 状态
docker compose logs mysql  # 日志
```

---

## 🔧 常见问题

| 现象 | 原因 | 解决 |
|------|------|------|
| `EACCES` 端口被占用 | Windows 保留端口 | 修改 `backend/server.js` 中 `PORT` 为 8080 等空闲端口 |
| 数据全是 0 | Docker Volume 未重建 | `docker compose down -v && docker compose up -d` |
| `LOAD DATA` 报错 | `secure-file-priv` 路径不对 | 检查 `02_import_data.sql` 中路径是否为绝对路径 |
| 前端图表无数据 | 后端未启动 | `cd backend && npm start` |
| 前端图表数据不更新 | 代理配置问题 | 检查 `vite.config.js` 中 proxy target 是否为 `http://localhost:8080` |
| MySQL 容器不健康 | my.cnf 权限问题（Windows） | 已修复：配置已合并到 docker-compose `command` 中 |

---

## 📚 文档索引

| 文档 | 内容 |
|------|------|
| [运行界面截图](doc/运行界面截图.png) | 大屏实际运行效果 |
| [数据字典](doc/数据字典.md) | 4 个原始文件字段、类型、关联关系 |
| [大屏指标设计文档](doc/大屏指标设计文档.md) | 大屏布局、指标清单、告警阈值、API 建议 |
| [API 接口文档](doc/API接口文档.md) | curl 命令、返回格式示例、错误排查 |
| [原始需求 - 数据加工](doc/prompt/数据加工提示词.txt) | 数据准备阶段完整需求 |
| [原始需求 - 后端接口](doc/prompt/接口提示词.txt) | 后端 API 开发需求 |
| [原始需求 - 前端开发](doc/prompt/前端开发提示词.txt) | 前端大屏开发需求 |

---

## 📄 License

课程学习项目。
