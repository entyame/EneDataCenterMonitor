// ============================================================
// server.js — 数据中心监控大屏 API 服务入口
// 启动：node server.js  (或 npm start / npm run dev)
// ============================================================

const express = require('express');
const cors = require('cors');
const dashboardRoutes = require('./routes/dashboard');

const app = express();
const PORT = process.env.PORT || 8080;

// 中间件
app.use(cors());                          // 允许前端跨域请求
app.use(express.json());                  // JSON 解析

// 路由挂载
app.use('/api', dashboardRoutes);

// 根路由 — 健康检查
app.get('/', (req, res) => {
  res.json({
    service: 'EneDataCenterMonitor API',
    version: '1.0.0',
    status: 'running',
    endpoints: [
      'GET /api/kpi',
      'GET /api/cpu/hour',
      'GET /api/memory/hour',
      'GET /api/network/hour',
      'GET /api/load/hour',
      'GET /api/disk/hour',
      'GET /api/hosts/rank?type=cpu&top=10',
      'GET /api/rooms',
      'GET /api/alerts'
    ]
  });
});

// 404
app.use((req, res) => {
  res.status(404).json({ success: false, message: `接口不存在: ${req.method} ${req.url}` });
});

// 启动
app.listen(PORT, () => {
  console.log(`\n============================================`);
  console.log(`  数据中心监控大屏 API 服务已启动`);
  console.log(`  地址: http://localhost:${PORT}`);
  console.log(`  健康检查: http://localhost:${PORT}/`);
  console.log(`  API 列表: http://localhost:${PORT}/api/kpi`);
  console.log(`============================================\n`);
});
