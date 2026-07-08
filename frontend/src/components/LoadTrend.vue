<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchLoadHour } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchLoadHour()
    if (!res.success || !res.data.length) return
    const xData = res.data.map(d => `${d.ts_hour}:00`)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: -6, textStyle: { color: '#94a3b8', fontSize: 9 },
        data: ['1min', '5min', '15min'] },
      grid: { left: 6, right: 6, top: 6, bottom: 44, containLabel: true },
      xAxis: { type: 'category', data: xData, axisLabel: { color: '#64748b', fontSize: 8, interval: 5 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      yAxis: { type: 'value', axisLabel: { color: '#94a3b8', fontSize: 8 },
        splitLine: { lineStyle: { color: 'rgba(124,58,237,0.08)' } } },
      series: [
        { name: '1min',  type: 'line', data: res.data.map(d => d.load1_avg), smooth: true, lineStyle: { color: '#06b6d4', width: 2 }, symbol: 'none', areaStyle: { color: 'rgba(6,182,212,0.1)' } },
        { name: '5min',  type: 'line', data: res.data.map(d => d.load5_avg), smooth: true, lineStyle: { color: '#f59e0b', width: 2 }, symbol: 'none', areaStyle: { color: 'rgba(245,158,11,0.08)' } },
        { name: '15min', type: 'line', data: res.data.map(d => d.load15_avg), smooth: true, lineStyle: { color: '#8b5cf6', width: 1.5, type: 'dashed' }, symbol: 'none' }
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
