-- ============================================================
-- 04_statistics.sql
-- 数据中心运行监控大屏 — 统计分析 SQL
-- ============================================================
-- 每个查询标注：作用、输入表、输出字段、前端图表用途
-- ============================================================

USE ene_datacenter;

-- ============================================================
-- A. 首页核心指标 (KPI — Key Performance Indicators)
-- ============================================================

-- ----------------------------------------------------------
-- A1. 概览：服务器总数 / 在线服务器数 / 指标数据条数
-- 作用：大屏顶部数字卡片
-- 输入：dim_host, fact_pref_tsar
-- 输出：total_hosts, online_hosts, total_metrics, latest_time
-- 前端：StatCard 数字卡片组件
-- ----------------------------------------------------------
SELECT
    'KPI-概览' AS query_label,
    COUNT(DISTINCT h.host_id)                                                    AS total_hosts,
    COUNT(DISTINCT CASE WHEN f.host_id IS NOT NULL THEN h.host_id END)           AS online_hosts,
    COUNT(DISTINCT f.mod_id)                                                     AS metric_types,
    MAX(f.ts_datetime)                                                           AS latest_data_time,
    COUNT(DISTINCT f.ts_date)                                                    AS total_days
FROM dim_host h
LEFT JOIN fact_pref_tsar f ON h.host_id = f.host_id;


-- ----------------------------------------------------------
-- A2. 首页KPI：CPU平均使用率（最近一小时、最近一天）
-- 作用：大屏 CPU 仪表盘
-- 输入：fact_pref_tsar
-- 输出：cpu_avg_1h, cpu_max_1h, cpu_avg_24h, cpu_max_24h
-- 前端：Gauge / 仪表盘组件
-- ----------------------------------------------------------
SELECT
    'KPI-CPU' AS query_label,
    ROUND(AVG(CASE WHEN ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
                   THEN value END), 2)                                           AS cpu_avg_1h,
    ROUND(MAX(CASE WHEN ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
                   THEN value END), 2)                                           AS cpu_max_1h,
    ROUND(AVG(CASE WHEN ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
                   THEN value END), 2)                                           AS cpu_avg_24h,
    ROUND(MAX(CASE WHEN ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
                   THEN value END), 2)                                           AS cpu_max_24h
FROM fact_pref_tsar
WHERE mod_id = 'cpu_usage';


-- ----------------------------------------------------------
-- A3. 首页KPI：内存平均使用率（总内存 = used + free + buff + cache）
-- 作用：大屏内存仪表盘
-- 输入：fact_pref_tsar
-- 输出：mem_used_avg, mem_total_avg, mem_usage_pct
-- 前端：Gauge / 进度条组件
-- ----------------------------------------------------------
SELECT
    'KPI-内存' AS query_label,
    ROUND(AVG(used_val), 0)               AS mem_used_avg_mb,
    ROUND(AVG(total_val), 0)              AS mem_total_avg_mb,
    ROUND(AVG(used_val) / AVG(total_val) * 100, 2) AS mem_usage_pct
FROM (
    SELECT
        ts,
        host_id,
        MAX(CASE WHEN mod_id = 'mem_used'  THEN value END) AS used_val,
        SUM(CASE WHEN mod_id IN ('mem_free','mem_buff','mem_cache') THEN value END) AS non_used_val,
        MAX(CASE WHEN mod_id = 'mem_used'  THEN value END)
        + SUM(CASE WHEN mod_id IN ('mem_free','mem_buff','mem_cache') THEN value END) AS total_val
    FROM fact_pref_tsar
    WHERE mod_id IN ('mem_used', 'mem_free', 'mem_buff', 'mem_cache')
      AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
    GROUP BY ts, host_id
) t;


-- ----------------------------------------------------------
-- A4. 首页KPI：网络流量（最近一小时入站/出站总带宽）
-- 作用：大屏网络流量卡片
-- 输入：fact_pref_tsar
-- 输出：net_in_total_mbps, net_out_total_mbps
-- 前端：StatCard 双数字卡片
-- ----------------------------------------------------------
SELECT
    'KPI-网络' AS query_label,
    ROUND(AVG(CASE WHEN mod_id = 'net_in'  THEN value END), 2) AS net_in_avg_mbps,
    ROUND(MAX(CASE WHEN mod_id = 'net_in'  THEN value END), 2) AS net_in_peak_mbps,
    ROUND(AVG(CASE WHEN mod_id = 'net_out' THEN value END), 2) AS net_out_avg_mbps,
    ROUND(MAX(CASE WHEN mod_id = 'net_out' THEN value END), 2) AS net_out_peak_mbps
