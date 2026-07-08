# EneDataCenterMonitor — 数据中心运行监控大屏

> **课程项目：大数据专题 — 数据中心运行监控大屏**  
> 完整全栈项目：Docker + MySQL 数据仓库 → Node.js API 后端 → Vue3 可视化大屏

---

## 📋 项目概述

基于 4 个原始监控数据文件（`.dat`），构建一个企业级数据中心监控大屏系统：

```
原始 .dat 文件
      │
      ▼
Docker MySQL 容器 → 建表 → LOAD DATA 导入 → 清洗 → 聚合
      │
      ▼
9 张 dashboard_* 结果表（预聚合，供前端直查）
      │
      ▼
Node.js + Express API 服务（9 个 REST 接口，端口 8080）
      │
      ▼
Vue3 + Vite + ECharts 可视化大屏（科技感 HUD 风格，端口 5173）
```

---

## 🗂️ 项目目录结构

```
EneDataCenterMonitor/
├── README.md
├── .gitignore
│
├── data/                              # 原始数据（老师提供的 .dat 文件）
│   ├── host_detail.dat
│   ├── mod_detail.dat
│   ├── pref_tsar.dat
│   └── disk_tsar.dat
│
├── docker/                            # Docker 环境 — MySQL 8.0 容器
│   ├── docker-compose.yml
│   └── my.cnf
│
├── sql/                               # SQL 脚本（按流程编号）
│   ├── 01_create_tables.sql           # ① 建库 + 维度表 + 事实表
│   ├── 02_import_data.sql             # ② LOAD DATA 导入
│   ├── 03_clean_data.sql              # ③ 时间转换 + 异常检测
│   ├── 04_statistics.sql              # ④ 16 个统计分析查询
│   └── 05_result_tables.sql           # ⑤ 9 张 dashboard_* 结果表
│
├── backend/                           # Node.js + Express API 服务
│   ├── package.json
│   ├── server.js                      # 入口（端口 8080）
│   ├── config/db.js                   # MySQL 连接池
│   ├── routes/dashboard.js            # 9 条路由
│   └── controllers/dashboardController.js
│
├── frontend/                          # Vue3 + Vite + ECharts 大屏
│   ├── package.json
│   ├── index.html
│   ├── vite.config.js
│   └── src/
│       ├── main.js
│       ├── App.vue                    # 主布局
│       ├── api/dashboard.js           # Axios API 封装
│       ├── assets/global.css          # 全局 HUD 样式
│       └── components/                # 9 个可视化组件
│           ├── KpiCard.vue
│           ├── CpuTrend.vue
│           ├── MemoryTrend.vue
│           ├── NetworkTrend.vue
│           ├── DiskTrend.vue
│           ├── LoadTrend.vue
│           ├── CpuRank.vue
│           ├── RoomDist.vue
│           └── GlassPanel.vue
│
├── scripts/                           # 辅助脚本
│   ├── setup.sh                       # 一键部署 Docker + 数据
│   └── run_all.sh                     # 全量重跑 SQL
│
└── doc/                               # 文档
    ├── prompt/                        # 原始需求文档
    ├── 数据字典.md
    ├── 大屏指标设计文档.md
    └── API接口文档.md
```

---

## 🚀 完整启动步骤

### 前置条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Node.js](https://nodejs.org/) 18+（后端 & 前端）
- Git Bash（Windows 下执行 `.sh` 脚本）

### 步骤 1：克隆项目

```bash
git clone git@github.com:entyame/EneDataCenterMonitor.git
cd EneDataCenterMonitor
```

### 步骤 2：部署 Docker MySQL 数据库

```bash
# Windows Git Bash 中运行：
bash scripts/setup.sh

# 该脚本会自动完成：
#   ✓ 检测 Docker 环境
#   ✓ 启动 MySQL 8.0 容器（端口 3306）
#   ✓ 建表 + 导入 79,200 行数据
#   ✓ 执行数据清洗 + 生成 9 张结果表
```

### 步骤 3：启动后端 API 服务

```bash
cd backend
npm install
npm start          # 启动 → http://localhost:8080
```

验证：
```bash
curl http://localhost:8080/api/kpi
```

### 步骤 4：启动前端大屏

