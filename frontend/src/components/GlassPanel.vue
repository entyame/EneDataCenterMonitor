<template>
  <div class="glass-panel">
    <div class="panel-title"><slot name="title">{{ title }}</slot></div>
    <div class="panel-body"><slot /></div>
    <span class="corner-br"></span>
  </div>
</template>

<script setup>
defineProps({ title: { type: String, default: '' } })
</script>
