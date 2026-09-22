import { apiRequest } from './client'

export function dashboard(token) {
  return apiRequest('/admin/dashboard', { token })
}

export function salesReport(range, token) {
  return apiRequest('/admin/reports/sales', { token, query: { range } })
}

export function topProductsReport(limit, token) {
  return apiRequest('/admin/reports/top-products', { token, query: { limit } })
}

export function listUsers(token) {
  return apiRequest('/admin/users', { token })
}

export function listTables(token) {
  return apiRequest('/tables', { token })
}

export function createTable(tableNumber, token) {
  return apiRequest('/tables', { method: 'POST', body: { tableNumber }, token })
}