```bash
cd frontend
npm install
npm run dev        # 启动 → http://localhost:5173
```

浏览器打开 **http://localhost:5173** 即可看到数据中心监控大屏。

---

## 🔌 各服务端口

| 服务 | 端口 | 地址 |
|------|------|------|
| MySQL (Docker) | 3306 | `localhost:3306` |
| 后端 API | 8080 | `http://localhost:8080` |
| 前端大屏 | 5173 | `http://localhost:5173` |

MySQL 连接信息：`ene_user` / `ene_pass_2026` @ `ene_datacenter`

---

## 🧱 数据库设计

### 维度表（2 张）

| 表 | 来源 | 行数 |
|----|------|------|
| `dim_host` | host_detail.dat | 20 |
| `dim_mod` | mod_detail.dat | 55 |

### 事实表（2 张）

| 表 | 来源 | 行数 | 说明 |
|----|------|------|------|
| `fact_pref_tsar` | pref_tsar.dat | 67,200 | 性能监控：20主机 × 20指标 × 168小时 |
| `fact_disk_tsar` | disk_tsar.dat | 12,000 | 磁盘监控：5磁盘 × 7指标 |

### 结果表（9 张 → 前端查询）

| 表 | 大屏组件 | 行数 |
|----|----------|------|
| `dashboard_kpi_summary` | 顶部 5 个 KPI 数字卡片 | 12 |
| `dashboard_cpu_hour` | CPU 趋势折线图 | 168 |
| `dashboard_mem_hour` | 内存堆叠面积图 | 168 |
| `dashboard_net_hour` | 网络双轴折线图 | 168 |
| `dashboard_load_hour` | 负载折线图 | 168 |
| `dashboard_disk_hour` | 磁盘 IO 趋势图 | 1000 |
| `dashboard_host_rank` | CPU/内存/磁盘 TOP10 | 57 |
| `dashboard_room_summary` | 机房分布饼图 | 5 |
| `dashboard_alert_detail` | 告警滚动列表 | 3 |

---

## 📡 API 接口一览

| 接口 | 说明 |
|------|------|
| `GET /api/kpi` | 首页 KPI 卡片（1h + 24h） |
| `GET /api/cpu/hour` | CPU 使用率 24h 趋势 |
| `GET /api/memory/hour` | 内存使用 24h 趋势 |
| `GET /api/network/hour` | 网络流量 24h 趋势 |
| `GET /api/load/hour` | 系统负载 24h 趋势 |
| `GET /api/disk/hour` | 磁盘 IO 趋势 |
| `GET /api/hosts/rank?type=cpu&top=10` | 服务器排名 |
| `GET /api/rooms` | 机房分布统计 |
| `GET /api/alerts` | 实时告警列表 |

详细文档：[doc/API接口文档.md](doc/API接口文档.md)

---

## 📊 数据概览

| 维度 | 详情 |
|------|------|
| 主机 | 20 台（host001 ~ host020） |
| 机房 | A/B/C/D/E 共 5 个机房 |
| 监控指标 | CPU(5) + 内存(5) + 网络(4) + 负载(3) + 进程(3) + 磁盘(35) = **55 个** |
| 性能时间范围 | 2026-06-30 ~ 2026-07-06（7天 × 168小时） |
| 数据总量 | 79,200 行 |

---

## 🐳 Docker 的作用

Docker 负责**运行 MySQL 数据库**，好处是：
- **免安装**：不用装 MySQL，一条命令搞定
- **环境一致**：任何人运行都一样，不会"我这能跑你那报错"
- **数据不丢**：Volume 持久化存储，删容器 ≠ 删数据
- **自动初始化**：首次启动自动建表+导入数据

```bash
docker compose up -d          # 启动
docker compose down           # 停止
docker compose ps             # 状态
```

---

## 📚 文档索引

| 文档 | 内容 |
|------|------|
| [数据字典](doc/数据字典.md) | 原始文件字段、类型、关联关系 |
| [大屏指标设计文档](doc/大屏指标设计文档.md) | 大屏布局、指标清单、告警阈值 |
| [API 接口文档](doc/API接口文档.md) | curl 命令、返回格式、错误排查 |

---

## 📄 License

课程学习项目。
