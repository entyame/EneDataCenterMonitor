// ============================================================
// Dashboard Controller — 所有 API 业务逻辑
// 每个函数直接查询 dashboard_* 结果表
// ============================================================

const pool = require('../config/db');

// ----------------------------------------------------------
// GET /api/kpi
// 查询表：dashboard_kpi_summary
// 返回：1h 和 24h 两组的 KPI 卡片数据
// ----------------------------------------------------------
exports.getKpi = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT kpi_name, kpi_label, kpi_value, kpi_unit, kpi_max, kpi_min, data_range, stat_time ' +
      'FROM dashboard_kpi_summary ORDER BY data_range, kpi_name'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/cpu/hour
// 查询表：dashboard_cpu_hour
// 返回：CPU 五项指标按小时趋势
// ----------------------------------------------------------
exports.getCpuHour = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ts_date, ts_hour, cpu_user_avg, cpu_sys_avg, cpu_wait_avg, cpu_usage_avg, cpu_idle_avg, sample_count ' +
      'FROM dashboard_cpu_hour ORDER BY ts_date, ts_hour'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/memory/hour
// 查询表：dashboard_mem_hour
// 返回：内存五项指标按小时趋势
// ----------------------------------------------------------
exports.getMemoryHour = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ts_date, ts_hour, mem_used_avg, mem_free_avg, mem_buff_avg, mem_cache_avg, mem_swap_avg, sample_count ' +
      'FROM dashboard_mem_hour ORDER BY ts_date, ts_hour'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/network/hour
// 查询表：dashboard_net_hour
// 返回：网络流量入站/出站 + 数据包趋势
// ----------------------------------------------------------
exports.getNetworkHour = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ts_date, ts_hour, net_in_avg, net_out_avg, net_in_peak, net_out_peak, pkt_in_avg, pkt_out_avg, sample_count ' +
      'FROM dashboard_net_hour ORDER BY ts_date, ts_hour'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/load/hour
// 查询表：dashboard_load_hour
// 返回：系统负载 load1/5/15 按小时趋势
// ----------------------------------------------------------
exports.getLoadHour = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ts_date, ts_hour, load1_avg, load5_avg, load15_avg, sample_count ' +
      'FROM dashboard_load_hour ORDER BY ts_date, ts_hour'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/disk/hour
// 查询表：dashboard_disk_hour
// 返回：磁盘读写 + 使用率 + 延迟趋势
// ----------------------------------------------------------
exports.getDiskHour = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ts_date, ts_hour, disk_read_avg, disk_write_avg, disk_util_avg, disk_latency_avg, sample_count ' +
      'FROM dashboard_disk_hour ORDER BY ts_date, ts_hour'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/hosts/rank?type=cpu
// 查询表：dashboard_host_rank
// 可选参数：type (cpu / memory / disk)，默认 cpu
// 可选参数：top (返回前N条)，默认 10
// 返回：主机排名数据
// ----------------------------------------------------------
exports.getHostsRank = async (req, res) => {
  try {
    const type = req.query.type || 'cpu';
    const top = parseInt(req.query.top) || 10;
    const [rows] = await pool.query(
      'SELECT rank_type, host_id, hostname, room, avg_value, max_value, rank_position, stat_time ' +
      'FROM dashboard_host_rank WHERE rank_type = ? AND rank_position <= ? ORDER BY rank_position',
      [type, top]
    );
    res.json({ success: true, data: rows, count: rows.length, params: { type, top } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/rooms
// 查询表：dashboard_room_summary
// 返回：各机房服务器数量、占比、CPU/内存均值
// ----------------------------------------------------------
exports.getRooms = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT room, host_count, host_pct, cpu_avg, mem_avg_mb, stat_time ' +
      'FROM dashboard_room_summary ORDER BY host_count DESC'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ----------------------------------------------------------
// GET /api/alerts
// 查询表：dashboard_alert_detail
// 返回：所有告警记录，按告警级别×当前值排序
// ----------------------------------------------------------
exports.getAlerts = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT alert_type, host_id, hostname, room, current_value, threshold_value, alert_level, last_check_time, stat_time ' +
      'FROM dashboard_alert_detail ORDER BY FIELD(alert_level, "CRITICAL", "WARNING"), current_value DESC'
    );
    res.json({ success: true, data: rows, count: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
