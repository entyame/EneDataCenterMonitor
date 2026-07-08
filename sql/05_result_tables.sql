-- ============================================================
-- 05_result_tables.sql
-- 数据中心运行监控大屏 — 前端数据服务层（结果表）
-- ============================================================
-- 设计原则：
--   1. 不让前端直接查询原始事实表
--   2. 预聚合为小时粒度，减少前端查询压力
--   3. 每张表对应一个明确的大屏组件
--   4. 表名以 dashboard_ 前缀区分
--   5. 可通过定时任务（cron）增量刷新
-- ============================================================

USE ene_datacenter;

-- ============================================================
-- 1. dashboard_kpi_summary — 首页KPI汇总
-- 对应大屏组件：顶部5个数字卡片（CPU/内存/网络/磁盘/服务器数）
-- 刷新策略：每小时全量刷新
-- ============================================================
DROP TABLE IF EXISTS dashboard_kpi_summary;
CREATE TABLE dashboard_kpi_summary (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    kpi_name        VARCHAR(40)   NOT NULL COMMENT '指标名称，如 cpu_usage',
    kpi_label       VARCHAR(60)   NOT NULL COMMENT '中文标签，如 CPU平均使用率',
    kpi_value       DOUBLE        DEFAULT NULL COMMENT '指标值',
    kpi_unit        VARCHAR(20)   DEFAULT NULL COMMENT '单位，如 %、MB/s',
    kpi_max         DOUBLE        DEFAULT NULL COMMENT '周期内最大值',
    kpi_min         DOUBLE        DEFAULT NULL COMMENT '周期内最小值',
    stat_time       DATETIME      NOT NULL COMMENT '统计时间',
    data_range      VARCHAR(20)   NOT NULL COMMENT '数据范围：1h / 24h',
    UNIQUE KEY uk_kpi_range (kpi_name, data_range)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='首页KPI汇总表 — 供大屏数字卡片使用';

-- 填充数据：最近1小时KPI
INSERT INTO dashboard_kpi_summary (kpi_name, kpi_label, kpi_value, kpi_unit, kpi_max, kpi_min, stat_time, data_range)
SELECT 'cpu_usage',   'CPU综合使用率', ROUND(AVG(value), 2),     '%',    ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '1h'
FROM fact_pref_tsar WHERE mod_id = 'cpu_usage'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
UNION ALL
SELECT 'mem_used',    '内存使用量',     ROUND(AVG(value), 0),     'MB',   ROUND(MAX(value), 0), ROUND(MIN(value), 0), NOW(), '1h'
FROM fact_pref_tsar WHERE mod_id = 'mem_used'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
UNION ALL
SELECT 'net_in',      '网络入站带宽',   ROUND(AVG(value), 2),     'MB/s', ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '1h'
FROM fact_pref_tsar WHERE mod_id = 'net_in'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
UNION ALL
SELECT 'net_out',     '网络出站带宽',   ROUND(AVG(value), 2),     'MB/s', ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '1h'
FROM fact_pref_tsar WHERE mod_id = 'net_out'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
UNION ALL
SELECT 'disk_util',   '磁盘平均使用率', ROUND(AVG(value), 2),     '%',    ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '1h'
FROM fact_disk_tsar WHERE tag = 'disk_util_percent'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_disk_tsar)
UNION ALL
SELECT 'host_online', '在线服务器数',   COUNT(DISTINCT host_id), '台',   NULL,                 NULL,                 NOW(), '1h'
FROM fact_pref_tsar
WHERE ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar);

