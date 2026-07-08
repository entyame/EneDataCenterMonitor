-- ============================================================
-- 03_clean_data.sql
-- 数据中心运行监控大屏 — 数据清洗与时间转换
-- ============================================================
-- 清洗内容：
--   1. 毫秒时间戳 → DATETIME / DATE / HOUR 转换
--   2. 从 mod_id 提取磁盘名（sda~sde）
--   3. 异常值 / NULL 值标记（保留原始值，不做硬删除）
--   4. 数据一致性验证
-- ============================================================

USE ene_datacenter;

-- ----------------------------------------------------------
-- 3.1 清洗 fact_pref_tsar：时间转换 + 数据验证
-- ----------------------------------------------------------

-- 步骤 A：时间戳解析
-- 原始 ts 为毫秒级 Unix 时间戳，除以 1000 后用 FROM_UNIXTIME 转换
UPDATE fact_pref_tsar
SET
    ts_datetime = FROM_UNIXTIME(ts / 1000),
    ts_date     = DATE(FROM_UNIXTIME(ts / 1000)),
    ts_hour     = HOUR(FROM_UNIXTIME(ts / 1000))
WHERE ts_datetime IS NULL;

-- 步骤 B：标记异常值（值在业务合理范围之外）
-- CPU 类指标应在 0~100 之间
SELECT 'fact_pref_tsar — CPU 异常值检查 (value NOT BETWEEN 0 AND 100)' AS check_item,
       COUNT(*) AS anomaly_count
FROM fact_pref_tsar
WHERE tag = 'cpu_percent' AND (value < 0 OR value > 100);

-- 内存类指标应 >= 0
SELECT 'fact_pref_tsar — 内存负值检查 (value < 0)' AS check_item,
       COUNT(*) AS anomaly_count
FROM fact_pref_tsar
WHERE tag = 'mem_metric' AND value < 0;

-- 负载平均值应 >= 0
SELECT 'fact_pref_tsar — 负载负值检查 (value < 0)' AS check_item,
       COUNT(*) AS anomaly_count
FROM fact_pref_tsar
WHERE tag = 'load_average' AND value < 0;

-- 步骤 C：NULL 值统计（如有，可在后续聚合时用 COALESCE 处理）
SELECT 'fact_pref_tsar — value IS NULL 统计' AS check_item,
       COUNT(*) AS null_count
FROM fact_pref_tsar
WHERE value IS NULL;


-- ----------------------------------------------------------
-- 3.2 清洗 fact_disk_tsar：时间转换 + 磁盘名提取
-- ----------------------------------------------------------

-- 步骤 A：时间戳解析
UPDATE fact_disk_tsar
SET
    ts_datetime = FROM_UNIXTIME(ts / 1000),
    ts_date     = DATE(FROM_UNIXTIME(ts / 1000)),
    ts_hour     = HOUR(FROM_UNIXTIME(ts / 1000))
WHERE ts_datetime IS NULL;

-- 步骤 B：从 mod_id 中提取磁盘名
-- 例如 sda_read → sda, sdb_util → sdb
UPDATE fact_disk_tsar
SET disk_name = SUBSTRING_INDEX(mod_id, '_', 1)
WHERE disk_name IS NULL;

-- 步骤 C：标记异常值
-- 使用率应在 0~100 之间
SELECT 'fact_disk_tsar — util 异常值检查 (value NOT BETWEEN 0 AND 100)' AS check_item,
       COUNT(*) AS anomaly_count
FROM fact_disk_tsar
WHERE tag = 'disk_util_percent' AND (value < 0 OR value > 100);

-- I/O 等待时间应 >= 0
SELECT 'fact_disk_tsar — latency 负值检查 (value < 0)' AS check_item,
       COUNT(*) AS anomaly_count
FROM fact_disk_tsar
WHERE tag = 'disk_latency_ms' AND value < 0;

-- NULL 值统计
SELECT 'fact_disk_tsar — value IS NULL 统计' AS check_item,
       COUNT(*) AS null_count
FROM fact_disk_tsar
WHERE value IS NULL;


-- ----------------------------------------------------------
-- 3.3 数据一致性验证
-- ----------------------------------------------------------

-- 验证：fact_pref_tsar 中的 host_id 是否都在 dim_host 中存在
SELECT '孤立 host_id（pref 中有但 dim_host 中无）' AS check_item,
       COUNT(DISTINCT f.host_id) AS orphan_count
FROM fact_pref_tsar f
LEFT JOIN dim_host h ON f.host_id = h.host_id
WHERE h.host_id IS NULL;

-- 验证：fact_disk_tsar 中的 host_id 是否都在 dim_host 中存在
SELECT '孤立 host_id（disk 中有但 dim_host 中无）' AS check_item,
       COUNT(DISTINCT f.host_id) AS orphan_count
FROM fact_disk_tsar f
LEFT JOIN dim_host h ON f.host_id = h.host_id
WHERE h.host_id IS NULL;

-- 验证：pref 时间覆盖范围
SELECT 'pref 时间范围' AS check_item,
       MIN(ts_datetime) AS earliest,
       MAX(ts_datetime) AS latest,
       COUNT(DISTINCT ts_date) AS distinct_days,
       COUNT(DISTINCT ts_hour) AS distinct_hours
FROM fact_pref_tsar;

-- 验证：disk 时间覆盖范围
SELECT 'disk 时间范围' AS check_item,
       MIN(ts_datetime) AS earliest,
       MAX(ts_datetime) AS latest,
       COUNT(DISTINCT ts_date) AS distinct_days
FROM fact_disk_tsar;

-- 验证：每个主机每小时的数据完整性（pref）
SELECT 'pref 数据完整性（按主机+小时）' AS check_item,
       COUNT(DISTINCT host_id) AS host_count,
       COUNT(DISTINCT CONCAT(host_id, '-', ts_date, '-', ts_hour)) AS host_hour_combos,
       COUNT(DISTINCT CONCAT(host_id, '-', ts_date, '-', ts_hour))
         / (COUNT(DISTINCT host_id) * COUNT(DISTINCT CONCAT(ts_date, '-', ts_hour))) * 100
         AS completeness_pct
FROM fact_pref_tsar;
