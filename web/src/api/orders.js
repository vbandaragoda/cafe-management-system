import { apiRequest } from './client'

export function placeOrder({ items, tableId, pickupType }, token) {
  return apiRequest('/orders', { method: 'POST', body: { items, tableId, pickupType }, token })
}

export function myOrders(token) {
  return apiRequest('/orders/my', { token })
}

export function getOrder(id, token) {
  return apiRequest(`/orders/${id}`, { token })
}

export function activeOrders(token) {
  return apiRequest('/orders', { token, query: { active: 'true' } })
}

export function updateOrderStatus(id, status, token) {
  return apiRequest(`/orders/${id}/status`, { method: 'PUT', body: { status }, token })
}