-- 填充：最近24小时（用于对比）
INSERT INTO dashboard_kpi_summary (kpi_name, kpi_label, kpi_value, kpi_unit, kpi_max, kpi_min, stat_time, data_range)
SELECT 'cpu_usage',   'CPU综合使用率', ROUND(AVG(value), 2),     '%',    ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '24h'
FROM fact_pref_tsar WHERE mod_id = 'cpu_usage'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
UNION ALL
SELECT 'mem_used',    '内存使用量',     ROUND(AVG(value), 0),     'MB',   ROUND(MAX(value), 0), ROUND(MIN(value), 0), NOW(), '24h'
FROM fact_pref_tsar WHERE mod_id = 'mem_used'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
UNION ALL
SELECT 'net_in',      '网络入站带宽',   ROUND(AVG(value), 2),     'MB/s', ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '24h'
FROM fact_pref_tsar WHERE mod_id = 'net_in'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
UNION ALL
SELECT 'net_out',     '网络出站带宽',   ROUND(AVG(value), 2),     'MB/s', ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '24h'
FROM fact_pref_tsar WHERE mod_id = 'net_out'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
UNION ALL
SELECT 'disk_util',   '磁盘平均使用率', ROUND(AVG(value), 2),     '%',    ROUND(MAX(value), 2), ROUND(MIN(value), 2), NOW(), '24h'
FROM fact_disk_tsar WHERE tag = 'disk_util_percent'
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_disk_tsar)
UNION ALL
SELECT 'host_online', '在线服务器数',   COUNT(DISTINCT host_id), '台',   NULL,                 NULL,                 NOW(), '24h'
FROM fact_pref_tsar
WHERE ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar);


