# API 接口文档 — 数据中心运行监控大屏

> 后端技术栈：Node.js + Express + mysql2  
> 基础地址：`http://localhost:8080`  
> 所有接口均为 `GET` 请求，返回 JSON

---

## 启动与停止

```bash
# 1. 确保 MySQL 容器已启动
docker ps | grep ene_dc_monitor_mysql

# 2. 启动 API 服务
cd backend
npm install        # 首次运行
npm start          # 或 npm run dev（文件变更自动重启）

# 服务地址：http://localhost:8080
# 健康检查：http://localhost:8080/
```

---

## 接口清单

| # | 接口 | 查询表 | 返回条数 |
|---|------|--------|----------|
| 1 | `GET /api/kpi` | `dashboard_kpi_summary` | 12 |
| 2 | `GET /api/cpu/hour` | `dashboard_cpu_hour` | 168 |
| 3 | `GET /api/memory/hour` | `dashboard_mem_hour` | 168 |
| 4 | `GET /api/network/hour` | `dashboard_net_hour` | 168 |
| 5 | `GET /api/load/hour` | `dashboard_load_hour` | 168 |
| 6 | `GET /api/disk/hour` | `dashboard_disk_hour` | 1000 |
| 7 | `GET /api/hosts/rank?type=cpu&top=10` | `dashboard_host_rank` | 可配置 |
| 8 | `GET /api/rooms` | `dashboard_room_summary` | 5 |
| 9 | `GET /api/alerts` | `dashboard_alert_detail` | 动态 |

---

## 1. GET /api/kpi — 首页 KPI 卡片

**返回格式：**

```json
{
  "success": true,
  "count": 12,
  "data": [
    {
      "kpi_name": "cpu_usage",
      "kpi_label": "CPU综合使用率",
      "kpi_value": 43.18,
      "kpi_unit": "%",
      "kpi_max": 94.54,
      "kpi_min": 5.84,
      "data_range": "1h",
      "stat_time": "2026-07-09T05:07:22.000Z"
    },
    {
      "kpi_name": "cpu_usage",
      "kpi_label": "CPU综合使用率",
      "kpi_value": 43.2,
      "kpi_unit": "%",
      "kpi_max": 94.54,
      "kpi_min": 5.84,
      "data_range": "24h",
      "stat_time": "2026-07-09T05:07:22.000Z"
    }
  ]
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/kpi
```

---

## 2. GET /api/cpu/hour — CPU 24h 趋势

**返回格式（data 数组中单条）：**

```json
{
  "ts_date": "2026-07-01",
  "ts_hour": 0,
  "cpu_user_avg": 23.50,
  "cpu_sys_avg": 14.73,
  "cpu_wait_avg": 3.63,
  "cpu_usage_avg": 35.26,
  "cpu_idle_avg": 64.74,
  "sample_count": 20
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/cpu/hour
```

---

## 3. GET /api/memory/hour — 内存 24h 趋势

**返回格式（data 数组中单条）：**

```json
{
  "ts_date": "2026-07-01",
  "ts_hour": 0,
  "mem_used_avg": 64911,
  "mem_free_avg": 93421,
  "mem_buff_avg": 51646,
  "mem_cache_avg": 39807,
  "mem_swap_avg": 48968,
  "sample_count": 20
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/memory/hour
```

---

## 4. GET /api/network/hour — 网络流量趋势

**返回格式（data 数组中单条）：**

```json
{
  "ts_date": "2026-07-01",
  "ts_hour": 0,
  "net_in_avg": 409.72,
  "net_out_avg": 389.39,
  "net_in_peak": 880.26,
  "net_out_peak": 920.09,
  "pkt_in_avg": 58132,
  "pkt_out_avg": 59182,
  "sample_count": 20
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/network/hour
```

---

## 5. GET /api/load/hour — 系统负载趋势

**返回格式（data 数组中单条）：**

```json
{
  "ts_date": "2026-07-01",
  "ts_hour": 0,
  "load1_avg": 10.12,
  "load5_avg": 10.68,
  "load15_avg": 10.12,
  "sample_count": 20
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/load/hour
```

---

## 6. GET /api/disk/hour — 磁盘 IO 趋势

**返回格式（data 数组中单条）：**

```json
{
  "ts_date": "2026-07-01",
  "ts_hour": 0,
  "disk_read_avg": 141179,
  "disk_write_avg": 290346,
  "disk_util_avg": 47.34,
  "disk_latency_avg": 24.45,
  "sample_count": 2
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/disk/hour
```

---

## 7. GET /api/hosts/rank — 主机性能排名

**查询参数：**

| 参数 | 默认值 | 可选值 | 说明 |
|------|--------|--------|------|
| `type` | `cpu` | `cpu` / `memory` / `disk` | 排名维度 |
| `top` | `10` | 任意正整数 | 返回前 N 条 |

**返回格式：**

```json
{
  "success": true,
  "count": 5,
  "params": { "type": "cpu", "top": 5 },
  "data": [
    {
      "rank_type": "cpu",
      "host_id": "host018",
      "hostname": "server-018.hismartlab.cn",
      "room": "D机房",
      "avg_value": 50.85,
      "max_value": 96.57,
      "rank_position": 1,
      "stat_time": "2026-07-09T05:07:22.000Z"
    }
  ]
}
```

**curl 测试：**

```bash
# CPU 排名 TOP 5
curl "http://localhost:8080/api/hosts/rank?type=cpu&top=5"

# 内存排名 TOP 10
curl "http://localhost:8080/api/hosts/rank?type=memory&top=10"

# 磁盘排名 TOP 10
curl "http://localhost:8080/api/hosts/rank?type=disk&top=10"
```

---

## 8. GET /api/rooms — 机房分布统计

**返回格式：**

```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "room": "A机房",
      "host_count": 7,
      "host_pct": 35.0,
      "cpu_avg": 40.78,
      "mem_avg_mb": 74403,
      "stat_time": "2026-07-09T05:07:23.000Z"
    }
  ]
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/rooms
```

---

## 9. GET /api/alerts — 异常告警

**返回格式：**

```json
{
  "success": true,
  "count": 3,
  "data": [
    {
      "alert_type": "cpu",
      "host_id": "host006",
      "hostname": "server-006.hismartlab.cn",
      "room": "E机房",
      "current_value": 65.46,
      "threshold_value": 60,
      "alert_level": "WARNING",
      "last_check_time": "2026-07-07T15:00:00.000Z",
      "stat_time": "2026-07-09T05:07:23.000Z"
    }
  ]
}
```

**curl 测试：**

```bash
curl http://localhost:8080/api/alerts
```

---

## 浏览器访问方式

在浏览器地址栏直接输入以下 URL 即可看到 JSON 数据：

- `http://localhost:8080/` — API 服务列表
- `http://localhost:8080/api/kpi`
- `http://localhost:8080/api/cpu/hour`
- `http://localhost:8080/api/hosts/rank?type=memory&top=10`

也可以安装 JSON 格式化插件（如 JSON Viewer）让显示更美观。

---

## 常见错误排查

| 现象 | 可能原因 | 解决方法 |
|------|----------|----------|
| `ECONNREFUSED` | API 服务未启动 | `cd backend && npm start` |
| `MySQL 连接失败` | Docker 容器未启动 | `cd docker && docker compose up -d` |
| `EACCES 0.0.0.0:8080` | 端口被占用 | 修改 `server.js` 中的 `PORT` |
| 返回空数据 `[]` | 结果表未生成 | 执行 `sql/05_result_tables.sql` |
| 中文乱码 | 终端编码问题 | 浏览器访问正常，curl 加 `Accept-Charset` |
