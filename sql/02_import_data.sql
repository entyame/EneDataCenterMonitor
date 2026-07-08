-- ============================================================
-- 02_import_data.sql
-- 数据中心运行监控大屏 — 原始 dat 文件导入
-- ============================================================
-- 注意：
--   1. 需要先确认 MySQL 开启了 local_infile（docker-compose 已配置）
--   2. dat 文件分隔符为 Tab（\t），换行为 CRLF
--   3. 导入路径请根据实际挂载情况调整
--   4. Docker 环境下文件在 /docker-entrypoint-initdb.d/data/ 下
-- ============================================================

USE ene_datacenter;

-- 导入前清空已有数据（幂等执行友好）
TRUNCATE TABLE dim_host;
TRUNCATE TABLE dim_mod;
TRUNCATE TABLE fact_pref_tsar;
TRUNCATE TABLE fact_disk_tsar;

-- ----------------------------------------------------------
-- 2.1 导入主机维度表
-- 文件：host_detail.dat  (21行含表头, Tab分隔, UTF-8)
-- ----------------------------------------------------------
LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/data/host_detail.dat'
INTO TABLE dim_host
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES  TERMINATED BY '\r\n'
IGNORE 1 ROWS
(host_id, hostname, owner, model, location1, location2);

-- 验证
SELECT CONCAT('dim_host: ', COUNT(*), ' rows imported') AS check_result FROM dim_host;


-- ----------------------------------------------------------
-- 2.2 导入指标字典维度表
-- 文件：mod_detail.dat  (56行含表头, Tab分隔, UTF-8)
-- ----------------------------------------------------------
LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/data/mod_detail.dat'
INTO TABLE dim_mod
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES  TERMINATED BY '\r\n'
IGNORE 1 ROWS
(mod_id, mod_type, mod_desc, mod_unit, mod_tag);

-- 验证
SELECT CONCAT('dim_mod: ', COUNT(*), ' rows imported') AS check_result FROM dim_mod;


-- ----------------------------------------------------------
-- 2.3 导入性能监控事实表
-- 文件：pref_tsar.dat  (67201行含表头, Tab分隔)
-- ----------------------------------------------------------
LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/data/pref_tsar.dat'
INTO TABLE fact_pref_tsar
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES  TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ts, host_id, @type, mod_id, value, tag);

-- 验证
SELECT CONCAT('fact_pref_tsar: ', COUNT(*), ' rows imported') AS check_result FROM fact_pref_tsar;


-- ----------------------------------------------------------
-- 2.4 导入磁盘监控事实表
-- 文件：disk_tsar.dat  (12001行含表头, Tab分隔)
-- ----------------------------------------------------------
LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/data/disk_tsar.dat'
INTO TABLE fact_disk_tsar
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES  TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ts, host_id, @type, mod_id, value, tag);

-- 验证
SELECT CONCAT('fact_disk_tsar: ', COUNT(*), ' rows imported') AS check_result FROM fact_disk_tsar;


-- ----------------------------------------------------------
-- 最终核对
-- ----------------------------------------------------------
SELECT 'host_detail.dat'  AS source_file, COUNT(*) AS row_count FROM dim_host
UNION ALL
SELECT 'mod_detail.dat',   COUNT(*) FROM dim_mod
UNION ALL
SELECT 'pref_tsar.dat',    COUNT(*) FROM fact_pref_tsar
UNION ALL
SELECT 'disk_tsar.dat',    COUNT(*) FROM fact_disk_tsar;