-- ============================================================
-- 2. dashboard_cpu_hour — CPU 每小时聚合趋势
-- 对应大屏组件：CPU趋势折线图（多条线：user/sys/wait/usage/idle）
-- 字段：date, hour, cpu_user_avg, cpu_sys_avg, cpu_wait_avg, cpu_usage_avg, cpu_idle_avg
-- 示例数据：2026-07-06 | 14 | 35.21 | 12.50 | 5.33 | 45.67 | 54.33
-- ============================================================
DROP TABLE IF EXISTS dashboard_cpu_hour;
CREATE TABLE dashboard_cpu_hour (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    ts_date         DATE          NOT NULL COMMENT '日期',
    ts_hour         TINYINT       NOT NULL COMMENT '小时 (0-23)',
    cpu_user_avg    DECIMAL(6,2)  DEFAULT NULL COMMENT '用户态CPU平均使用率',
    cpu_sys_avg     DECIMAL(6,2)  DEFAULT NULL COMMENT '系统态CPU平均使用率',
    cpu_wait_avg    DECIMAL(6,2)  DEFAULT NULL COMMENT 'IO等待CPU平均使用率',
    cpu_usage_avg   DECIMAL(6,2)  DEFAULT NULL COMMENT 'CPU综合使用率平均值',
    cpu_idle_avg    DECIMAL(6,2)  DEFAULT NULL COMMENT 'CPU空闲率平均值',
    sample_count    INT           DEFAULT 0  COMMENT '该时段样本数',
    UNIQUE KEY uk_date_hour (ts_date, ts_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CPU每小时聚合趋势 — 供折线图使用';

INSERT INTO dashboard_cpu_hour (ts_date, ts_hour, cpu_user_avg, cpu_sys_avg, cpu_wait_avg, cpu_usage_avg, cpu_idle_avg, sample_count)
SELECT
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_user'  THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'cpu_sys'   THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'cpu_wait'  THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'cpu_usage' THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'cpu_idle'  THEN value END), 2),
    COUNT(DISTINCT host_id)
FROM fact_pref_tsar
WHERE tag = 'cpu_percent'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- 3. dashboard_mem_hour — 内存每小时聚合趋势
-- 对应大屏组件：内存堆叠面积图（used/free/buff/cache/swap）
-- 字段：date, hour, mem_used_avg, mem_free_avg, mem_buff_avg, mem_cache_avg, mem_swap_avg
-- 示例数据：2026-07-06 | 14 | 90559 | 91864 | 73069 | 63200 | 59171
-- ============================================================
DROP TABLE IF EXISTS dashboard_mem_hour;
CREATE TABLE dashboard_mem_hour (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    ts_date         DATE          NOT NULL COMMENT '日期',
    ts_hour         TINYINT       NOT NULL COMMENT '小时 (0-23)',
    mem_used_avg    DECIMAL(10,0) DEFAULT NULL COMMENT '已用内存平均值 (MB)',
    mem_free_avg    DECIMAL(10,0) DEFAULT NULL COMMENT '空闲内存平均值 (MB)',
    mem_buff_avg    DECIMAL(10,0) DEFAULT NULL COMMENT '缓冲区平均值 (MB)',
    mem_cache_avg   DECIMAL(10,0) DEFAULT NULL COMMENT '缓存平均值 (MB)',
    mem_swap_avg    DECIMAL(10,0) DEFAULT NULL COMMENT '交换区平均值 (MB)',
    sample_count    INT           DEFAULT 0  COMMENT '该时段样本数',
    UNIQUE KEY uk_date_hour (ts_date, ts_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='内存每小时聚合 — 供堆叠面积图使用';

INSERT INTO dashboard_mem_hour (ts_date, ts_hour, mem_used_avg, mem_free_avg, mem_buff_avg, mem_cache_avg, mem_swap_avg, sample_count)
SELECT
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'mem_used'  THEN value END), 0),
    ROUND(AVG(CASE WHEN mod_id = 'mem_free'  THEN value END), 0),
    ROUND(AVG(CASE WHEN mod_id = 'mem_buff'  THEN value END), 0),
    ROUND(AVG(CASE WHEN mod_id = 'mem_cache' THEN value END), 0),
    ROUND(AVG(CASE WHEN mod_id = 'mem_swap'  THEN value END), 0),
    COUNT(DISTINCT host_id)
FROM fact_pref_tsar
WHERE tag = 'mem_metric'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- 4. dashboard_net_hour — 网络流量每小时聚合
-- 对应大屏组件：网络流量双轴折线图（入站/出站带宽 + 数据包）
-- 字段：date, hour, net_in_avg, net_out_avg, net_in_peak, net_out_peak, pkt_in_avg, pkt_out_avg
-- 示例数据：2026-07-06 | 14 | 824.81 | 302.42 | 950.00 | 450.00 | 79873 | 74249
-- ============================================================
DROP TABLE IF EXISTS dashboard_net_hour;
CREATE TABLE dashboard_net_hour (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    ts_date         DATE          NOT NULL COMMENT '日期',
    ts_hour         TINYINT       NOT NULL COMMENT '小时 (0-23)',
    net_in_avg      DECIMAL(10,2) DEFAULT NULL COMMENT '入站带宽均值 (MB/s)',
    net_out_avg     DECIMAL(10,2) DEFAULT NULL COMMENT '出站带宽均值 (MB/s)',
    net_in_peak     DECIMAL(10,2) DEFAULT NULL COMMENT '入站带宽峰值 (MB/s)',
    net_out_peak    DECIMAL(10,2) DEFAULT NULL COMMENT '出站带宽峰值 (MB/s)',
    pkt_in_avg      DECIMAL(10,0) DEFAULT NULL COMMENT '入站数据包均值 (pkt/s)',
    pkt_out_avg     DECIMAL(10,0) DEFAULT NULL COMMENT '出站数据包均值 (pkt/s)',
    sample_count    INT           DEFAULT 0  COMMENT '该时段样本数',
    UNIQUE KEY uk_date_hour (ts_date, ts_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='网络每小时聚合 — 供双轴折线图使用';

INSERT INTO dashboard_net_hour (ts_date, ts_hour, net_in_avg, net_out_avg, net_in_peak, net_out_peak, pkt_in_avg, pkt_out_avg, sample_count)
SELECT
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'net_in'  THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'net_out' THEN value END), 2),
    ROUND(MAX(CASE WHEN mod_id = 'net_in'  THEN value END), 2),
    ROUND(MAX(CASE WHEN mod_id = 'net_out' THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'net_pktin'  THEN value END), 0),
    ROUND(AVG(CASE WHEN mod_id = 'net_pktout' THEN value END), 0),
    COUNT(DISTINCT host_id)
FROM fact_pref_tsar
WHERE tag IN ('net_speed_mb', 'net_packets')
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- 5. dashboard_load_hour — 系统负载每小时聚合
-- 对应大屏组件：负载折线图（load1/load5/load15三条线）
-- 示例数据：2026-07-06 | 14 | 5.41 | 12.43 | 14.27
-- ============================================================
DROP TABLE IF EXISTS dashboard_load_hour;
CREATE TABLE dashboard_load_hour (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    ts_date         DATE          NOT NULL COMMENT '日期',
    ts_hour         TINYINT       NOT NULL COMMENT '小时 (0-23)',
    load1_avg       DECIMAL(6,2)  DEFAULT NULL COMMENT '1分钟平均负载',
    load5_avg       DECIMAL(6,2)  DEFAULT NULL COMMENT '5分钟平均负载',
    load15_avg      DECIMAL(6,2)  DEFAULT NULL COMMENT '15分钟平均负载',
    sample_count    INT           DEFAULT 0  COMMENT '该时段样本数',
    UNIQUE KEY uk_date_hour (ts_date, ts_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统负载每小时聚合 — 供折线图使用';

INSERT INTO dashboard_load_hour (ts_date, ts_hour, load1_avg, load5_avg, load15_avg, sample_count)
SELECT
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'load1'  THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'load5'  THEN value END), 2),
    ROUND(AVG(CASE WHEN mod_id = 'load15' THEN value END), 2),
    COUNT(DISTINCT host_id)
FROM fact_pref_tsar
WHERE tag = 'load_average'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- 6. dashboard_disk_hour — 磁盘性能每小时聚合
-- 对应大屏组件：磁盘趋势折线图（读/写扇区 + 使用率 + 延迟）
-- 示例数据：2026-07-06 | 14 | 280043 | 350000 | 88.47 | 20.12
-- ============================================================
DROP TABLE IF EXISTS dashboard_disk_hour;
CREATE TABLE dashboard_disk_hour (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    ts_date         DATE          NOT NULL COMMENT '日期',
    ts_hour         TINYINT       NOT NULL COMMENT '小时 (0-23)',
    disk_read_avg   DECIMAL(12,0) DEFAULT NULL COMMENT '平均读扇区数 (sectors/s)',
    disk_write_avg  DECIMAL(12,0) DEFAULT NULL COMMENT '平均写扇区数 (sectors/s)',
    disk_util_avg   DECIMAL(6,2)  DEFAULT NULL COMMENT '磁盘使用率均值 (%)',
    disk_latency_avg DECIMAL(6,2) DEFAULT NULL COMMENT 'IO延迟均值 (ms)',
    sample_count    INT           DEFAULT 0  COMMENT '该时段样本数',
    UNIQUE KEY uk_date_hour (ts_date, ts_hour)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='磁盘性能每小时聚合 — 供折线图使用';

INSERT INTO dashboard_disk_hour (ts_date, ts_hour, disk_read_avg, disk_write_avg, disk_util_avg, disk_latency_avg, sample_count)
SELECT
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN tag = 'disk_rw_sectors' AND mod_id LIKE '%_read'  THEN value END), 0),
    ROUND(AVG(CASE WHEN tag = 'disk_rw_sectors' AND mod_id LIKE '%_write' THEN value END), 0),
    ROUND(AVG(CASE WHEN tag = 'disk_util_percent' THEN value END), 2),
    ROUND(AVG(CASE WHEN tag = 'disk_latency_ms'   THEN value END), 2),
    COUNT(*)
FROM fact_disk_tsar
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- 7. dashboard_host_rank — 主机排名（CPU/内存/磁盘 TOP N）
-- 对应大屏组件：TOP10横向柱状图
-- 字段：rank_type, host_id, hostname, room, avg_value, max_value, rank_position
-- 示例数据：cpu | host003 | server-003.hismartlab.cn | E机房 | 87.32 | 95.10 | 1
-- ============================================================
DROP TABLE IF EXISTS dashboard_host_rank;
CREATE TABLE dashboard_host_rank (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    rank_type       VARCHAR(20)   NOT NULL COMMENT '排名类型：cpu / memory / disk',
    host_id         VARCHAR(20)   NOT NULL COMMENT '主机ID',
    hostname        VARCHAR(100)  DEFAULT NULL COMMENT '主机域名',
    room            VARCHAR(50)   DEFAULT NULL COMMENT '机房',
    avg_value       DECIMAL(10,2) NOT NULL COMMENT '平均值',
    max_value       DECIMAL(10,2) DEFAULT NULL COMMENT '最大值',
    rank_position   INT           NOT NULL COMMENT '排名 (1-N)',
    stat_time       DATETIME      NOT NULL COMMENT '统计时间',
    UNIQUE KEY uk_rank (rank_type, host_id),
    INDEX idx_rank_pos (rank_type, rank_position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='主机排名表 — 供TOP10柱状图使用';

-- CPU TOP20（全量排名）
INSERT INTO dashboard_host_rank (rank_type, host_id, hostname, room, avg_value, max_value, rank_position, stat_time)
SELECT 'cpu', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 2), ROUND(MAX(f.value), 2),
       RANK() OVER (ORDER BY AVG(f.value) DESC), NOW()
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'cpu_usage'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1;

-- 内存 TOP20
INSERT INTO dashboard_host_rank (rank_type, host_id, hostname, room, avg_value, max_value, rank_position, stat_time)
SELECT 'memory', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 0), ROUND(MAX(f.value), 0),
       RANK() OVER (ORDER BY AVG(f.value) DESC), NOW()
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'mem_used'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1;

-- 磁盘 TOP20
INSERT INTO dashboard_host_rank (rank_type, host_id, hostname, room, avg_value, max_value, rank_position, stat_time)
SELECT 'disk', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 2), ROUND(MAX(f.value), 2),
       RANK() OVER (ORDER BY AVG(f.value) DESC), NOW()