FROM fact_pref_tsar
WHERE mod_id IN ('net_in', 'net_out')
  AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar);


-- ----------------------------------------------------------
-- A5. 首页KPI：磁盘IO状态（所有磁盘平均使用率）
-- 作用：大屏磁盘健康状态卡片
-- 输入：fact_disk_tsar
-- 输出：disk_util_avg, disk_io_wait_avg_ms
-- 前端：StatCard
-- ----------------------------------------------------------
SELECT
    'KPI-磁盘' AS query_label,
    ROUND(AVG(CASE WHEN tag = 'disk_util_percent' THEN value END), 2) AS disk_util_avg_pct,
    ROUND(AVG(CASE WHEN tag = 'disk_latency_ms'  THEN value END), 2) AS disk_latency_avg_ms
FROM fact_disk_tsar
WHERE ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_disk_tsar);


-- ============================================================
-- B. 趋势分析（24小时时序）
-- ============================================================

-- ----------------------------------------------------------
-- B1. CPU 24小时变化趋势（每小时，所有主机平均）
-- 作用：折线图展示CPU使用率一天内的波动
-- 输入：fact_pref_tsar
-- 输出：ts_date, ts_hour, cpu_user_avg, cpu_sys_avg, cpu_usage_avg, cpu_idle_avg
-- 前端：多条折线图 (ECharts line)
-- ----------------------------------------------------------
SELECT
    '趋势-CPU' AS query_label,
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_user'  THEN value END), 2)  AS cpu_user_avg,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_sys'   THEN value END), 2)  AS cpu_sys_avg,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_wait'  THEN value END), 2)  AS cpu_wait_avg,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_usage' THEN value END), 2)  AS cpu_usage_avg,
    ROUND(AVG(CASE WHEN mod_id = 'cpu_idle'  THEN value END), 2)  AS cpu_idle_avg
FROM fact_pref_tsar
WHERE tag = 'cpu_percent'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ----------------------------------------------------------
-- B2. 内存 24小时变化趋势
-- 作用：折线图展示内存各分项随时间变化
-- 输入：fact_pref_tsar
-- 输出：ts_date, ts_hour, mem_used_avg, mem_free_avg, mem_buff_avg, mem_cache_avg
-- 前端：堆叠面积图 (ECharts area)
-- ----------------------------------------------------------
SELECT
    '趋势-内存' AS query_label,
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'mem_used'  THEN value END), 0) AS mem_used_avg_mb,
    ROUND(AVG(CASE WHEN mod_id = 'mem_free'  THEN value END), 0) AS mem_free_avg_mb,
    ROUND(AVG(CASE WHEN mod_id = 'mem_buff'  THEN value END), 0) AS mem_buff_avg_mb,
    ROUND(AVG(CASE WHEN mod_id = 'mem_cache' THEN value END), 0) AS mem_cache_avg_mb,
    ROUND(AVG(CASE WHEN mod_id = 'mem_swap'  THEN value END), 0) AS mem_swap_avg_mb
FROM fact_pref_tsar
WHERE tag = 'mem_metric'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ----------------------------------------------------------
-- B3. 网络流量 24小时变化趋势
-- 作用：折线图展示入站/出站带宽随时间变化
-- 输入：fact_pref_tsar
-- 输出：ts_date, ts_hour, net_in_avg, net_out_avg, net_in_max, net_out_max
-- 前端：双轴折线图 (ECharts line)
-- ----------------------------------------------------------
SELECT
    '趋势-网络' AS query_label,
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'net_in'  THEN value END), 2)  AS net_in_avg_mbps,
    ROUND(AVG(CASE WHEN mod_id = 'net_out' THEN value END), 2)  AS net_out_avg_mbps,
    ROUND(MAX(CASE WHEN mod_id = 'net_in'  THEN value END), 2)  AS net_in_peak_mbps,
    ROUND(MAX(CASE WHEN mod_id = 'net_out' THEN value END), 2)  AS net_out_peak_mbps,
    ROUND(AVG(CASE WHEN mod_id = 'net_pktin'  THEN value END), 0) AS pkt_in_avg,
    ROUND(AVG(CASE WHEN mod_id = 'net_pktout' THEN value END), 0) AS pkt_out_avg
