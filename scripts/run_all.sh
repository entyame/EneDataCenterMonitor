#!/bin/bash
# ============================================================
# run_all.sh — 按顺序执行全部 SQL 脚本
# ============================================================
# 在已运行的 MySQL 容器中手动执行全套 SQL
# 适用于：更新数据后需要全量重跑的场景
# ============================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SQL_DIR="$PROJECT_ROOT/sql"
MYSQL_CMD="docker exec -i ene_dc_monitor_mysql mysql -u root -proot123456 ene_datacenter"

echo "=============================================="
echo "  全量执行数据加工流程"
echo "=============================================="

for sql_file in \
    "01_create_tables.sql" \
    "02_import_data.sql" \
    "03_clean_data.sql" \
    "05_result_tables.sql"
do
    echo ""
    echo "▶ 执行: $sql_file"
    echo "----------------------------------------------"
    $MYSQL_CMD < "$SQL_DIR/$sql_file"
    echo "✓ 完成: $sql_file"
done

echo ""
echo "=============================================="
echo "  全部脚本执行完毕！"
echo "  运行 04_statistics.sql 可查看详细统计结果"
echo "=============================================="
