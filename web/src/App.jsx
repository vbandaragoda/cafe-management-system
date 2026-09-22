import { Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { AppProvider, useApp } from './context/AppContext'
import HomePage from './pages/HomePage'
import AuthPage from './pages/AuthPage'
import MenuPage from './pages/MenuPage'
import CartOrdersPage from './pages/CartOrdersPage'
import AdminPage from './pages/AdminPage'

// Route guards are UX-only — they keep signed-out/non-admin visitors from
// seeing screens meant for someone else, but the backend is the real
// authority: every protected endpoint re-checks the bearer token and role
// itself, so nothing here should be treated as the actual security boundary.
function RequireAuth({ children }) {
  const { user } = useApp()
  const location = useLocation()
  if (!user) {
    return <Navigate to="/auth" replace state={{ from: location }} />
  }
  return children
}

function RequireAdmin({ children }) {
  const { user, isAdmin } = useApp()
  const location = useLocation()
  if (!user) {
    return <Navigate to="/auth" replace state={{ from: location }} />
  }
  if (!isAdmin) {
    return <Navigate to="/" replace />
  }
  return children
}

export default function App() {
  return (
    <AppProvider>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/auth" element={<AuthPage />} />
        <Route path="/menu" element={<MenuPage />} />
        <Route
          path="/cart"
          element={
            <RequireAuth>
              <CartOrdersPage />
            </RequireAuth>
          }
        />
        <Route
          path="/admin"
          element={
            <RequireAdmin>
              <AdminPage />
            </RequireAdmin>
          }
        />
      </Routes>
    </AppProvider>
  )
}
