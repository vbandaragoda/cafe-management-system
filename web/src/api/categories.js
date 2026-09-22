import { apiRequest } from './client'

export function listCategories() {
  return apiRequest('/categories')
}

export function createCategory({ name, description }, token) {
  return apiRequest('/categories', { method: 'POST', body: { name, description }, token })
}

export function updateCategory(id, { name, description }, token) {
  return apiRequest(`/categories/${id}`, { method: 'PUT', body: { name, description }, token })
}

export function deleteCategory(id, token) {
  return apiRequest(`/categories/${id}`, { method: 'DELETE', token })
}
