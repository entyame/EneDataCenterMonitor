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
# 2. 在 SQL 目录下创建 data 软链接（MySQL 容器内 import 用）
# --------------------------------------------------
echo "[2/4] 准备数据文件..."
if [ ! -d "$SQL_DIR/data" ]; then
    # Windows 下可能不支持软链接，改用拷贝方式
    if [ -d "$DATA_DIR" ]; then
        echo "  将 data/*.dat 复制到 sql/data/ 供容器挂载..."
        mkdir -p "$SQL_DIR/data"
        cp "$DATA_DIR"/*.dat "$SQL_DIR/data/"
        echo "  ✓ 数据文件已复制"
    fi
else
    echo "  ✓ sql/data/ 已存在，跳过"
fi

# --------------------------------------------------
# 3. 启动 Docker MySQL 容器
# --------------------------------------------------
echo "[3/4] 启动 MySQL 容器..."
cd "$DOCKER_DIR"

# 停止并删除旧容器（如果有）
docker compose down 2>/dev/null || true

# 如果希望完全重建（清空旧数据），取消下面一行的注释：
# docker volume rm docker_mysql_data 2>/dev/null || true

docker compose up -d

echo "  等待 MySQL 启动..."
sleep 5

# 检查 MySQL 健康状态
for i in $(seq 1 30); do
    if docker compose ps | grep -q "healthy"; then
        echo "  ✓ MySQL 容器已启动 (healthy)"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "  警告：MySQL 启动超时，请手动检查 docker compose logs"
    fi
    sleep 2
done

# --------------------------------------------------
# 4. 执行 SQL 脚本（清理 + 统计 + 结果表）
# 注：01_create_tables 和 02_import_data 由容器初始化自动执行
#    这里只跑后续的加工脚本
# --------------------------------------------------
echo "[4/4] 执行数据加工 SQL..."

run_sql() {
    local sql_file="$1"
    local desc="$2"
    echo "  执行: $desc ..."
    docker exec ene_dc_monitor_mysql \
        mysql -u root -proot123456 ene_datacenter \
        < "$SQL_DIR/$sql_file"
    echo "  ✓ $desc 完成"
}

# 注意：03_clean_data 和 04_statistics 是 SELECT 为主，适合验证
# 05_result_tables 会创建并填充结果表
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
echo "    docker exec -it ene_dc_monitor_mysql mysql -u root -proot123456 ene_datacenter"
echo "    SELECT COUNT(*) FROM fact_pref_tsar;"
echo ""
