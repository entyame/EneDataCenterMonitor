-- ============================================================
-- 01_create_tables.sql
-- 数据中心运行监控大屏 — 数据库建表 DDL
-- ============================================================
-- 设计思路：
--   维度表：dim_host（主机维度）、dim_mod（指标字典维度）
--   事实表：fact_pref_tsar（性能监控事实）、fact_disk_tsar（磁盘监控事实）
--   结果表：dashboard_* 系列（供前端大屏直接查询）
-- ============================================================

CREATE DATABASE IF NOT EXISTS ene_datacenter
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ene_datacenter;

-- ============================================================
-- 1. 维度表：主机信息
-- 来源文件：host_detail.dat (20 台服务器)
-- ============================================================
DROP TABLE IF EXISTS dim_host;
CREATE TABLE dim_host (
    host_id     VARCHAR(20)   NOT NULL COMMENT '主机ID，如 host001',
    hostname    VARCHAR(100)  NOT NULL COMMENT '主机域名',
    owner       VARCHAR(50)   DEFAULT NULL COMMENT '所属业务线/负责人',
    model       VARCHAR(50)   DEFAULT NULL COMMENT '服务器型号',
    location1   VARCHAR(50)   DEFAULT NULL COMMENT '机房（数据中心）',
    location2   VARCHAR(50)   DEFAULT NULL COMMENT '机架编号',
    PRIMARY KEY (host_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='主机维度表 —— 20台服务器的基本信息';


-- ============================================================
-- 2. 维度表：监控指标字典
-- 来源文件：mod_detail.dat (55 个指标)
--   - disk 类 35 个 (5块磁盘 × 7个指标)
--   - pref 类 20 个 (CPU/内存/网络/负载/进程)
-- ============================================================
DROP TABLE IF EXISTS dim_mod;
CREATE TABLE dim_mod (
    mod_id      VARCHAR(30)   NOT NULL COMMENT '指标编码，如 cpu_usage',
    mod_type    VARCHAR(10)   NOT NULL COMMENT '分类：disk / pref',
    mod_desc    VARCHAR(100)  DEFAULT NULL COMMENT '指标中文描述',
    mod_unit    VARCHAR(20)   DEFAULT NULL COMMENT '单位，如 %、MB、MB/s',
    mod_tag     VARCHAR(30)   DEFAULT NULL COMMENT '指标标签（分组标识）',
    PRIMARY KEY (mod_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监控指标字典维度表';


-- ============================================================
-- 3. 事实表：服务器性能监控（pref）
-- 来源文件：pref_tsar.dat
-- 数据规模：~67,200 行 = 20主机 × 20指标 × 168小时
-- 时间范围：2026-06-30 ~ 2026-07-06（7天，每小时一条）
-- ============================================================
DROP TABLE IF EXISTS fact_pref_tsar;
CREATE TABLE fact_pref_tsar (
    id          BIGINT        AUTO_INCREMENT COMMENT '自增主键',
    ts          BIGINT        NOT NULL    COMMENT '原始毫秒级时间戳',
    ts_datetime DATETIME      DEFAULT NULL COMMENT '转换后的日期时间',
    ts_date     DATE          DEFAULT NULL COMMENT '日期（yyyy-mm-dd）',
    ts_hour     TINYINT       DEFAULT NULL COMMENT '小时（0-23）',
    host_id     VARCHAR(20)   NOT NULL    COMMENT '主机ID',
    mod_id      VARCHAR(30)   NOT NULL    COMMENT '指标编码',
    value       DOUBLE        DEFAULT NULL COMMENT '指标值',
    tag         VARCHAR(30)   DEFAULT NULL COMMENT '指标标签',
    PRIMARY KEY (id),
    INDEX idx_pref_host     (host_id),
    INDEX idx_pref_mod      (mod_id),
    INDEX idx_pref_datetime (ts_datetime),
    INDEX idx_pref_date_hour(ts_date, ts_hour),
    INDEX idx_pref_host_mod (host_id, mod_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='性能监控事实表 — CPU/内存/网络/负载/进程';


-- ============================================================
-- 4. 事实表：磁盘性能监控（disk）
-- 来源文件：disk_tsar.dat
-- 数据规模：~12,000 行（稀疏采样，每5分钟一条随机主机/指标）
-- ============================================================
DROP TABLE IF EXISTS fact_disk_tsar;
CREATE TABLE fact_disk_tsar (
    id          BIGINT        AUTO_INCREMENT COMMENT '自增主键',
    ts          BIGINT        NOT NULL    COMMENT '原始毫秒级时间戳',
    ts_datetime DATETIME      DEFAULT NULL COMMENT '转换后的日期时间',
    ts_date     DATE          DEFAULT NULL COMMENT '日期（yyyy-mm-dd）',
    ts_hour     TINYINT       DEFAULT NULL COMMENT '小时（0-23）',
    host_id     VARCHAR(20)   NOT NULL    COMMENT '主机ID',
    disk_name   CHAR(3)       DEFAULT NULL COMMENT '磁盘名，如 sda/sdb/sdc/sdd/sde',
    mod_id      VARCHAR(30)   NOT NULL    COMMENT '指标编码',
    value       DOUBLE        DEFAULT NULL COMMENT '指标值',
    tag         VARCHAR(30)   DEFAULT NULL COMMENT '指标标签',
    PRIMARY KEY (id),
    INDEX idx_disk_host       (host_id),
    INDEX idx_disk_mod        (mod_id),
    INDEX idx_disk_datetime   (ts_datetime),
    INDEX idx_disk_date_hour  (ts_date, ts_hour),
    INDEX idx_disk_diskname   (disk_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='磁盘监控事实表 — 5块磁盘的读写/IO指标';
