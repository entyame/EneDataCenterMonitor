<template>
  <div ref="chartRoot" class="chart-box"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { fetchRooms } from '../api/dashboard'

const chartRoot = ref(null)
let chart = null, timer = null

async function load() {
  try {
    const res = await fetchRooms()
    if (!res.success || !res.data.length) return
    const raw = res.data.map(r => ({
      name: r.room.replace('机房', ''),
      value: r.host_count
    }))
    // 按 A B C D E 顺序排列
    const data = raw.sort((a, b) => a.name.localeCompare(b.name))
    chart.setOption({
      tooltip: { trigger: 'item', formatter: '{b}机房: {c} 台 ({d}%)' },
      legend: { bottom: -10, textStyle: { color: '#94a3b8', fontSize: 9 } },
      series: [{
        type: 'pie', radius: ['40%', '60%'], center: ['50%', '43%'],
        data,
        label: { color: '#e2e8f0', fontSize: 9, formatter: '{d}%' },
        labelLine: { lineStyle: { color: 'rgba(124,58,237,0.3)' } },
        itemStyle: {
          borderRadius: 3,
          borderColor: '#0a0a1a', borderWidth: 3
        },
        emphasis: {
          label: { fontSize: 16, fontWeight: 'bold' },
          scaleSize: 8
        }
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
