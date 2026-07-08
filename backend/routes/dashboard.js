// ============================================================
// Dashboard Routes — 路由定义
// ============================================================

const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/dashboardController');

// KPI 卡片
router.get('/kpi',          ctrl.getKpi);

// 趋势分析（5个维度）
router.get('/cpu/hour',     ctrl.getCpuHour);
router.get('/memory/hour',  ctrl.getMemoryHour);
router.get('/network/hour', ctrl.getNetworkHour);
router.get('/load/hour',    ctrl.getLoadHour);
router.get('/disk/hour',    ctrl.getDiskHour);

// 排名 & 分布 & 告警
router.get('/hosts/rank',   ctrl.getHostsRank);
router.get('/rooms',        ctrl.getRooms);
router.get('/alerts',       ctrl.getAlerts);

module.exports = router;
