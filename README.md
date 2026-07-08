# EneDataCenterMonitor — 数据中心运行监控大屏

> **课程项目：大数据专题 — 数据中心运行监控大屏**  
> 完整的数据准备阶段：从 Docker 到前端数据服务层

---

## 📋 项目概述

本项目是一个企业级数据中心监控大屏的**数据准备与后端数据处理**部分。基于4个原始监控数据文件（`.dat`），通过 Docker + MySQL 搭建数据仓库，完成数据导入、清洗、统计分析和结果表生成，最终为 Vue + ECharts 可视化大屏提供可直接查询的聚合数据。

### 数据流程

```
原始 .dat 文件
      │
      ▼
Docker MySQL 容器部署
      │
      ▼
LOAD DATA 导入 4 张原始事实表
      │
      ▼
时间戳转换 + 数据清洗 + 异常检测
      │
      ▼
SQL 统计分析 (KPI / 趋势 / 排名 / 分布 / 异常)
      │
      ▼
生成 9 张 dashboard_* 结果表
      │
      ▼
Vue + ECharts 大屏消费（RESTful API）
```

---

## 🗂️ 项目目录结构

```
EneDataCenterMonitor/
├── README.md                          # 项目说明文档
├── .gitignore                         # Git 忽略规则
│
├── data/                              # 原始数据文件（老师提供）
│   ├── host_detail.dat                #   主机信息 (20台服务器)
│   ├── mod_detail.dat                 #   监控指标字典 (55个指标)
│   ├── pref_tsar.dat                  #   性能监控数据 (~67K 行, 7天)
│   └── disk_tsar.dat                  #   磁盘监控数据 (~12K 行)
│
├── docker/                            # Docker 环境配置
│   ├── docker-compose.yml             #   MySQL 8.0 容器编排
│   └── my.cnf                         #   MySQL 自定义配置（utf8mb4、InnoDB调优）
│
├── sql/                               # SQL 脚本（按执行顺序编号）
│   ├── 01_create_tables.sql           #   ① DDL：建库 + 维度表 + 事实表 + 索引
│   ├── 02_import_data.sql             #   ② 数据导入：LOAD DATA 导入 4 个 .dat
│   ├── 03_clean_data.sql              #   ③ 数据清洗：时间转换 + 异常检测 + 一致性验证
│   ├── 04_statistics.sql              #   ④ 统计分析：KPI/趋势/排名/分布/异常 (共16个查询)
│   └── 05_result_tables.sql           #   ⑤ 结果表：9张 dashboard_* 表（前端直查）
│
├── scripts/                           # 辅助脚本
│   ├── setup.sh                       #   一键部署：启动Docker + 执行SQL
│   └── run_all.sh                     #   全量重跑：按顺序执行全套SQL
│
└── doc/                               # 文档
    ├── 数据加工提示词.txt              #   原始需求文档
    ├── 数据字典.md                     #   数据字典（字段说明、关联关系）
    └── 大屏指标设计文档.md             #   大屏布局 + 指标清单 + 前端API建议
```

---

## 🚀 快速开始

### 前置条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop)（Windows/Mac）或 Docker Engine（Linux）
- Git Bash（Windows 下执行 `.sh` 脚本）

### 1. 克隆项目

```bash
git clone git@github.com:entyame/EneDataCenterMonitor.git
cd EneDataCenterMonitor
```

### 2. 一键部署

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

该脚本会自动：
1. 检测 Docker 环境
2. 复制 `.dat` 文件到容器挂载目录
3. 启动 MySQL 8.0 容器（端口 3306）
4. 自动建表 + 导入数据（容器初始化）
5. 执行数据清洗 + 生成结果表

### 3. 验证部署

```bash
# 进入 MySQL
docker exec -it ene_dc_monitor_mysql mysql -u root -proot123456 ene_datacenter

# 检查数据
SELECT COUNT(*) FROM fact_pref_tsar;       -- 应为 67200
SELECT COUNT(*) FROM fact_disk_tsar;       -- 应为 12000
SELECT COUNT(*) FROM dim_host;             -- 应为 20

# 查看 KPI 卡片数据
SELECT * FROM dashboard_kpi_summary;
```

### 4. 查看统计指标

```bash
# 在 MySQL 中执行统计分析 SQL
docker exec -i ene_dc_monitor_mysql mysql -u root -proot123456 ene_datacenter < sql/04_statistics.sql
```

