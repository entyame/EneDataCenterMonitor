#!/bin/bash
# ============================================================
# setup.sh — 数据中心监控大屏项目一键部署脚本
# ============================================================
# 用法：
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
# ============================================================

set -e

echo "=============================================="
echo "  数据中心运行监控大屏 — 项目部署脚本"
echo "=============================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
SQL_DIR="$PROJECT_ROOT/sql"
DATA_DIR="$PROJECT_ROOT/data"

# Docker 容器内 mysql 客户端统一走 TCP，避免 Unix socket 问题
MYSQL_EXEC="docker exec -i ene_dc_monitor_mysql mysql -h 127.0.0.1 -u root -proot123456"

# --------------------------------------------------
# 1. 检查 Docker 环境
# --------------------------------------------------
echo "[1/4] 检查 Docker 环境..."
if ! command -v docker &> /dev/null; then
    echo "错误：未检测到 Docker，请先安装 Docker Desktop。"
    echo "下载地址：https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "错误：未检测到 docker-compose。"
    exit 1
fi

echo "  ✓ Docker 已就绪"

# --------------------------------------------------
# 2. 准备数据文件（复制到 sql/data/ 供容器挂载）
# --------------------------------------------------
echo "[2/4] 准备数据文件..."
mkdir -p "$SQL_DIR/data"
cp "$DATA_DIR"/*.dat "$SQL_DIR/data/"
echo "  ✓ 数据文件已复制到 sql/data/"

# --------------------------------------------------
# 3. 彻底重建 MySQL 容器（清空旧数据卷，确保 init 脚本从头执行）
# --------------------------------------------------
echo "[3/4] 重建 MySQL 容器（清空旧数据）..."

cd "$DOCKER_DIR"

# 停止并删除容器 + 数据卷（彻底重建）
docker compose down -v 2>/dev/null || true

docker compose up -d

echo "  等待 MySQL 启动..."
sleep 8

# 检查 MySQL 健康状态
READY=0
for i in $(seq 1 30); do
    if docker compose ps | grep -q "healthy"; then
        echo "  ✓ MySQL 容器已启动 (healthy)"
        READY=1
        break
    fi
    echo "  等待中... ($i/30)"
    sleep 2
done

if [ $READY -eq 0 ]; then
    echo "  警告：MySQL 启动超时，查看日志："
    docker compose logs --tail=30
    exit 1
fi

# 验证 init 脚本是否执行成功
echo ""
echo "  验证数据导入结果..."
sleep 2

echo "  dim_host:       $($MYSQL_EXEC -N -e 'SELECT COUNT(*) FROM ene_datacenter.dim_host') 行 (预期 20)"
echo "  dim_mod:        $($MYSQL_EXEC -N -e 'SELECT COUNT(*) FROM ene_datacenter.dim_mod') 行 (预期 55)"
echo "  fact_pref_tsar: $($MYSQL_EXEC -N -e 'SELECT COUNT(*) FROM ene_datacenter.fact_pref_tsar') 行 (预期 67200)"
echo "  fact_disk_tsar: $($MYSQL_EXEC -N -e 'SELECT COUNT(*) FROM ene_datacenter.fact_disk_tsar') 行 (预期 12000)"

# --------------------------------------------------
# 4. 执行数据加工 SQL
# --------------------------------------------------
echo ""
echo "[4/4] 执行数据加工 SQL..."

run_sql() {
    local sql_file="$1"
    local desc="$2"
    echo "  执行: $desc ..."
    $MYSQL_EXEC ene_datacenter < "$SQL_DIR/$sql_file"
    echo "  ✓ $desc 完成"
}

run_sql "03_clean_data.sql"    "数据清洗"
run_sql "05_result_tables.sql" "生成结果表"

# --------------------------------------------------
# 完成
# --------------------------------------------------
echo ""
echo "=============================================="
echo "  部署完成！"
echo "=============================================="
echo ""
echo "  MySQL 连接信息："
echo "    地址：localhost:3306"
echo "    数据库：ene_datacenter"
echo "    用户：ene_user / ene_pass_2026"
echo "    root：root / root123456"
echo ""
echo "  验证命令："
echo "    docker exec -i ene_dc_monitor_mysql mysql -h 127.0.0.1 -u root -proot123456 ene_datacenter"
echo ""
echo "  查看结果表："
echo "    SELECT table_name, table_rows FROM information_schema.tables"
echo "    WHERE table_schema='ene_datacenter' AND table_name LIKE 'dashboard_%';"
echo ""
