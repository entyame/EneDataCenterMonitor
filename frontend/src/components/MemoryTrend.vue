<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchMemoryHour } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchMemoryHour()
    if (!res.success || !res.data.length) return
    const xData = res.data.map(d => `${d.ts_hour}:00`)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0, textStyle: { color: '#94a3b8', fontSize: 10 },
        data: ['已用', '空闲', '缓冲', '缓存', '交换'] },
      grid: { left: 8, right: 8, top: 8, bottom: 28, containLabel: true },
      xAxis: { type: 'category', data: xData, axisLabel: { color: '#64748b', fontSize: 9 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      yAxis: { type: 'value', axisLabel: { color: '#94a3b8', fontSize: 9, formatter: v => (v/1024).toFixed(0)+'G' },
        splitLine: { lineStyle: { color: 'rgba(124,58,237,0.08)' } } },
      series: [
        { name: '已用', type: 'line', stack: 'mem', data: res.data.map(d => d.mem_used_avg), smooth: true, lineStyle: { color: '#ef4444', width: 1.2 }, areaStyle: { color: 'rgba(239,68,68,0.25)' }, symbol: 'none' },
        { name: '空闲', type: 'line', stack: 'mem', data: res.data.map(d => d.mem_free_avg), smooth: true, lineStyle: { color: '#10b981', width: 1.2 }, areaStyle: { color: 'rgba(16,185,129,0.2)' }, symbol: 'none' },
        { name: '缓冲', type: 'line', stack: 'mem', data: res.data.map(d => d.mem_buff_avg), smooth: true, lineStyle: { color: '#f59e0b', width: 1.2 }, areaStyle: { color: 'rgba(245,158,11,0.15)' }, symbol: 'none' },
        { name: '缓存', type: 'line', stack: 'mem', data: res.data.map(d => d.mem_cache_avg), smooth: true, lineStyle: { color: '#06b6d4', width: 1.2 }, areaStyle: { color: 'rgba(6,182,212,0.15)' }, symbol: 'none' },
        { name: '交换', type: 'line', stack: 'mem', data: res.data.map(d => d.mem_swap_avg), smooth: true, lineStyle: { color: '#8b5cf6', width: 1 }, areaStyle: { color: 'rgba(139,92,246,0.1)' }, symbol: 'none' }
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
.chart-box { width: 100%; height: 100%; min-height: 160px; }
</style>
