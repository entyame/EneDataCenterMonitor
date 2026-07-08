<template>
  <div class="glass-panel kpi-card" :style="{ '--accent': color }">
    <div class="panel-body kpi-body">
      <div class="kpi-icon">{{ icon }}</div>
      <div class="kpi-info">
        <div class="stat-value" :style="{ color: color, textShadow: `0 0 16px ${color}44` }">
          {{ formattedValue }}<span class="stat-unit">{{ unit }}</span>
        </div>
        <div class="stat-label">{{ label }}</div>
      </div>
    </div>
    <span class="corner-br"></span>
  </div>
</template>

<script setup>
import { computed } from 'vue'
const props = defineProps({
  label: String, value: [String, Number], unit: String, icon: String, color: String
})
const formattedValue = computed(() => {
  const v = props.value
  if (v === '--') return '--'
  const n = Number(v)
  return isNaN(n) ? v : (n % 1 === 0 ? n.toLocaleString() : Number(n).toFixed(1))
})
</script>

<style scoped>
.kpi-card {
  border-color: rgba(124, 58, 237, 0.2);
}
.kpi-body {
  display: flex; align-items: center; gap: 14px; height: 100%;
}
.kpi-icon { font-size: 26px; flex-shrink: 0; }
.kpi-info { display: flex; flex-direction: column; gap: 2px; }
</style>