FROM fact_disk_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.tag = 'disk_util_percent'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_disk_tsar)
GROUP BY f.host_id, h.hostname, h.location1;


-- ============================================================
-- 8. dashboard_room_summary — 机房汇总
-- 对应大屏组件：机房分布饼图 + 机房维度柱状图
-- 示例数据：A机房 | 4 | 20.0 | 45.32 | 85000
-- ============================================================
DROP TABLE IF EXISTS dashboard_room_summary;
CREATE TABLE dashboard_room_summary (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    room            VARCHAR(50)   NOT NULL COMMENT '机房名称',
    host_count      INT           NOT NULL COMMENT '服务器数量',
    host_pct        DECIMAL(5,1)  DEFAULT NULL COMMENT '占比 (%)',
    cpu_avg         DECIMAL(6,2)  DEFAULT NULL COMMENT '该机房CPU平均使用率',
    mem_avg_mb      DECIMAL(10,0) DEFAULT NULL COMMENT '该机房内存平均使用量 (MB)',
    stat_time       DATETIME      NOT NULL COMMENT '统计时间',
    UNIQUE KEY uk_room (room)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='机房汇总表 — 供饼图和柱状图使用';

INSERT INTO dashboard_room_summary (room, host_count, host_pct, cpu_avg, mem_avg_mb, stat_time)
SELECT
    h.location1,
    COUNT(DISTINCT h.host_id),
    ROUND(COUNT(DISTINCT h.host_id) * 100.0 / (SELECT COUNT(*) FROM dim_host), 1),
    ROUND(AVG(cpu.value), 2),
    ROUND(AVG(mem.value), 0),
    NOW()
FROM dim_host h
LEFT JOIN fact_pref_tsar cpu ON h.host_id = cpu.host_id
    AND cpu.mod_id = 'cpu_usage'
    AND cpu.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
LEFT JOIN fact_pref_tsar mem ON h.host_id = mem.host_id
    AND mem.mod_id = 'mem_used'
    AND mem.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
GROUP BY h.location1;


-- ============================================================
-- 9. dashboard_alert_detail — 告警明细
-- 对应大屏组件：实时告警列表（滚动表格 / 红色高亮）
-- 示例数据：cpu | host003 | server-003 | E机房 | 92.5 | 80 | CRITICAL
-- ============================================================
DROP TABLE IF EXISTS dashboard_alert_detail;
CREATE TABLE dashboard_alert_detail (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    alert_type      VARCHAR(20)   NOT NULL COMMENT '告警类型：cpu / memory / disk',
    host_id         VARCHAR(20)   NOT NULL COMMENT '主机ID',
    hostname        VARCHAR(100)  DEFAULT NULL COMMENT '主机域名',
    room            VARCHAR(50)   DEFAULT NULL COMMENT '机房',
    current_value   DECIMAL(10,2) NOT NULL COMMENT '当前值',
    threshold_value DECIMAL(10,2) NOT NULL COMMENT '阈值',
    alert_level     VARCHAR(20)   NOT NULL COMMENT '告警级别：CRITICAL / WARNING',
    last_check_time DATETIME      NOT NULL COMMENT '最后检查时间',
    stat_time       DATETIME      NOT NULL COMMENT '统计时间',
    INDEX idx_alert_type (alert_type),
    INDEX idx_alert_level (alert_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警明细表 — 供实时告警列表使用';

-- CPU 超过 80% → CRITICAL
INSERT INTO dashboard_alert_detail (alert_type, host_id, hostname, room, current_value, threshold_value, alert_level, last_check_time, stat_time)
SELECT 'cpu', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 2), 80, 'CRITICAL',
       MAX(f.ts_datetime), NOW()
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'cpu_usage'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
HAVING AVG(f.value) > 80;

-- CPU 60-80% → WARNING
INSERT INTO dashboard_alert_detail (alert_type, host_id, hostname, room, current_value, threshold_value, alert_level, last_check_time, stat_time)
SELECT 'cpu', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 2), 60, 'WARNING',
       MAX(f.ts_datetime), NOW()
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'cpu_usage'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
HAVING AVG(f.value) BETWEEN 60 AND 80;

-- 磁盘使用率 > 70% → WARNING
INSERT INTO dashboard_alert_detail (alert_type, host_id, hostname, room, current_value, threshold_value, alert_level, last_check_time, stat_time)
SELECT 'disk', f.host_id, h.hostname, h.location1,
       ROUND(AVG(f.value), 2), 70, 'WARNING',
       MAX(f.ts_datetime), NOW()
FROM fact_disk_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.tag = 'disk_util_percent'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_disk_tsar)
GROUP BY f.host_id, h.hostname, h.location1
HAVING AVG(f.value) > 70;


-- ============================================================
-- 10. 最终验证：汇总所有结果表行数
-- ============================================================
SELECT 'dashboard_kpi_summary'   AS result_table, COUNT(*) AS row_count FROM dashboard_kpi_summary
UNION ALL
SELECT 'dashboard_cpu_hour',     COUNT(*) FROM dashboard_cpu_hour
UNION ALL
SELECT 'dashboard_mem_hour',     COUNT(*) FROM dashboard_mem_hour
UNION ALL
SELECT 'dashboard_net_hour',     COUNT(*) FROM dashboard_net_hour
UNION ALL
SELECT 'dashboard_load_hour',    COUNT(*) FROM dashboard_load_hour
UNION ALL
SELECT 'dashboard_disk_hour',    COUNT(*) FROM dashboard_disk_hour
UNION ALL
SELECT 'dashboard_host_rank',    COUNT(*) FROM dashboard_host_rank
UNION ALL
SELECT 'dashboard_room_summary', COUNT(*) FROM dashboard_room_summary
UNION ALL
SELECT 'dashboard_alert_detail', COUNT(*) FROM dashboard_alert_detail;
