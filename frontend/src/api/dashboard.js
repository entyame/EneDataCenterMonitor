// ============================================================
// Dashboard API — Axios 封装
// 代理到后端 http://localhost:8080
// ============================================================
import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' }
})

// 响应拦截：统一提取 data
api.interceptors.response.use(
  res => res.data,
  err => {
    console.error('API 请求失败:', err.message)
    return Promise.reject(err)
  }
)

export function fetchKpi()         { return api.get('/kpi') }
export function fetchCpuHour()     { return api.get('/cpu/hour') }
export function fetchMemoryHour()  { return api.get('/memory/hour') }
export function fetchNetworkHour() { return api.get('/network/hour') }
export function fetchLoadHour()    { return api.get('/load/hour') }
export function fetchDiskHour()    { return api.get('/disk/hour') }
export function fetchHostsRank(type = 'cpu', top = 10) {
  return api.get('/hosts/rank', { params: { type, top } })
}
export function fetchRooms()       { return api.get('/rooms') }
export function fetchAlerts()      { return api.get('/alerts') }
