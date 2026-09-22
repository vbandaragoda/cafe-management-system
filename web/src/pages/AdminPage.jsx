import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import Footer from '../components/Footer'
import { icons, adminIcons, adminAvatar } from '../assets/images'
import { useApp } from '../context/AppContext'
import * as productsApi from '../api/products'
import * as categoriesApi from '../api/categories'
import * as ordersApi from '../api/orders'
import * as adminApi from '../api/admin'
import { formatApiError } from '../api/client'

const sidebarItems = [
  { key: 'dashboard', label: 'Live Dashboard', icon: 'chartLine' },
  { key: 'menu', label: 'Manage Menu', icon: 'bookOpen' },
  { key: 'categories', label: 'Manage Categories', icon: 'bookOpen' },
  { key: 'orders', label: 'Manage Orders', icon: 'clipboardList' },
  { key: 'tables', label: 'Tables', icon: 'clipboardList' },
  { key: 'users', label: 'Users', icon: 'chartLine' },
  { key: 'reports', label: 'Reports', icon: 'chartLine' },
  { key: 'settings', label: 'Store Settings', icon: 'settings' },
]

const STATUS_CYCLE = ['PENDING', 'PREPARING', 'READY', 'COMPLETED']
const STATUS_DOT = {
  PENDING: 'bg-[#b58900]',
  PREPARING: 'bg-rust',
  READY: 'bg-[#498500]',
  COMPLETED: 'bg-mocha',
  CANCELLED: 'bg-[#b3261e]',
}

const EMPTY_PRODUCT_FORM = { id: null, name: '', description: '', price: '', categoryId: '', imageUrl: '', status: 'AVAILABLE' }
const EMPTY_CATEGORY_FORM = { id: null, name: '', description: '' }

function AdminHeader({ section, setSection }) {
  const navTabs = [
    { key: 'dashboard', label: 'Dashboard' },
    { key: 'menu', label: 'Manage Menu' },
    { key: 'orders', label: 'Manage Orders' },
  ]
  return (
    <header className="bg-white border-latte border-b border-solid flex items-center justify-between px-6 lg:px-16 py-5 w-full flex-wrap gap-4">
      <Link to="/" className="flex gap-2 items-center shrink-0">
        <div className="bg-rust flex items-center justify-center rounded-xl shrink-0 size-8">
          <img alt="" className="size-[18px]" src={icons.coffee} />
        </div>
        <p className="font-display font-bold text-espresso text-[22px] whitespace-nowrap">Caffora</p>
      </Link>
      <nav className="flex gap-8 items-center shrink-0" aria-label="Admin quick navigation">
        {navTabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setSection(tab.key)}
            className="flex flex-col gap-1 items-center"
          >
            <span
              className={
                section === tab.key
                  ? 'font-sans font-bold text-rust text-[15px]'
                  : 'font-sans font-medium text-mocha text-[15px]'
              }
            >
              {tab.label}
            </span>
            {section === tab.key && <span className="bg-rust h-0.5 w-4" />}
          </button>
        ))}
      </nav>
      <div className="flex gap-3 items-center shrink-0">
        <span className="bg-espresso flex items-start px-2.5 py-1 rounded font-sans font-bold text-white text-xs whitespace-nowrap">
          SYSTEM ADMIN
        </span>
        <img alt="" className="rounded-full size-9 object-cover" src={adminAvatar} />
      </div>
    </header>
  )
}

