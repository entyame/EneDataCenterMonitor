<template>
  <div class="dashboard">
    <!-- 背景粒子 -->
    <canvas ref="particleCanvas" id="particles"></canvas>

    <!-- ===== 顶部标题栏 ===== -->
    <header class="header">
      <div class="header-line left"></div>
      <div class="header-content">
        <span class="header-icon">⚡</span>
        <h1>EneDataCenterMonitor</h1>
        <span class="header-sub">数据中心运行监控大屏</span>
        <span class="header-time">{{ currentTime }}</span>
      </div>
      <div class="header-line right"></div>
    </header>

    <!-- ===== 主体：左栏 + 右区域 ===== -->
    <main class="main-layout">

      <!-- ========== 左栏：排名 + 机房 ========== -->
      <aside class="sidebar">
        <GlassPanel title="服务器 CPU 排名 TOP10">
          <CpuRank />
        </GlassPanel>
        <GlassPanel title="机房服务器分布">
          <RoomDist />
        </GlassPanel>
      </aside>

      <!-- ========== 右区域：KPI → 趋势图 ========== -->
      <section class="content">

        <!-- KPI 卡片行 -->
        <div class="kpi-row">
          <KpiCard v-for="card in kpiCards" :key="card.label"
            :label="card.label" :value="card.value" :unit="card.unit"
            :icon="card.icon" :color="card.color" />
        </div>

        <!-- 趋势图第一行：CPU 全宽 -->
        <GlassPanel title="CPU 使用率趋势 (24h)" class="trend-full">
          <CpuTrend />
        </GlassPanel>

        <!-- 趋势图第二行：内存 + 网络 并排 -->
        <div class="trend-row">
          <GlassPanel title="内存使用趋势 (24h)">
            <MemoryTrend />
          </GlassPanel>
          <GlassPanel title="网络流量趋势 (24h)">
            <NetworkTrend />
          </GlassPanel>
        </div>

        <!-- 趋势图第三行：磁盘 + 负载 并排 -->
        <div class="trend-row">
          <GlassPanel title="磁盘 IO 趋势">
            <DiskTrend />
          </GlassPanel>
          <GlassPanel title="系统负载趋势 (24h)">
            <LoadTrend />
          </GlassPanel>
        </div>

      </section>
    </main>

    <!-- ===== 告警滚动条 ===== -->
    <footer class="alert-bar" v-if="alerts.length">
      <span class="alert-icon">⚠</span>
      <div class="alert-scroll">
        <span v-for="a in alerts" :key="a.host_id" class="alert-item">
          [{{ a.alert_level }}] {{ a.hostname }} — {{ a.alert_type }}={{ a.current_value }}
        </span>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import GlassPanel from './components/GlassPanel.vue'
import KpiCard from './components/KpiCard.vue'
import CpuRank from './components/CpuRank.vue'
import CpuTrend from './components/CpuTrend.vue'
import MemoryTrend from './components/MemoryTrend.vue'
import NetworkTrend from './components/NetworkTrend.vue'
import DiskTrend from './components/DiskTrend.vue'
import LoadTrend from './components/LoadTrend.vue'
import RoomDist from './components/RoomDist.vue'
import { fetchKpi, fetchAlerts } from './api/dashboard'

// 实时时钟
const currentTime = ref('')
let clockTimer = null

// KPI 数据
const kpiCards = ref([
  { label: '服务器总数', value: '--', unit: '台', icon: '🖥', color: '#7c3aed' },
  { label: '在线服务器', value: '--', unit: '台', icon: '✅', color: '#10b981' },
  { label: 'CPU 平均使用率', value: '--', unit: '%', icon: '📊', color: '#06b6d4' },
  { label: '内存平均使用量', value: '--', unit: 'MB', icon: '💾', color: '#f59e0b' },
  { label: '磁盘平均使用率', value: '--', unit: '%', icon: '💿', color: '#8b5cf6' },
])

// 告警
const alerts = ref([])

// 加载 KPI
async function loadKpi() {
  try {
    const res = await fetchKpi()
    if (!res.success) return
    const map = {}
    res.data.forEach(d => {
      if (d.data_range === '1h') map[d.kpi_name] = d
    })
    if (map['host_online'])  kpiCards.value[0].value = map['host_online'].kpi_value
    if (map['host_online'])  kpiCards.value[1].value = map['host_online'].kpi_value
    if (map['cpu_usage'])    kpiCards.value[2].value = map['cpu_usage'].kpi_value
    if (map['mem_used'])     kpiCards.value[3].value = map['mem_used'].kpi_value
    if (map['disk_util'])    kpiCards.value[4].value = map['disk_util'].kpi_value
  } catch (e) { console.error('KPI load error:', e) }
}

async function loadAlerts() {
  try {
    const res = await fetchAlerts()
    if (res.success) alerts.value = res.data
  } catch (e) { /* silent */ }
}