---

## 🧱 数据库设计（数据仓库星型模型）

### 维度表（2张）

| 表名 | 来源 | 行数 | 说明 |
|------|------|------|------|
| `dim_host` | host_detail.dat | 20 | 主机维度：ID、域名、型号、机房、机架 |
| `dim_mod` | mod_detail.dat | 55 | 指标字典：编码、描述、单位、分组标签 |

### 事实表（2张）

| 表名 | 来源 | 行数 | 说明 |
|------|------|------|------|
| `fact_pref_tsar` | pref_tsar.dat | 67,200 | 性能监控：20主机 × 20指标 × 168小时 |
| `fact_disk_tsar` | disk_tsar.dat | 12,000 | 磁盘监控：5磁盘 × 7指标，稀疏采样 |

### 结果表（9张，供前端查询）

| 表名 | 大屏组件 | 粒度 |
|------|----------|------|
| `dashboard_kpi_summary` | 顶部KPI数字卡片 | 1h / 24h |
| `dashboard_cpu_hour` | CPU趋势折线图 | 小时 × 5指标 |
| `dashboard_mem_hour` | 内存堆叠面积图 | 小时 × 5指标 |
| `dashboard_net_hour` | 网络双轴折线图 | 小时 × 6指标 |
| `dashboard_load_hour` | 负载折线图 | 小时 × 3指标 |
| `dashboard_disk_hour` | 磁盘趋势折线图 | 小时 × 4指标 |
| `dashboard_host_rank` | CPU/内存/磁盘 TOP10 | 主机 × 排名 |
| `dashboard_room_summary` | 机房分布饼图 | 机房 |
| `dashboard_alert_detail` | 告警滚动列表 | 单条告警 |

### ER 关系图

```
┌──────────────┐       ┌─────────────────────┐
│   dim_host   │       │      dim_mod        │
│   (维度表)    │       │     (维度表)         │
│  PK: host_id │       │  PK: mod_id         │
└──────┬───────┘       └──────────┬──────────┘
       │ 1:N                      │ 1:N
       │                          │
┌──────┴──────────────────────────┴──────────┐
│              fact_pref_tsar                 │
│              (核心事实表)                     │
│  ts, host_id(FK), mod_id(FK), value, tag   │
└────────────────────────────────────────────┘

┌──────────────┐       ┌─────────────────────┐
│   dim_host   │       │      dim_mod        │
└──────┬───────┘       └──────────┬──────────┘
       │ 1:N                      │ 1:N
       │                          │
┌──────┴──────────────────────────┴──────────┐
│              fact_disk_tsar                 │
│              (辅助事实表)                     │
│  ts, host_id(FK), disk_name, mod_id(FK), … │
└────────────────────────────────────────────┘
```

---

## 📊 数据概览

| 维度 | 详情 |
|------|------|
| **主机数量** | 20 台服务器（host001 ~ host020） |
| **机房数量** | 5 个机房（A机房 ~ E机房） |
| **服务器型号** | Dell R750/R740, HP DL388, Huawei 2288H, Lenovo SR650/SR860 |
| **监控指标** | CPU(5) + 内存(5) + 网络(4) + 负载(3) + 进程(3) + 磁盘(35) = **55 个** |
| **时间范围** | 性能数据: 2026-06-30 ~ 2026-07-06（7天 × 24小时 = 168个采样点） |
| **数据总量** | 性能 67,200 行 + 磁盘 12,000 行 = **79,200 行** |

---

## 🔌 MySQL 连接信息

| 参数 | 值 |
|------|-----|
| 地址 | `localhost:3306` |
| 数据库 | `ene_datacenter` |
| Root 用户 | `root` / `root123456` |
| 应用用户 | `ene_user` / `ene_pass_2026` |
| 字符集 | `utf8mb4` |
| 时区 | `Asia/Shanghai (+08:00)` |

---

## 🐳 Docker 的作用（给不熟悉的同学）

### Docker 是什么？

**Docker** 是一个容器化平台。你可以把它理解为**轻量级的虚拟机**——不需要在你的电脑上装一个完整的 Linux 系统，就能运行一个独立的、隔离的软件环境。

### 在这个项目中，Docker 扮演了什么角色？

在这个项目里，Docker 负责**运行 MySQL 数据库**。具体来说：

1. **免安装 MySQL**  
   你不需要下载 MySQL 安装包、配置环境变量、折腾 Windows 服务。Docker 帮你把所有东西打包在"容器"里，一条命令就能启动一个配置好的 MySQL。

