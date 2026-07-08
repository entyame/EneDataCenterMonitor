<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchNetworkHour } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchNetworkHour()
    if (!res.success || !res.data.length) return
    const xData = res.data.map(d => `${d.ts_hour}:00`)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: -6, textStyle: { color: '#94a3b8', fontSize: 9 },
        data: ['入站(MB/s)', '出站(MB/s)', '入站数据包', '出站数据包'] },
      grid: { left: 6, right: 6, top: 6, bottom: 44, containLabel: true },
      xAxis: { type: 'category', data: xData, axisLabel: { color: '#64748b', fontSize: 8, interval: 5 },
        axisLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } } },
      yAxis: [
        { type: 'value', name: 'MB/s', nameTextStyle: { color: '#94a3b8', fontSize: 8 },
          axisLabel: { color: '#94a3b8', fontSize: 8 }, splitLine: { lineStyle: { color: 'rgba(124,58,237,0.08)' } } },
        { type: 'value', name: 'pkt/s', nameTextStyle: { color: '#94a3b8', fontSize: 8 },
          axisLabel: { color: '#94a3b8', fontSize: 8 }, splitLine: { show: false } }
      ],
      series: [
        { name: '入站(MB/s)', type: 'line', data: res.data.map(d => d.net_in_avg), smooth: true, lineStyle: { color: '#10b981', width: 2 }, symbol: 'none', areaStyle: { color: 'rgba(16,185,129,0.1)' } },
        { name: '出站(MB/s)', type: 'line', data: res.data.map(d => d.net_out_avg), smooth: true, lineStyle: { color: '#f59e0b', width: 2 }, symbol: 'none', areaStyle: { color: 'rgba(245,158,11,0.1)' } },
        { name: '入站数据包', type: 'line', yAxisIndex: 1, data: res.data.map(d => d.pkt_in_avg), smooth: true, lineStyle: { color: '#06b6d4', width: 1, type: 'dashed' }, symbol: 'none' },
        { name: '出站数据包', type: 'line', yAxisIndex: 1, data: res.data.map(d => d.pkt_out_avg), smooth: true, lineStyle: { color: '#8b5cf6', width: 1, type: 'dashed' }, symbol: 'none' }
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
