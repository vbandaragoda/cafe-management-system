import { apiRequest } from './client'

export function uploadImage(file, token) {
  const body = new FormData()
  body.append('file', file)
  return apiRequest('/images', { method: 'POST', body, token })
}

export function listProducts({ categoryId, search } = {}) {
  return apiRequest('/products', { query: { categoryId, search } })
}

export function getProduct(id) {
  return apiRequest(`/products/${id}`)
}

export function createProduct({ name, description, price, categoryId, imageUrl, status }, token) {
  return apiRequest('/products', {
    method: 'POST',
    body: { name, description, price, categoryId, imageUrl, status },
    token,
  })
}

export function updateProduct(id, { name, description, price, categoryId, imageUrl, status }, token) {
  return apiRequest(`/products/${id}`, {
    method: 'PUT',
    body: { name, description, price, categoryId, imageUrl, status },
    token,
  })
}

export function toggleProductAvailability(id, token) {
  return apiRequest(`/products/${id}/toggle-availability`, { method: 'PATCH', token })
}

export function deleteProduct(id, token) {
  return apiRequest(`/products/${id}`, { method: 'DELETE', token })
}