// 背景粒子系统
const particleCanvas = ref(null)
let animId = null
function initParticles() {
  const canvas = particleCanvas.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  const resize = () => { canvas.width = window.innerWidth; canvas.height = window.innerHeight }
  resize()
  window.addEventListener('resize', resize)

  const particles = Array.from({ length: 60 }, () => ({
    x: Math.random() * canvas.width, y: Math.random() * canvas.height,
    vx: (Math.random() - 0.5) * 0.4, vy: (Math.random() - 0.5) * 0.4,
    r: Math.random() * 1.5 + 0.5, alpha: Math.random() * 0.5 + 0.2
  }))

  function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    particles.forEach(p => {
      p.x += p.vx; p.y += p.vy
      if (p.x < 0) p.x = canvas.width
      if (p.x > canvas.width) p.x = 0
      if (p.y < 0) p.y = canvas.height
      if (p.y > canvas.height) p.y = 0
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(124, 58, 237, ${p.alpha})`
      ctx.fill()
    })
    // 连线
    particles.forEach((a, i) => {
      particles.slice(i + 1).forEach(b => {
        const d = Math.hypot(a.x - b.x, a.y - b.y)
        if (d < 120) {
          ctx.beginPath()
          ctx.moveTo(a.x, a.y)
          ctx.lineTo(b.x, b.y)
          ctx.strokeStyle = `rgba(124, 58, 237, ${0.08 * (1 - d / 120)})`
          ctx.lineWidth = 0.5
          ctx.stroke()
        }
      })
    })
    animId = requestAnimationFrame(draw)
  }
  draw()
}

onMounted(() => {
  loadKpi(); loadAlerts()
  setInterval(loadKpi, 30000)
  setInterval(loadAlerts, 30000)
  clockTimer = setInterval(() => {
    currentTime.value = new Date().toLocaleString('zh-CN', { hour12: false })
  }, 1000)
  currentTime.value = new Date().toLocaleString('zh-CN', { hour12: false })
  initParticles()
})

onUnmounted(() => {
  clearInterval(clockTimer)
  if (animId) cancelAnimationFrame(animId)
})
</script>

<style scoped>
.dashboard {
  width: 100vw; height: 100vh;
  display: flex; flex-direction: column;
  padding: 6px 14px 4px;
  gap: 5px;
  overflow: hidden;
  position: relative;
  z-index: 2;
}

/* ---- Header ---- */
.header {
  display: flex; align-items: center;
  height: 42px; flex-shrink: 0;
  z-index: 3;
}
.header-line {
  flex: 1; height: 1px;
  background: linear-gradient(90deg, transparent, var(--primary), transparent);
}
.header-content {
  display: flex; align-items: center; gap: 12px;
  padding: 0 24px;
}
.header-icon { font-size: 18px; }
.header-content h1 {
  font-size: 18px; font-weight: 700;
  letter-spacing: 4px;
  background: linear-gradient(90deg, var(--accent-cyan), var(--primary), var(--accent-gold));
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.header-sub {
  font-size: 10px; color: var(--text-dim); letter-spacing: 2px;
}
.header-time {
  margin-left: auto; font-size: 11px; color: var(--text-secondary);
  font-family: var(--font-mono);
}

/* ---- Main Layout: 左栏 + 右区域 ---- */
.main-layout {
  display: flex; gap: 8px;
  flex: 1; min-height: 0;
}

/* ---- 左栏 ---- */
.sidebar {
  width: 260px; flex-shrink: 0;
  display: flex; flex-direction: column; gap: 8px;
}
.sidebar > * { flex: 1; min-height: 0; }

/* ---- 右区域 ---- */
.content {
  flex: 1; min-width: 0;
  display: flex; flex-direction: column; gap: 6px;
}

/* ---- KPI ---- */
.kpi-row {
  display: flex; gap: 8px;
  height: 62px; flex-shrink: 0;
}
.kpi-row > * { flex: 1; }

/* ---- 趋势图全宽 ---- */
.trend-full {
  flex: 2.2; min-height: 0;
}

/* ---- 趋势图双栏 ---- */
.trend-row {
  display: flex; gap: 8px;
  flex: 1.8; min-height: 0;
}
.trend-row > * { flex: 1; min-width: 0; }

/* ---- Alert Bar ---- */
.alert-bar {
  display: flex; align-items: center; gap: 10px;
  height: 24px; flex-shrink: 0;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.25);
  border-radius: 4px;
  padding: 0 12px;
  font-size: 10px;
  z-index: 3;
  overflow: hidden;
}
.alert-icon { flex-shrink: 0; animation: pulse-dot 1s ease-in-out infinite; }
.alert-scroll {
  display: flex; gap: 32px;
  overflow: hidden; white-space: nowrap;
}
.alert-item {
  color: var(--accent-red);
  font-family: var(--font-mono);
  animation: scroll-left 20s linear infinite;
}
@keyframes scroll-left {
  0% { transform: translateX(100%); }
  100% { transform: translateX(-200%); }
}
</style>