FROM fact_pref_tsar
WHERE tag IN ('net_speed_mb', 'net_packets')
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ----------------------------------------------------------
-- B4. 系统负载 24小时趋势
-- 作用：折线图展示 load1/load5/load15 负载变化
-- 输入：fact_pref_tsar
-- 输出：ts_date, ts_hour, load1_avg, load5_avg, load15_avg
-- 前端：多条折线图 (ECharts line)
-- ----------------------------------------------------------
SELECT
    '趋势-负载' AS query_label,
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN mod_id = 'load1'  THEN value END), 2) AS load1_avg,
    ROUND(AVG(CASE WHEN mod_id = 'load5'  THEN value END), 2) AS load5_avg,
    ROUND(AVG(CASE WHEN mod_id = 'load15' THEN value END), 2) AS load15_avg
FROM fact_pref_tsar
WHERE tag = 'load_average'
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ----------------------------------------------------------
-- B5. 磁盘IO 24小时趋势（读写扇区数 + 使用率）
-- 作用：折线图展示磁盘读写和利用率趋势
-- 输入：fact_disk_tsar
-- 输出：ts_date, ts_hour, disk_read_avg, disk_write_avg, disk_util_avg
-- 前端：折线图 (ECharts line)
-- ----------------------------------------------------------
SELECT
    '趋势-磁盘' AS query_label,
    ts_date,
    ts_hour,
    ROUND(AVG(CASE WHEN tag = 'disk_rw_sectors' AND mod_id LIKE '%_read'  THEN value END), 0) AS disk_read_avg_sectors,
    ROUND(AVG(CASE WHEN tag = 'disk_rw_sectors' AND mod_id LIKE '%_write' THEN value END), 0) AS disk_write_avg_sectors,
    ROUND(AVG(CASE WHEN tag = 'disk_util_percent' THEN value END), 2)                   AS disk_util_avg_pct,
    ROUND(AVG(CASE WHEN tag = 'disk_latency_ms'   THEN value END), 2)                   AS disk_latency_avg_ms
FROM fact_disk_tsar
GROUP BY ts_date, ts_hour
ORDER BY ts_date, ts_hour;


-- ============================================================
-- C. 排名分析（TOP N）
-- ============================================================

-- ----------------------------------------------------------
-- C1. CPU使用率 TOP10 服务器（最近24小时平均）
-- 作用：横向柱状图展示CPU占用最高的服务器
-- 输入：fact_pref_tsar + dim_host
-- 输出：rank, host_id, hostname, cpu_avg, location1
-- 前端：横向柱状图 (ECharts bar)
-- ----------------------------------------------------------
SELECT
    '排名-CPU-TOP10' AS query_label,
    RANK() OVER (ORDER BY AVG(f.value) DESC)  AS ranking,
    f.host_id,
    h.hostname,
    h.location1                                AS room,
    ROUND(AVG(f.value), 2)                     AS cpu_avg_pct,
    ROUND(MAX(f.value), 2)                     AS cpu_max_pct,
    ROUND(MIN(f.value), 2)                     AS cpu_min_pct
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'cpu_usage'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
ORDER BY cpu_avg_pct DESC
LIMIT 10;


-- ----------------------------------------------------------
-- C2. 内存占用 TOP10 服务器（最近24小时平均）
-- 作用：横向柱状图展示内存占用最高
-- 输入：fact_pref_tsar + dim_host
-- 输出：rank, host_id, hostname, mem_used_avg, mem_usage_pct
-- 前端：横向柱状图 (ECharts bar)
-- ----------------------------------------------------------
SELECT
    '排名-内存-TOP10' AS query_label,
    RANK() OVER (ORDER BY AVG(f.value) DESC)  AS ranking,
    f.host_id,
    h.hostname,
    h.location1                                AS room,
    ROUND(AVG(f.value), 0)                     AS mem_used_avg_mb
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'mem_used'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
ORDER BY mem_used_avg_mb DESC
LIMIT 10;


