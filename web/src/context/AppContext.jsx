import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import * as authApi from '../api/auth'
import * as productsApi from '../api/products'
import * as categoriesApi from '../api/categories'
import * as ordersApi from '../api/orders'
import * as paymentsApi from '../api/payments'
import { ApiError, formatApiError } from '../api/client'

const AppContext = createContext(null)

const TAX_RATE = 0.08
const PICKUP_FEE = 0.5
const STORAGE_KEY = 'caffora-state-v1'

function loadPersisted() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export function AppProvider({ children }) {
  const persisted = useMemo(loadPersisted, [])
  const [user, setUser] = useState(persisted?.user ?? null) // null = guest, else { id, name, email, role }
  const [token, setToken] = useState(persisted?.token ?? null)
  const [cart, setCart] = useState(persisted?.cart ?? []) // [{ id, name, price, img, note, qty }] — id = productId

  // Shared catalog data (public endpoints), loaded once and reusable by Home/Menu/Admin.
  const [products, setProducts] = useState([])
  const [productsLoading, setProductsLoading] = useState(true)
  const [productsError, setProductsError] = useState(null)

  const [categories, setCategories] = useState([])
  const [categoriesLoading, setCategoriesLoading] = useState(true)
  const [categoriesError, setCategoriesError] = useState(null)

  // Order history for the signed-in user, and the state around placing a new one.
  const [myOrders, setMyOrders] = useState([])
  const [ordersLoading, setOrdersLoading] = useState(false)
  const [ordersError, setOrdersError] = useState(null)
  const [placingOrder, setPlacingOrder] = useState(false)
  const [placeOrderError, setPlaceOrderError] = useState(null)

  // Persist the durable slice of state (auth + cart) across reloads.
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ user, token, cart }))
    } catch {
      // ignore write failures (e.g. private browsing)
    }
  }, [user, token, cart])

  const refreshProducts = useCallback(async (params) => {
    setProductsLoading(true)
    setProductsError(null)
    try {
      const data = await productsApi.listProducts(params)
      setProducts(data ?? [])
      return data
    } catch (err) {
      setProductsError(formatApiError(err))
      throw err
    } finally {
      setProductsLoading(false)
    }
  }, [])

  const refreshCategories = useCallback(async () => {
    setCategoriesLoading(true)
    setCategoriesError(null)
    try {
      const data = await categoriesApi.listCategories()
      setCategories(data ?? [])
      return data
    } catch (err) {
      setCategoriesError(formatApiError(err))
      throw err
    } finally {
      setCategoriesLoading(false)
    }
  }, [])

  useEffect(() => {
    refreshProducts().catch(() => {})
    refreshCategories().catch(() => {})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const refreshOrders = useCallback(async () => {
    if (!token) {
      setMyOrders([])
      return []
    }
    setOrdersLoading(true)
    setOrdersError(null)
    try {
      const data = await ordersApi.myOrders(token)
      const sorted = [...(data ?? [])].sort(
        (a, b) => new Date(b.placedAt ?? 0) - new Date(a.placedAt ?? 0),
      )
      setMyOrders(sorted)
      return sorted
    } catch (err) {
      setOrdersError(formatApiError(err))
      throw err
    } finally {
      setOrdersLoading(false)
    }
  }, [token])

  useEffect(() => {
    if (token) {
      refreshOrders().catch(() => {})
    } else {
      setMyOrders([])
    }
  }, [token, refreshOrders])

  // --- Auth -------------------------------------------------------------

  const [authLoading, setAuthLoading] = useState(false)
  const [authError, setAuthError] = useState(null)

  const applySession = (session) => {
    setUser(session.user)
    setToken(session.token)
  }

  const login = async (email, password) => {
    setAuthLoading(true)
    setAuthError(null)
    try {
      const session = await authApi.login({ email, password })
      applySession(session)
      return session
    } catch (err) {
      setAuthError(formatApiError(err))
      throw err
    } finally {
      setAuthLoading(false)
    }
  }

  const register = async (name, email, password) => {
    setAuthLoading(true)
    setAuthError(null)
    try {
      const session = await authApi.register({ name, email, password })
      applySession(session)
      return session
    } catch (err) {
      setAuthError(formatApiError(err))
      throw err
    } finally {
      setAuthLoading(false)
    }
  }

  const logout = () => {
    setUser(null)
    setToken(null)
    setMyOrders([])
  }

  // --- Cart (local, client-side for responsiveness) ----------------------

  const addToCart = (product, note = '') => {
    setCart((prev) => {
      const existing = prev.find((line) => line.id === product.id && line.note === note)
      if (existing) {
        return prev.map((line) => (line === existing ? { ...line, qty: line.qty + 1 } : line))
      }
      return [
        ...prev,
        {
          id: product.id,
          name: product.name,
          price: product.price,
          img: product.imageUrl ?? product.img,
          note,
          qty: 1,
        },
      ]
    })
  }

  const updateQty = (id, note, delta) => {
    setCart((prev) =>
      prev
        .map((line) => (line.id === id && line.note === note ? { ...line, qty: line.qty + delta } : line))
        .filter((line) => line.qty > 0),
    )
  }

  const removeFromCart = (id, note) => {
    setCart((prev) => prev.filter((line) => !(line.id === id && line.note === note)))
  }

  const totals = useMemo(() => {
    const subtotal = cart.reduce((sum, line) => sum + line.price * line.qty, 0)
    const fee = cart.length ? PICKUP_FEE : 0
    const tax = subtotal * TAX_RATE
    return {
      subtotal,
      fee,
      tax,
      total: subtotal + fee + tax,
      count: cart.reduce((sum, line) => sum + line.qty, 0),
    }
  }, [cart])

  // --- Orders / checkout --------------------------------------------------

  /**
   * Places the current cart as a real order against the backend, then runs the
   * (simulated) payment step. Server-computed totals are authoritative — the
   * `totals` above are only a client-side estimate shown before checkout.
   */
  const placeOrder = async ({ paymentMethod = 'CASH', pickupType = 'COUNTER', tableId } = {}) => {
    if (cart.length === 0) return null
    if (!token) throw new ApiError('You must be signed in to place an order.', { status: 401 })

    setPlacingOrder(true)
    setPlaceOrderError(null)
    try {
      const items = cart.map((line) => ({
        productId: line.id,
        quantity: line.qty,
        note: line.note || undefined,
      }))
      const order = await ordersApi.placeOrder({ items, tableId, pickupType }, token)
      try {
        await paymentsApi.pay({ orderId: order.id, method: paymentMethod }, token)
      } catch (payErr) {
        // Order was created even if the (simulated) payment call failed — surface it,
        // but don't lose the cart-clearing / order-tracking behavior below.
        setPlaceOrderError(formatApiError(payErr))
      }
      setCart([])
      await refreshOrders()
      return order
    } catch (err) {
      setPlaceOrderError(formatApiError(err))
      throw err
    } finally {
      setPlacingOrder(false)
    }
  }

  const lastOrder = myOrders[0] ?? null

  const value = {
    // auth
    user,
    token,
    isAdmin: user?.role === 'ADMIN',
    login,
    register,
    logout,
    authLoading,
    authError,
    setAuthError,

    // catalog
    products,
    productsLoading,
    productsError,
    refreshProducts,
    categories,
    categoriesLoading,
    categoriesError,
    refreshCategories,

    // cart
    cart,
    addToCart,
    updateQty,
    removeFromCart,
    totals,

    // orders
    myOrders,
    lastOrder,
    ordersLoading,
    ordersError,
    refreshOrders,
    placeOrder,
    placingOrder,
    placeOrderError,
  }

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp must be used within AppProvider')
  return ctx
}
