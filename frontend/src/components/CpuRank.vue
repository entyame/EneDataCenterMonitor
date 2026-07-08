<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchHostsRank } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchHostsRank('cpu', 10)
    if (!res.success || !res.data.length) return
    const names = res.data.map(r => r.hostname.replace('.hismartlab.cn', '')).reverse()
    const vals  = res.data.map(r => Number(r.avg_value)).reverse()
    const rooms = res.data.map(r => r.room).reverse()

    chart.setOption({
      tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' },
        formatter: p => `${p[0].name}<br/>CPU 均值: ${p[0].value}%<br/>机房: ${rooms[res.data.length - 1 - p[0].dataIndex]}` },
      grid: { left: 8, right: 20, top: 4, bottom: 4, containLabel: true },
      xAxis: { type: 'value', max: 100, axisLabel: { color: '#94a3b8', fontSize: 10, formatter: '{value}%' },
        splitLine: { lineStyle: { color: 'rgba(124,58,237,0.1)' } } },
      yAxis: { type: 'category', data: names, axisLabel: { color: '#e2e8f0', fontSize: 10 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      series: [{
        type: 'bar', data: vals,
        itemStyle: {
          borderRadius: [0, 3, 3, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: '#7c3aed' }, { offset: 1, color: '#a78bfa' }
          ])
        },
        barWidth: 14,
        label: { show: true, position: 'right', color: '#a78bfa', fontSize: 10, formatter: '{c}%' }
      }]
    })
  } catch (e) { /* */ }
}

onMounted(() => {
  chart = echarts.init(chartRoot.value, null, { backgroundColor: 'transparent' })
  load()
  timer = setInterval(load, 60000)
  window.addEventListener('resize', () => chart?.resize())
})

onUnmounted(() => { clearInterval(timer); chart?.dispose() })
</script>

<style scoped>
.chart-box { width: 100%; height: 100%; min-height: 200px; }
</style>
