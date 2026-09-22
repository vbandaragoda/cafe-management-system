import { apiRequest } from './client'

export function register({ name, email, password }) {
  return apiRequest('/auth/register', { method: 'POST', body: { name, email, password } })
}

export function login({ email, password }) {
  return apiRequest('/auth/login', { method: 'POST', body: { email, password } })
}

export function me(token) {
  return apiRequest('/auth/me', { token })
}