-- ----------------------------------------------------------
-- C3. 磁盘IO最高 TOP10 服务器（最近24小时平均使用率）
-- 作用：横向柱状图展示磁盘最繁忙的服务器
-- 输入：fact_disk_tsar + dim_host
-- 输出：rank, host_id, hostname, disk_util_avg
-- 前端：横向柱状图 (ECharts bar)
-- ----------------------------------------------------------
SELECT
    '排名-磁盘-TOP10' AS query_label,
    RANK() OVER (ORDER BY AVG(f.value) DESC)  AS ranking,
    f.host_id,
    h.hostname,
    h.location1                                AS room,
    ROUND(AVG(f.value), 2)                     AS disk_util_avg_pct,
    ROUND(MAX(f.value), 2)                     AS disk_util_max_pct
FROM fact_disk_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.tag = 'disk_util_percent'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_disk_tsar)
GROUP BY f.host_id, h.hostname, h.location1
ORDER BY disk_util_avg_pct DESC
LIMIT 10;


-- ============================================================
-- D. 分布分析
-- ============================================================

-- ----------------------------------------------------------
-- D1. 各机房服务器数量分布
-- 作用：饼图展示不同数据中心的服务器占比
-- 输入：dim_host
-- 输出：location1, host_count
-- 前端：饼图 (ECharts pie)
-- ----------------------------------------------------------
SELECT
    '分布-机房' AS query_label,
    location1                                   AS room,
    COUNT(*)                                    AS host_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dim_host), 1) AS pct
FROM dim_host
GROUP BY location1
ORDER BY host_count DESC;


-- ----------------------------------------------------------
-- D2. 各指标类型的数据量分布（pref）
-- 作用：柱状图展示不同指标分组的数据条数
-- 输入：fact_pref_tsar
-- 输出：tag, record_count
-- 前端：柱状图 (ECharts bar) 或 旭日图
-- ----------------------------------------------------------
SELECT
    '分布-指标' AS query_label,
    tag                                         AS metric_group,
    COUNT(*)                                    AS record_count,
    COUNT(DISTINCT mod_id)                      AS metric_variants,
    ROUND(AVG(value), 2)                        AS avg_value
FROM fact_pref_tsar
GROUP BY tag
ORDER BY record_count DESC;


-- ----------------------------------------------------------
-- D3. 主机资源状态分布（CPU使用率分档）
-- 作用：展示各主机的CPU负载分级
-- 输入：fact_pref_tsar
-- 输出：host_id, cpu_level, host_count
-- 前端：堆叠柱状图 / 热力图
-- ----------------------------------------------------------
SELECT
    '分布-CPU分档' AS query_label,
    host_id,
    CASE
        WHEN avg_cpu < 30   THEN '低负载 (<30%)'
        WHEN avg_cpu < 60   THEN '中负载 (30-60%)'
        WHEN avg_cpu < 80   THEN '高负载 (60-80%)'
        ELSE                     '过载 (>80%)'
    END                                         AS cpu_level,
    COUNT(*)                                    AS sample_count
FROM (
    SELECT host_id,
           AVG(value) AS avg_cpu
    FROM fact_pref_tsar
    WHERE mod_id = 'cpu_usage'
      AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 DAY FROM fact_pref_tsar)
    GROUP BY host_id
) t
GROUP BY host_id, cpu_level
ORDER BY host_id;


-- ----------------------------------------------------------
-- D4. 各磁盘（sda~sde）平均利用率对比
-- 作用：柱状图对比5块磁盘的利用率差异
-- 输入：fact_disk_tsar
-- 输出：disk_name, disk_util_avg
-- 前端：柱状图 (ECharts bar)
-- ----------------------------------------------------------
SELECT
    '分布-磁盘对比' AS query_label,
    disk_name,
    ROUND(AVG(CASE WHEN tag = 'disk_util_percent' THEN value END), 2) AS util_avg_pct,
    ROUND(AVG(CASE WHEN tag = 'disk_latency_ms'   THEN value END), 2) AS latency_avg_ms,
    ROUND(AVG(CASE WHEN tag = 'disk_rqm_per_sec'  THEN value END), 2) AS rqm_avg,
    COUNT(*)                                                            AS sample_count
FROM fact_disk_tsar
GROUP BY disk_name
ORDER BY disk_name;


