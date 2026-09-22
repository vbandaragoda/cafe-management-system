import { apiRequest } from './client'

// NOTE: this is a SIMULATED payment step (no real payment gateway is involved).
// The backend just records a "paid" result — see checkout UI copy.
export function pay({ orderId, method }, token) {
  return apiRequest('/payments', { method: 'POST', body: { orderId, method }, token })
}

export function paymentForOrder(orderId, token) {
  return apiRequest(`/payments/order/${orderId}`, { token })
}