function Card({ title, subtitle, action, children }) {
  return (
    <div className="bg-white border border-latte border-solid flex flex-col gap-5 items-start p-6 rounded-2xl shrink-0 w-full overflow-x-auto">
      {(title || action) && (
        <div className="flex items-center justify-between w-full flex-wrap gap-3">
          <div className="flex flex-col gap-1 items-start">
            {title && <h2 className="font-display font-bold text-espresso text-lg">{title}</h2>}
            {subtitle && <p className="font-sans text-mocha text-[13px]">{subtitle}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </div>
  )
}

export default function AdminPage() {
  const { token, products, productsLoading, productsError, refreshProducts, categories, categoriesLoading, categoriesError, refreshCategories } = useApp()
  const [section, setSection] = useState('dashboard')

  // Dashboard
  const [dashboardData, setDashboardData] = useState(null)
  const [dashboardLoading, setDashboardLoading] = useState(true)
  const [dashboardErr, setDashboardErr] = useState(null)

  // Orders queue
  const [queue, setQueue] = useState([])
  const [queueLoading, setQueueLoading] = useState(true)
  const [queueErr, setQueueErr] = useState(null)

  // Product form
  const [productForm, setProductForm] = useState(null) // null = closed
  const [productFormErr, setProductFormErr] = useState(null)
  const [productSaving, setProductSaving] = useState(false)

  // Category form
  const [categoryForm, setCategoryForm] = useState(null)
  const [categoryFormErr, setCategoryFormErr] = useState(null)
  const [categorySaving, setCategorySaving] = useState(false)

  // Tables
  const [tables, setTables] = useState([])
  const [tablesLoading, setTablesLoading] = useState(true)
  const [tablesErr, setTablesErr] = useState(null)
  const [newTableNumber, setNewTableNumber] = useState('')
  const [tableSaving, setTableSaving] = useState(false)
  const [tableFormErr, setTableFormErr] = useState(null)

  // Users
  const [users, setUsers] = useState([])
  const [usersLoading, setUsersLoading] = useState(true)
  const [usersErr, setUsersErr] = useState(null)

  // Reports
  const [topProducts, setTopProducts] = useState([])
  const [topProductsLoading, setTopProductsLoading] = useState(true)
  const [topProductsErr, setTopProductsErr] = useState(null)
  const [salesRange, setSalesRange] = useState('daily')
  const [salesReport, setSalesReport] = useState([])
  const [salesLoading, setSalesLoading] = useState(true)
  const [salesErr, setSalesErr] = useState(null)

  const loadDashboard = () => {
    setDashboardLoading(true)
    setDashboardErr(null)
    adminApi
      .dashboard(token)
      .then(setDashboardData)
      .catch((err) => setDashboardErr(formatApiError(err)))
      .finally(() => setDashboardLoading(false))
  }

  const loadQueue = () => {
    setQueueLoading(true)
    setQueueErr(null)
    ordersApi
      .activeOrders(token)
      .then((data) => setQueue(data ?? []))
      .catch((err) => setQueueErr(formatApiError(err)))
      .finally(() => setQueueLoading(false))
  }

  const loadTables = () => {
    setTablesLoading(true)
    setTablesErr(null)
    adminApi
      .listTables(token)
      .then((data) => setTables(data ?? []))
      .catch((err) => setTablesErr(formatApiError(err)))
      .finally(() => setTablesLoading(false))
  }

  const loadUsers = () => {
    setUsersLoading(true)
    setUsersErr(null)
    adminApi
      .listUsers(token)
      .then((data) => setUsers(data ?? []))
      .catch((err) => setUsersErr(formatApiError(err)))
      .finally(() => setUsersLoading(false))
  }

  const loadTopProducts = () => {
    setTopProductsLoading(true)
    setTopProductsErr(null)
    adminApi
      .topProductsReport(5, token)
      .then((data) => setTopProducts(data ?? []))
      .catch((err) => setTopProductsErr(formatApiError(err)))
      .finally(() => setTopProductsLoading(false))
  }

  const loadSalesReport = (range) => {
    setSalesLoading(true)
    setSalesErr(null)
    adminApi
      .salesReport(range, token)
      .then((data) => setSalesReport(data ?? []))
      .catch((err) => setSalesErr(formatApiError(err)))
      .finally(() => setSalesLoading(false))
  }

  useEffect(() => {
    if (!token) return
    loadDashboard()
    loadQueue()
    loadTables()
    loadUsers()
    loadTopProducts()
    loadSalesReport(salesRange)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token])

  useEffect(() => {
    if (!token) return
    loadSalesReport(salesRange)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [salesRange])

  const cycleStatus = async (order) => {
    const nextIdx = (STATUS_CYCLE.indexOf(order.status) + 1) % STATUS_CYCLE.length
    const nextStatus = STATUS_CYCLE[nextIdx]
    try {
      await ordersApi.updateOrderStatus(order.id, nextStatus, token)
      loadQueue()
      loadDashboard()
    } catch (err) {
      setQueueErr(formatApiError(err))
    }
  }

  // --- Product CRUD -------------------------------------------------------

  const openAddProduct = () => {
    setProductFormErr(null)
    setProductForm({ ...EMPTY_PRODUCT_FORM, categoryId: categories[0]?.id ?? '' })
  }

  const openEditProduct = (item) => {
    setProductFormErr(null)
    setProductForm({
      id: item.id,
      name: item.name,
      description: item.description ?? '',
      price: String(item.price ?? ''),
      categoryId: item.categoryId ?? '',
      imageUrl: item.imageUrl ?? '',
      status: item.status ?? 'AVAILABLE',
    })
  }

  const closeProductForm = () => {
    setProductForm(null)
    setProductFormErr(null)
  }

  const saveProduct = async (e) => {
    e.preventDefault()
    if (!productForm.name.trim() || !productForm.categoryId || !productForm.price) {
      setProductFormErr('Name, category, and price are required.')
      return
    }
    setProductSaving(true)
    setProductFormErr(null)
    const payload = {
      name: productForm.name.trim(),
      description: productForm.description.trim(),
      price: Number(productForm.price),
      categoryId: productForm.categoryId,
      imageUrl: productForm.imageUrl.trim(),
      status: productForm.status,
    }
    try {
      if (productForm.imageFile) {
        const uploaded = await productsApi.uploadImage(productForm.imageFile, token)
        payload.imageUrl = uploaded.imageUrl
        setProductForm((form) => ({ ...form, imageUrl: uploaded.imageUrl, imageFile: null }))
      }
      if (productForm.id) {
        await productsApi.updateProduct(productForm.id, payload, token)
      } else {
        await productsApi.createProduct(payload, token)
      }
      await refreshProducts()
      closeProductForm()
    } catch (err) {
      setProductFormErr(formatApiError(err))
    } finally {
      setProductSaving(false)
    }
  }

  const toggleAvailability = async (item) => {
    try {
      await productsApi.toggleProductAvailability(item.id, token)
      await refreshProducts()
    } catch (err) {
      setProductFormErr(formatApiError(err))
    }
  }

  const deleteProduct = async (item) => {
    try {
      await productsApi.deleteProduct(item.id, token)
      await refreshProducts()
    } catch (err) {
      // e.g. 409 when a product is referenced by existing orders
      setProductFormErr(formatApiError(err))
    }
  }

  // --- Category CRUD -------------------------------------------------------

  const openAddCategory = () => {
    setCategoryFormErr(null)
    setCategoryForm({ ...EMPTY_CATEGORY_FORM })
  }

  const openEditCategory = (cat) => {
    setCategoryFormErr(null)
    setCategoryForm({ id: cat.id, name: cat.name, description: cat.description ?? '' })
  }

  const closeCategoryForm = () => {
    setCategoryForm(null)
    setCategoryFormErr(null)
  }

  const saveCategory = async (e) => {
    e.preventDefault()
    if (!categoryForm.name.trim()) {
      setCategoryFormErr('Category name is required.')
      return
    }
    setCategorySaving(true)
    setCategoryFormErr(null)
    const payload = { name: categoryForm.name.trim(), description: categoryForm.description.trim() }
    try {
      if (categoryForm.id) {
        await categoriesApi.updateCategory(categoryForm.id, payload, token)
      } else {
        await categoriesApi.createCategory(payload, token)
      }
      await refreshCategories()
      closeCategoryForm()
    } catch (err) {
      setCategoryFormErr(formatApiError(err))
    } finally {
      setCategorySaving(false)
    }
  }

  const deleteCategory = async (cat) => {
    try {
      await categoriesApi.deleteCategory(cat.id, token)
      await refreshCategories()
    } catch (err) {
      // e.g. 409 when products still reference this category
      setCategoryFormErr(formatApiError(err))
    }
  }

  // --- Tables ---------------------------------------------------------------

  const addTable = async (e) => {
    e.preventDefault()
    if (!newTableNumber.trim()) {
      setTableFormErr('Table number is required.')
      return
    }
    setTableSaving(true)
    setTableFormErr(null)
    try {
      await adminApi.createTable(newTableNumber.trim(), token)
      setNewTableNumber('')
      loadTables()
    } catch (err) {
      setTableFormErr(formatApiError(err))
    } finally {
      setTableSaving(false)
    }
  }

  const grossSales = dashboardData?.todaysGrossSales ?? 0
  const activeCount = dashboardData?.activeOrderCount ?? queue.length
  const completedToday = dashboardData?.completedTodayCount ?? 0
  const avgPrep = dashboardData?.averagePrepMinutes

  return (
    <div className="bg-cream flex flex-col items-start w-full min-h-screen">
      <AdminHeader section={section} setSection={setSection} />

      <div className="flex flex-col lg:flex-row gap-8 items-start px-6 lg:px-16 py-12 w-full">
        <aside className="bg-white border border-latte border-solid flex flex-col gap-2 items-start p-4 rounded-2xl shrink-0 w-full lg:w-[260px]">
          <p className="font-display font-bold text-mocha text-xs uppercase">Cafe Operations</p>
          {sidebarItems.map((item) => (
            <button
              key={item.key}
              type="button"
              onClick={() => setSection(item.key)}
              aria-current={section === item.key ? 'page' : undefined}
              className={
                section === item.key
                  ? 'bg-[#f4ede4] flex gap-3 items-center px-4 py-3 rounded-lg shrink-0 w-full font-sans font-bold text-espresso text-sm'
                  : 'flex gap-3 items-center px-4 py-3 rounded-lg shrink-0 w-full font-sans font-medium text-mocha text-sm hover:bg-cream transition-colors'
              }
            >
              <img alt="" className="size-4" src={adminIcons[item.icon]} />
              <span className="flex-1 text-left">{item.label}</span>
              {item.key === 'orders' && queue.length > 0 && (
                <span className="bg-rust flex items-start px-1.5 py-0.5 rounded font-sans font-bold text-white text-[10px]">
                  {queue.length}
                </span>
              )}
            </button>
          ))}
        </aside>

        <div className="flex flex-1 flex-col gap-8 items-start min-w-0 w-full">
          <h1 className="sr-only">Cafe admin console — {sidebarItems.find((s) => s.key === section)?.label}</h1>

          {section === 'dashboard' && (
            <>
              <div className="flex flex-col md:flex-row gap-5 items-start w-full">
                <div className="bg-white border border-latte border-solid flex flex-1 flex-col gap-3 items-start p-5 rounded-2xl w-full">
                  <p className="font-sans text-mocha text-[13px]">Today's Gross Sales</p>
                  <p className="font-display font-extrabold text-espresso text-[28px]">${Number(grossSales).toFixed(2)}</p>
                </div>
                <div className="bg-white border border-latte border-solid flex flex-1 flex-col gap-3 items-start p-5 rounded-2xl w-full">
                  <p className="font-sans text-mocha text-[13px]">Incoming Orders Queue</p>
                  <p className="font-display font-extrabold text-espresso text-[28px]">{activeCount} Active</p>
                  <p className="font-sans text-mocha text-xs">{completedToday} completed today</p>
                </div>
                <div className="bg-white border border-latte border-solid flex flex-1 flex-col gap-3 items-start p-5 rounded-2xl w-full">
                  <p className="font-sans text-mocha text-[13px]">Avg Prep Completion</p>
                  <p className="font-display font-extrabold text-espresso text-[28px]">
                    {avgPrep != null ? `${avgPrep} minutes` : '—'}
                  </p>
                </div>
              </div>
              {dashboardLoading && <p className="font-sans text-mocha text-sm">Loading dashboard…</p>}
              {dashboardErr && <p className="font-sans text-sm text-[#b3261e]">{dashboardErr}</p>}
            </>
          )}

          {section === 'menu' && (
            <Card
              title="Manage Menu Items"
              subtitle="Browse, add, edit, or toggle availability of coffee & pastries."
              action={
                <button
                  type="button"
                  onClick={openAddProduct}
                  className="bg-espresso flex gap-2 items-center px-4 py-2 rounded-lg shrink-0 font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity"
                >
                  <img alt="" className="size-3" src={adminIcons.plus} />
                  Add Item
                </button>
              }
            >
              {productFormErr && !productForm && (
                <p className="font-sans text-sm text-[#b3261e] w-full">{productFormErr}</p>
              )}

              {productForm && (
                <form
                  onSubmit={saveProduct}
                  className="bg-cream border border-latte border-solid flex flex-col gap-4 items-start p-4 rounded-xl w-full"
                >
                  <p className="font-display font-bold text-espresso text-sm">
                    {productForm.id ? 'Edit Item' : 'New Item'}
                  </p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full">
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-name">
                        Name
                      </label>
                      <input
                        id="p-name"
                        type="text"
                        value={productForm.name}
                        onChange={(e) => setProductForm((f) => ({ ...f, name: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-category">
                        Category
                      </label>
                      <select
                        id="p-category"
                        value={productForm.categoryId}
                        onChange={(e) => setProductForm((f) => ({ ...f, categoryId: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      >
                        <option value="" disabled>
                          Select a category…
                        </option>
                        {categories.map((cat) => (
                          <option key={cat.id} value={cat.id}>
                            {cat.name}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-price">
                        Price ($)
                      </label>
                      <input
                        id="p-price"
                        type="number"
                        min="0"
                        step="0.01"
                        value={productForm.price}
                        onChange={(e) => setProductForm((f) => ({ ...f, price: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-status">
                        Status
                      </label>
                      <select
                        id="p-status"
                        value={productForm.status}
                        onChange={(e) => setProductForm((f) => ({ ...f, status: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      >
                        <option value="AVAILABLE">Available</option>
                        <option value="SOLD_OUT">Sold Out</option>
                      </select>
                    </div>
                    <div className="flex flex-col gap-1.5 items-start sm:col-span-2">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-image">
                        Image URL (or upload below)
                      </label>
                      <input
                        id="p-image"
                        type="text"
                        value={productForm.imageUrl}
                        onChange={(e) => setProductForm((f) => ({ ...f, imageUrl: e.target.value }))}
                        placeholder="https://…"
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                      <label htmlFor="p-upload" className="font-sans text-sm">Upload product image</label>
                      <input
                        id="p-upload"
                        type="file"
                        accept="image/jpeg,image/png"
                        disabled={productSaving}
                        onChange={(e) => {
                          const file = e.target.files?.[0]
                          if (file && (!['image/jpeg', 'image/png'].includes(file.type) || file.size > 5 * 1024 * 1024)) {
                            setProductFormErr('Choose a JPEG or PNG image up to 5 MB.')
                            e.target.value = ''
                            setProductForm((f) => ({ ...f, imageFile: null }))
                            return
                          }
                          setProductFormErr(null)
                          setProductForm((f) => ({ ...f, imageFile: file ?? null }))
                        }}
                      />
                      <p className="font-sans text-xs text-mocha">JPEG or PNG, up to 5 MB and 16 megapixels. The selected file uploads when you save.</p>
                    </div>
                    <div className="flex flex-col gap-1.5 items-start sm:col-span-2">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="p-desc">
                        Description
                      </label>
                      <textarea
                        id="p-desc"
                        value={productForm.description}
                        onChange={(e) => setProductForm((f) => ({ ...f, description: e.target.value }))}
                        rows={2}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                    </div>
                  </div>
                  {productFormErr && <p className="font-sans text-sm text-[#b3261e] whitespace-pre-line">{productFormErr}</p>}
                  <div className="flex gap-3 items-center">
                    <button
                      type="submit"
                      disabled={productSaving}
                      className="bg-rust flex items-start px-4 py-2 rounded-lg font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity disabled:opacity-60"
                    >
                      {productSaving ? 'Saving…' : 'Save Item'}
                    </button>
                    <button
                      type="button"
                      onClick={closeProductForm}
                      className="border border-latte border-solid flex items-start px-4 py-2 rounded-lg font-sans font-bold text-mocha text-[13px]"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}

              {productsLoading ? (
                <p className="font-sans text-mocha text-sm">Loading menu items…</p>
              ) : productsError ? (
                <p className="font-sans text-sm text-[#b3261e]">{productsError}</p>
              ) : (
                <table className="w-full min-w-[640px] font-sans">
                  <thead>
                    <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                      <th className="p-3 text-left">Item Name</th>
                      <th className="p-3 text-left w-[140px]">Category</th>
                      <th className="p-3 text-left w-20">Price</th>
                      <th className="p-3 text-left w-[120px]">Status</th>
                      <th className="p-3 text-right w-[100px]">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {products.map((item) => (
                      <tr key={item.id} className="border-latte border-b border-solid">
                        <td className="p-3 font-display font-bold text-espresso text-sm">{item.name}</td>
                        <td className="p-3 font-sans text-mocha text-[13px]">{item.categoryName}</td>
                        <td className="p-3 font-display font-bold text-[#3d2b1f] text-[13px]">${Number(item.price).toFixed(2)}</td>
                        <td className="p-3">
                          <button
                            type="button"
                            onClick={() => toggleAvailability(item)}
                            className={
                              item.status === 'AVAILABLE'
                                ? 'bg-[#eaf2df] flex items-start px-2 py-1 rounded font-sans font-bold text-[#498500] text-[11px]'
                                : 'bg-latte flex items-start px-2 py-1 rounded font-sans font-bold text-mocha text-[11px]'
                            }
                          >
                            {item.status === 'AVAILABLE' ? 'Available' : 'Sold Out'}
                          </button>
                        </td>
                        <td className="p-3">
                          <div className="flex gap-3 items-center justify-end">
                            <button type="button" onClick={() => openEditProduct(item)} aria-label={`Edit ${item.name}`}>
                              <img alt="" className="size-3.5" src={adminIcons.pen} />
                            </button>
                            <button type="button" onClick={() => deleteProduct(item)} aria-label={`Delete ${item.name}`}>
                              <img alt="" className="size-3.5" src={adminIcons.trash} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          )}

          {section === 'categories' && (
            <Card
              title="Manage Categories"
              subtitle="Organize menu items into categories customers can filter by."
              action={
                <button
                  type="button"
                  onClick={openAddCategory}
                  className="bg-espresso flex gap-2 items-center px-4 py-2 rounded-lg shrink-0 font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity"
                >
                  <img alt="" className="size-3" src={adminIcons.plus} />
                  Add Category
                </button>
              }
            >
              {categoryForm && (
                <form
                  onSubmit={saveCategory}
                  className="bg-cream border border-latte border-solid flex flex-col gap-4 items-start p-4 rounded-xl w-full"
                >
                  <p className="font-display font-bold text-espresso text-sm">
                    {categoryForm.id ? 'Edit Category' : 'New Category'}
                  </p>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full">
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="c-name">
                        Name
                      </label>
                      <input
                        id="c-name"
                        type="text"
                        value={categoryForm.name}
                        onChange={(e) => setCategoryForm((f) => ({ ...f, name: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                    </div>
                    <div className="flex flex-col gap-1.5 items-start">
                      <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="c-desc">
                        Description
                      </label>
                      <input
                        id="c-desc"
                        type="text"
                        value={categoryForm.description}
                        onChange={(e) => setCategoryForm((f) => ({ ...f, description: e.target.value }))}
                        className="border border-latte border-solid p-2.5 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                      />
                    </div>
                  </div>
                  {categoryFormErr && <p className="font-sans text-sm text-[#b3261e] whitespace-pre-line">{categoryFormErr}</p>}
                  <div className="flex gap-3 items-center">
                    <button
                      type="submit"
                      disabled={categorySaving}
                      className="bg-rust flex items-start px-4 py-2 rounded-lg font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity disabled:opacity-60"
                    >
                      {categorySaving ? 'Saving…' : 'Save Category'}
                    </button>
                    <button
                      type="button"
                      onClick={closeCategoryForm}
                      className="border border-latte border-solid flex items-start px-4 py-2 rounded-lg font-sans font-bold text-mocha text-[13px]"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}

              {categoryFormErr && !categoryForm && (
                <p className="font-sans text-sm text-[#b3261e] w-full">{categoryFormErr}</p>
              )}

              {categoriesLoading ? (
                <p className="font-sans text-mocha text-sm">Loading categories…</p>
              ) : categoriesError ? (
                <p className="font-sans text-sm text-[#b3261e]">{categoriesError}</p>
              ) : categories.length === 0 ? (
                <p className="font-sans text-mocha text-sm">No categories yet — add the first one.</p>
              ) : (
                <table className="w-full min-w-[480px] font-sans">
                  <thead>
                    <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                      <th className="p-3 text-left">Name</th>
                      <th className="p-3 text-left">Description</th>
                      <th className="p-3 text-right w-[100px]">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {categories.map((cat) => (
                      <tr key={cat.id} className="border-latte border-b border-solid">
                        <td className="p-3 font-display font-bold text-espresso text-sm">{cat.name}</td>
                        <td className="p-3 font-sans text-mocha text-[13px]">{cat.description}</td>
                        <td className="p-3">
                          <div className="flex gap-3 items-center justify-end">
                            <button type="button" onClick={() => openEditCategory(cat)} aria-label={`Edit ${cat.name}`}>
                              <img alt="" className="size-3.5" src={adminIcons.pen} />
                            </button>
                            <button type="button" onClick={() => deleteCategory(cat)} aria-label={`Delete ${cat.name}`}>
                              <img alt="" className="size-3.5" src={adminIcons.trash} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          )}

          {section === 'orders' && (
            <Card
              title="Live Kitchen Queue"
              subtitle="Manage active ticket fulfillment directly at register station."
              action={
                <button type="button" onClick={loadQueue} className="font-sans font-bold text-rust text-xs">
                  Refresh Queue
                </button>
              }
            >
              {queueLoading ? (
                <p className="font-sans text-mocha text-sm">Loading queue…</p>
              ) : queueErr ? (
                <p className="font-sans text-sm text-[#b3261e]">{queueErr}</p>
              ) : queue.length === 0 ? (
                <p className="font-sans text-mocha text-sm">No active orders right now.</p>
              ) : (
                <div className="flex flex-col gap-4 items-start w-full">
                  {queue.map((order) => {
                    const itemsSummary = (order.items ?? [])
                      .map((li) => `${li.quantity ?? li.qty}x ${li.productName ?? li.name ?? `#${li.productId}`}`)
                      .join(', ')
                    return (
                      <div key={order.id} className="bg-cream border border-latte border-solid flex items-center justify-between p-4 rounded-xl shrink-0 w-full flex-wrap gap-4">
                        <div className="flex flex-1 gap-5 items-center min-w-0 flex-wrap">
                          <div className="flex flex-col gap-1 items-start w-24 shrink-0">
                            <p className="font-display font-extrabold text-espresso text-base">#{order.orderNumber ?? order.id}</p>
                            <p className="font-sans text-mocha text-[11px]">
                              {order.pickupType === 'TABLE' ? `Table ${order.tableId ?? ''}` : 'Counter'}
                            </p>
                          </div>
                          <div className="flex flex-1 flex-col gap-1 items-start min-w-0">
                            <p className="font-sans text-mocha text-[13px] truncate">{itemsSummary || '—'}</p>
                          </div>
                        </div>
                        <div className="flex gap-8 items-center shrink-0">
                          <p className="font-display font-extrabold text-espresso text-base whitespace-nowrap">
                            ${Number(order.total ?? 0).toFixed(2)}
                          </p>
                          <button
                            type="button"
                            onClick={() => cycleStatus(order)}
                            className="bg-white border border-latte border-solid flex gap-3 items-center px-4 py-2 rounded-lg shrink-0"
                          >
                            <span className={`${STATUS_DOT[order.status] ?? 'bg-latte'} rounded-full size-2`} />
                            <span className="font-sans font-bold text-espresso text-[13px] whitespace-nowrap capitalize">
                              {(order.status || '').toLowerCase()}
                            </span>
                            <img alt="" className="size-2.5" src={adminIcons.chevronDown} />
                          </button>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </Card>
          )}

          {section === 'tables' && (
            <Card title="Tables" subtitle="Create tables and share their QR code value for printing.">
              <form onSubmit={addTable} className="flex items-end gap-3 flex-wrap w-full">
                <div className="flex flex-col gap-1.5 items-start">
                  <label className="font-sans font-semibold text-[#3d2b1f] text-xs" htmlFor="table-number">
                    Table number
                  </label>
                  <input
                    id="table-number"
                    type="text"
                    value={newTableNumber}
                    onChange={(e) => setNewTableNumber(e.target.value)}
                    placeholder="e.g. 12"
                    className="border border-latte border-solid p-2.5 rounded-lg w-40 font-sans text-sm text-espresso focus:outline-none focus:border-rust"
                  />
                </div>
                <button
                  type="submit"
                  disabled={tableSaving}
                  className="bg-espresso flex items-start px-4 py-2.5 rounded-lg font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity disabled:opacity-60"
                >
                  {tableSaving ? 'Adding…' : 'Add Table'}
                </button>
              </form>
              {tableFormErr && <p className="font-sans text-sm text-[#b3261e] whitespace-pre-line">{tableFormErr}</p>}

              {tablesLoading ? (
                <p className="font-sans text-mocha text-sm">Loading tables…</p>
              ) : tablesErr ? (
                <p className="font-sans text-sm text-[#b3261e]">{tablesErr}</p>
              ) : tables.length === 0 ? (
                <p className="font-sans text-mocha text-sm">No tables yet.</p>
              ) : (
                <table className="w-full min-w-[480px] font-sans">
                  <thead>
                    <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                      <th className="p-3 text-left w-[120px]">Table #</th>
                      <th className="p-3 text-left">QR Code Value (for printing / mobile scan)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tables.map((t) => (
                      <tr key={t.id} className="border-latte border-b border-solid">
                        <td className="p-3 font-display font-bold text-espresso text-sm">{t.tableNumber}</td>
                        <td className="p-3 font-mono text-mocha text-[13px] break-all">{t.qrCodeValue}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          )}

          {section === 'users' && (
            <Card title="Users" subtitle="Read-only list of registered accounts.">
              {usersLoading ? (
                <p className="font-sans text-mocha text-sm">Loading users…</p>
              ) : usersErr ? (
                <p className="font-sans text-sm text-[#b3261e]">{usersErr}</p>
              ) : users.length === 0 ? (
                <p className="font-sans text-mocha text-sm">No users found.</p>
              ) : (
                <table className="w-full min-w-[560px] font-sans">
                  <thead>
                    <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                      <th className="p-3 text-left">Name</th>
                      <th className="p-3 text-left">Email</th>
                      <th className="p-3 text-left w-[100px]">Role</th>
                      <th className="p-3 text-left w-[140px]">Joined</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((u) => (
                      <tr key={u.id} className="border-latte border-b border-solid">
                        <td className="p-3 font-display font-bold text-espresso text-sm">{u.name}</td>
                        <td className="p-3 font-sans text-mocha text-[13px]">{u.email}</td>
                        <td className="p-3">
                          <span
                            className={
                              u.role === 'ADMIN'
                                ? 'bg-blush flex items-start px-2 py-1 rounded font-sans font-bold text-rust text-[11px] w-fit'
                                : 'bg-latte flex items-start px-2 py-1 rounded font-sans font-bold text-mocha text-[11px] w-fit'
                            }
                          >
                            {u.role}
                          </span>
                        </td>
                        <td className="p-3 font-sans text-mocha text-[13px]">
                          {u.createdAt ? new Date(u.createdAt).toLocaleDateString() : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          )}

          {section === 'reports' && (
            <>
              <Card title="Top Products" subtitle="Best sellers by units sold.">
                {topProductsLoading ? (
                  <p className="font-sans text-mocha text-sm">Loading…</p>
                ) : topProductsErr ? (
                  <p className="font-sans text-sm text-[#b3261e]">{topProductsErr}</p>
                ) : topProducts.length === 0 ? (
                  <p className="font-sans text-mocha text-sm">No sales data yet.</p>
                ) : (
                  <table className="w-full min-w-[480px] font-sans">
                    <thead>
                      <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                        <th className="p-3 text-left">Product</th>
                        <th className="p-3 text-left w-[120px]">Units Sold</th>
                        <th className="p-3 text-left w-[120px]">Revenue</th>
                      </tr>
                    </thead>
                    <tbody>
                      {topProducts.map((p) => (
                        <tr key={p.productId} className="border-latte border-b border-solid">
                          <td className="p-3 font-display font-bold text-espresso text-sm">{p.productName}</td>
                          <td className="p-3 font-sans text-mocha text-[13px]">{p.unitsSold}</td>
                          <td className="p-3 font-sans text-mocha text-[13px]">${Number(p.revenue).toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </Card>

              <Card
                title="Sales Report"
                action={
                  <div className="bg-cream flex items-start p-1 rounded-xl shrink-0" role="group" aria-label="Sales report range">
                    {['daily', 'monthly'].map((r) => (
                      <button
                        key={r}
                        type="button"
                        onClick={() => setSalesRange(r)}
                        className={
                          salesRange === r
                            ? 'bg-white flex items-center justify-center px-4 py-2 rounded-lg font-sans font-bold text-espresso text-xs capitalize shadow-[0px_2px_2px_rgba(0,0,0,0.03)]'
                            : 'flex items-center justify-center px-4 py-2 rounded-lg font-sans font-medium text-mocha text-xs capitalize'
                        }
                      >
                        {r}
                      </button>
                    ))}
                  </div>
                }
              >
                {salesLoading ? (
                  <p className="font-sans text-mocha text-sm">Loading…</p>
                ) : salesErr ? (
                  <p className="font-sans text-sm text-[#b3261e]">{salesErr}</p>
                ) : salesReport.length === 0 ? (
                  <p className="font-sans text-mocha text-sm">No sales data yet.</p>
                ) : (
                  <table className="w-full min-w-[480px] font-sans">
                    <thead>
                      <tr className="bg-cream border-latte border-b border-solid text-mocha text-xs font-bold">
                        <th className="p-3 text-left">Period</th>
                        <th className="p-3 text-left w-[120px]">Orders</th>
                        <th className="p-3 text-left w-[140px]">Gross Sales</th>
                      </tr>
                    </thead>
                    <tbody>
                      {salesReport.map((row) => (
                        <tr key={row.period} className="border-latte border-b border-solid">
                          <td className="p-3 font-display font-bold text-espresso text-sm">{row.period}</td>
                          <td className="p-3 font-sans text-mocha text-[13px]">{row.orderCount}</td>
                          <td className="p-3 font-sans text-mocha text-[13px]">${Number(row.grossSales).toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </Card>
            </>
          )}

          {section === 'settings' && (
            <Card title="Store Settings" subtitle="General store configuration.">
              <p className="font-sans text-mocha text-sm">
                Store-wide settings (hours, tax rate, branding) are managed server-side. Nothing to configure here yet.
              </p>
            </Card>
          )}
        </div>
      </div>

      <Footer statusOverride="Logged in as System Admin" />
    </div>
  )
}