-- ============================================================
-- E. 异常分析
-- ============================================================

-- ----------------------------------------------------------
-- E1. CPU 超过80%的服务器列表（最近1小时）
-- 作用：实时告警 — 高CPU主机列表
-- 输入：fact_pref_tsar + dim_host
-- 输出：host_id, hostname, cpu_avg, room, last_check_time
-- 前端：告警列表 / 红色高亮表格
-- ----------------------------------------------------------
SELECT
    '异常-CPU高负载' AS query_label,
    f.host_id,
    h.hostname,
    h.location1                                AS room,
    ROUND(AVG(f.value), 2)                     AS cpu_avg_pct,
    MAX(f.ts_datetime)                         AS last_check_time
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'cpu_usage'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
HAVING AVG(f.value) > 80
ORDER BY cpu_avg_pct DESC;


-- ----------------------------------------------------------
-- E2. 内存超过阈值的服务器（阈值：used > 90% 估算总量）
-- 注意：这里用 mem_used 绝对值排序，取TOP作告警
-- 输入：fact_pref_tsar + dim_host
-- 输出：host_id, hostname, mem_used_avg
-- 前端：告警列表
-- ----------------------------------------------------------
SELECT
    '异常-内存高占用' AS query_label,
    f.host_id,
    h.hostname,
    h.location1                                AS room,
    ROUND(AVG(f.value), 0)                     AS mem_used_avg_mb,
    MAX(f.ts_datetime)                         AS last_check_time
FROM fact_pref_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.mod_id = 'mem_used'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
GROUP BY f.host_id, h.hostname, h.location1
HAVING AVG(f.value) > 90000   -- 假设总内存约100GB，90GB即告警阈值
ORDER BY mem_used_avg_mb DESC;


-- ----------------------------------------------------------
-- E3. 高IO磁盘列表（使用率超过70%）
-- 输入：fact_disk_tsar + dim_host
-- 输出：host_id, hostname, disk_name, disk_util_avg
-- 前端：告警列表
-- ----------------------------------------------------------
SELECT
    '异常-磁盘高IO' AS query_label,
    f.host_id,
    h.hostname,
    f.disk_name,
    ROUND(AVG(f.value), 2)                     AS disk_util_avg_pct,
    MAX(f.ts_datetime)                         AS last_check_time
FROM fact_disk_tsar f
JOIN dim_host h ON f.host_id = h.host_id
WHERE f.tag = 'disk_util_percent'
  AND f.ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_disk_tsar)
GROUP BY f.host_id, h.hostname, f.disk_name
HAVING AVG(f.value) > 70
ORDER BY disk_util_avg_pct DESC;


-- ----------------------------------------------------------
-- E4. 各阈值段服务器数量统计（用于概览饼图）
-- 作用：一览当前CPU/内存/磁盘的告警级别分布
-- 输入：fact_pref_tsar, fact_disk_tsar
-- 输出：category, level, host_count
-- 前端：环形图 (ECharts doughnut)
-- ----------------------------------------------------------
SELECT 'CPU' AS category,
       CASE
           WHEN avg_val >= 80 THEN '危险 (>80%)'
           WHEN avg_val >= 60 THEN '警告 (60-80%)'
           WHEN avg_val >= 30 THEN '正常 (30-60%)'
           ELSE                     '空闲 (<30%)'
       END AS level,
       COUNT(*) AS host_count
FROM (
    SELECT host_id, AVG(value) AS avg_val
    FROM fact_pref_tsar
    WHERE mod_id = 'cpu_usage'
      AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_pref_tsar)
    GROUP BY host_id
) t
GROUP BY level
UNION ALL
SELECT '磁盘' AS category,
       CASE
           WHEN avg_val >= 70 THEN '危险 (>70%)'
           WHEN avg_val >= 40 THEN '警告 (40-70%)'
           ELSE                     '正常 (<40%)'
       END AS level,
       COUNT(*) AS host_count
FROM (
    SELECT host_id, AVG(value) AS avg_val
    FROM fact_disk_tsar
    WHERE tag = 'disk_util_percent'
      AND ts_datetime >= (SELECT MAX(ts_datetime) - INTERVAL 1 HOUR FROM fact_disk_tsar)
    GROUP BY host_id
) t
GROUP BY level;
