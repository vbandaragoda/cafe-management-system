// Thin fetch wrapper for the Caffora backend (Spring Boot).
//
// - Base URL comes from VITE_API_URL (falls back to the local dev backend).
// - Attaches `Authorization: Bearer <token>` when a token is supplied.
// - Parses JSON bodies and throws a typed ApiError on any non-2xx response,
//   surfacing the backend's { status, message, fieldErrors, timestamp, path }
//   shape so callers/UI can show a real message instead of a raw stack trace.

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'

export class ApiError extends Error {
  constructor(message, { status, fieldErrors, path } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.fieldErrors = fieldErrors
    this.path = path
  }
}

/**
 * @param {string} path e.g. '/products' (leading slash) — joined with API_BASE_URL
 * @param {object} [options]
 * @param {string} [options.method]
 * @param {object} [options.body] plain object, JSON-encoded
 * @param {string|null} [options.token] bearer token to attach, when present
 * @param {Record<string,string>} [options.query] query-string params (falsy values skipped)
 */
export async function apiRequest(path, { method = 'GET', body, token, query } = {}) {
  let url = `${API_BASE_URL}${path}`
  if (query && Object.keys(query).length) {
    const params = new URLSearchParams()
    Object.entries(query).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') params.set(key, value)
    })
    const qs = params.toString()
    if (qs) url += `?${qs}`
  }

  const headers = { Accept: 'application/json' }
  const isFormData = body instanceof FormData
  if (body !== undefined && !isFormData) headers['Content-Type'] = 'application/json'
  if (token) headers.Authorization = `Bearer ${token}`

  let response
  try {
    response = await fetch(url, {
      method,
      headers,
      body: isFormData ? body : body !== undefined ? JSON.stringify(body) : undefined,
    })
  } catch (networkErr) {
    throw new ApiError('Unable to reach the server. Please check your connection and try again.', {
      status: 0,
    })
  }

  const text = await response.text()
  let data = null
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = null
    }
  }

  if (!response.ok) {
    const message = data?.message || `Request failed (${response.status})`
    throw new ApiError(message, {
      status: response.status,
      fieldErrors: data?.fieldErrors,
      path: data?.path,
    })
  }

  return data
}

/** Formats an ApiError (or any error) into user-facing copy: message + one field error per line. */
export function formatApiError(err) {
  if (!err) return 'Something went wrong.'
  const lines = [err.message || 'Something went wrong.']
  if (err.fieldErrors && typeof err.fieldErrors === 'object') {
    Object.entries(err.fieldErrors).forEach(([field, msg]) => {
      lines.push(`${field}: ${msg}`)
    })
  }
  return lines.join('\n')
}
