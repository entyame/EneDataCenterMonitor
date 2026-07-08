<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchDiskHour } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchDiskHour()
    if (!res.success || !res.data.length) return
    const xData = res.data.map(d => `${d.ts_date.slice(5)} ${String(d.ts_hour).padStart(2,'0')}:00`)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: -6, textStyle: { color: '#94a3b8', fontSize: 9 },
        data: ['读取', '写入', '使用率', '延迟'] },
      grid: { left: 6, right: 6, top: 6, bottom: 44, containLabel: true },
      xAxis: { type: 'category', data: xData, axisLabel: { color: '#64748b', fontSize: 8, interval: 149 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      yAxis: [
        { type: 'value', name: '扇区/s', nameTextStyle: { color: '#94a3b8', fontSize: 8 },
          axisLabel: { color: '#94a3b8', fontSize: 8, formatter: v => (v/1000).toFixed(0)+'k' },
          splitLine: { lineStyle: { color: 'rgba(124,58,237,0.08)' } } },
        { type: 'value', name: '% / ms', nameTextStyle: { color: '#94a3b8', fontSize: 8 },
          axisLabel: { color: '#94a3b8', fontSize: 8 }, splitLine: { show: false } }
      ],
      series: [
        { name: '读取', type: 'line', data: res.data.map(d => d.disk_read_avg), smooth: true, lineStyle: { color: '#10b981', width: 1.2 }, symbol: 'none' },
        { name: '写入', type: 'line', data: res.data.map(d => d.disk_write_avg), smooth: true, lineStyle: { color: '#f59e0b', width: 1.2 }, symbol: 'none' },
        { name: '使用率', type: 'line', yAxisIndex: 1, data: res.data.map(d => d.disk_util_avg), smooth: true, lineStyle: { color: '#ef4444', width: 2 }, symbol: 'none' },
        { name: '延迟', type: 'line', yAxisIndex: 1, data: res.data.map(d => d.disk_latency_avg), smooth: true, lineStyle: { color: '#06b6d4', width: 1.5, type: 'dashed' }, symbol: 'none' }
      ]
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
.chart-box { width: 100%; height: 100%; min-height: 140px; }
</style>