2. **环境一致性**  
   `docker-compose.yml` 里写死了 MySQL 8.0 + utf8mb4 + 时区 + 密码。任何人拿到这个项目，运行出来的数据库环境**一模一样**——不会出现"我电脑上跑得通，你电脑上报错"的情况。

3. **数据不丢失**  
   Docker 的 `volumes`（数据卷）会把 MySQL 的数据文件保存在你的硬盘上。即使删掉容器、重启电脑，数据还在。删除容器 ≠ 删除数据。

4. **一键部署**  
   `docker compose up -d` 一条命令 = MySQL 启动完成。而 `docker compose down` = 停止容器。比手动管理 MySQL 服务简单得多。

5. **SQL 自动初始化**  
   我们把 `sql/` 目录挂载到容器的 `/docker-entrypoint-initdb.d/`。MySQL 容器**第一次启动**时，会自动执行里面的 `.sql` 文件——建表、导入数据全部自动化。

### 关键概念速览

| 概念 | 通俗解释 |
|------|----------|
| **Image（镜像）** | 一个"软件安装包模板"，比如 `mysql:8.0` 就是一个装好 MySQL 8.0 的模板 |
| **Container（容器）** | 镜像"跑起来"之后的实例，就是你的数据库正在运行的那个进程 |
| **docker-compose.yml** | "部署说明书"，定义了用什么镜像、开什么端口、设什么密码 |
| **Volume（数据卷）** | 容器和宿主机之间的"共享文件夹"，让数据持久化保存 |
| **Port Mapping** | `3306:3306` 意思是把容器的 3306 端口映射到你的 localhost:3306 |

### 常用命令

```bash
docker compose up -d          # 启动容器（后台运行）
docker compose down           # 停止并删除容器
docker compose ps             # 查看容器状态
docker compose logs mysql     # 查看 MySQL 日志
docker exec -it ene_dc_monitor_mysql bash   # 进入容器内部
```

---

## 📝 SQL 脚本说明

| 文件 | 执行时机 | 幂等 | 说明 |
|------|----------|------|------|
| `01_create_tables.sql` | 容器首次启动（自动） | ✅ (DROP IF EXISTS) | 建库 + 建4张明细表 + 建索引 |
| `02_import_data.sql` | 容器首次启动（自动） | ✅ (TRUNCATE) | LOAD DATA 导入 .dat 文件 |
| `03_clean_data.sql` | 手动 / setup.sh | 可重复执行 | 时间转换 + 磁盘名提取 + 异常检测 |
| `04_statistics.sql` | 手动（查看用） | 只读 | 16个统计分析查询（KPI/趋势/排名/分布/异常） |
| `05_result_tables.sql` | 手动 / setup.sh | ✅ (DROP IF EXISTS) | 创建9张结果表 + 填充聚合数据 |

---

## 🖥️ 前端对接建议

Vue 项目创建独立的 `ene-dashboard` 目录，通过 Axios 调用后端 API：

```javascript
// 示例：获取 CPU 趋势数据
axios.get('/api/dashboard/cpu-trend').then(res => {
  // res.data → dashboard_cpu_hour 的 JSON 数组
  // 直接绑定到 ECharts dataset
})
```

推荐的技术栈：
- **Vue 3** + **ECharts 5** + **Axios**
- **Vite** 构建
- 后端可选：Node.js/Express 或 Python/Flask，封装 MySQL 查询为 RESTful API

---

## 📚 文档索引

- [数据字典](doc/数据字典.md) — 4个原始文件的字段、类型、关联关系
- [大屏指标设计文档](doc/大屏指标设计文档.md) — 大屏布局、指标清单、告警阈值、API 建议
- [原始需求](doc/数据加工提示词.txt) — 老师提供的完整任务说明

---

## 📌 开发笔记

- 原始时间戳为**毫秒**级，转换需 `/1000` 后用 `FROM_UNIXTIME()`
- `pref_tsar` 数据每小时一条，**168小时 = 6月30日 ~ 7月6日**共7天
- `disk_tsar` 为**稀疏采样**，每个时间点仅一条随机主机/指标记录
- 所有结果表设计为**预聚合**，避免前端直查大数据量事实表
- 告警阈值可在 `05_result_tables.sql` 中按需调整

---

## 📄 License

本项目为课程学习项目。
