// ============================================================
// MySQL 连接池配置
// 连接 Docker 中的 MySQL 容器
// ============================================================

const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: '127.0.0.1',
  port: 3306,
  user: 'ene_user',
  password: 'ene_pass_2026',
  database: 'ene_datacenter',
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,      // 最大连接数
  queueLimit: 0,            // 队列无限制
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// 启动时测试连接
pool.getConnection()
  .then(conn => {
    console.log('✓ MySQL 连接成功 (ene_datacenter)');
    conn.release();
  })
  .catch(err => {
    console.error('✗ MySQL 连接失败:', err.message);
    console.error('  请确保 Docker MySQL 容器已启动: docker compose up -d');
  });

module.exports = pool;
