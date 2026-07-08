<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchCpuHour } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchCpuHour()
    if (!res.success || !res.data.length) return
    const xData = res.data.map(d => `${d.ts_hour}:00`)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0, textStyle: { color: '#94a3b8', fontSize: 10 },
        data: ['user', 'sys', 'wait', 'usage', 'idle'] },
      grid: { left: 8, right: 8, top: 8, bottom: 28, containLabel: true },
      xAxis: { type: 'category', data: xData, axisLabel: { color: '#64748b', fontSize: 9 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      yAxis: { type: 'value', max: 100, axisLabel: { color: '#94a3b8', fontSize: 9, formatter: '{value}%' },
        splitLine: { lineStyle: { color: 'rgba(124,58,237,0.08)' } } },
      series: [
        { name: 'user', type: 'line', data: res.data.map(d => d.cpu_user_avg), smooth: true, lineStyle: { color: '#f59e0b', width: 1.5 }, symbol: 'none', areaStyle: { color: 'rgba(245,158,11,0.06)' } },
        { name: 'sys',  type: 'line', data: res.data.map(d => d.cpu_sys_avg), smooth: true, lineStyle: { color: '#8b5cf6', width: 1.5 }, symbol: 'none', areaStyle: { color: 'rgba(139,92,246,0.06)' } },
        { name: 'wait', type: 'line', data: res.data.map(d => d.cpu_wait_avg), smooth: true, lineStyle: { color: '#ef4444', width: 1.2 }, symbol: 'none' },
        { name: 'usage',type: 'line', data: res.data.map(d => d.cpu_usage_avg), smooth: true, lineStyle: { color: '#06b6d4', width: 2.5 }, symbol: 'none', areaStyle: { color: 'rgba(6,182,212,0.1)' } },
        { name: 'idle', type: 'line', data: res.data.map(d => d.cpu_idle_avg), smooth: true, lineStyle: { color: '#10b981', width: 1 }, symbol: 'none', areaStyle: { color: 'rgba(16,185,129,0.04)' } }
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
