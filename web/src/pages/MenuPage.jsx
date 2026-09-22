import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { menuIcons } from '../assets/images'
import { useApp } from '../context/AppContext'

export default function MenuPage() {
  const { user, products, productsLoading, productsError, categories, addToCart } = useApp()
  const [search, setSearch] = useState('')
  const [categoryId, setCategoryId] = useState('all')
  const [addedId, setAddedId] = useState(null)

  const filtered = useMemo(() => {
    return products.filter((item) => {
      const matchesCategory = categoryId === 'all' || String(item.categoryId) === String(categoryId)
      const matchesSearch = item.name.toLowerCase().includes(search.toLowerCase())
      return matchesCategory && matchesSearch
    })
  }, [products, categoryId, search])

  const handleAdd = (item) => {
    if (item.status === 'SOLD_OUT') return
    addToCart(item)
    setAddedId(item.id)
    setTimeout(() => setAddedId((id) => (id === item.id ? null : id)), 1200)
  }

  return (
    <div className="bg-cream flex flex-col items-start w-full min-h-screen">
      <Header />

      {!user && (
        <div
          className="bg-[#faf3db] border-latte border-b border-solid flex items-center justify-between px-6 lg:px-16 py-4 w-full flex-wrap gap-3"
          data-name="warning-toast"
        >
          <div className="flex gap-3 items-center flex-wrap">
            <span className="bg-[#b58900] flex items-center justify-center rounded-xl shrink-0 size-6">
              <img alt="" className="size-3" src={menuIcons.alertTriangle} />
            </span>
            <p className="font-sans font-semibold text-espresso text-sm whitespace-nowrap">You are browsing as a guest.</p>
            <p className="font-sans text-[#3d2b1f] text-sm">
              You can customize and explore items, but checking out requires a quick login.
            </p>
          </div>
          <Link to="/auth" className="flex gap-2 items-center shrink-0">
            <span className="font-sans font-bold text-rust text-[13px] underline whitespace-nowrap">Login Now</span>
            <img alt="" className="size-3" src={menuIcons.chevronRight} />
          </Link>
        </div>
      )}

      <div
        className="bg-white border-latte border-b border-solid flex items-center justify-between px-6 lg:px-16 py-6 w-full flex-wrap gap-4"
        data-name="search-filters-bar"
      >
        <div className="bg-cream flex gap-3 items-center px-4 py-3 rounded-lg shrink-0 w-full sm:w-80">
          <img alt="" className="size-4" src={menuIcons.search} />
          <label htmlFor="menu-search" className="sr-only">
            Search the menu
          </label>
          <input
            id="menu-search"
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search flat white, sourdough..."
            className="bg-transparent font-sans text-mocha text-sm placeholder:text-mocha focus:outline-none w-full"
          />
        </div>
        <div className="flex gap-3 items-start flex-wrap" data-name="categories">
          <button
            type="button"
            onClick={() => setCategoryId('all')}
            className={
              categoryId === 'all'
                ? 'bg-espresso flex items-start px-5 py-2.5 rounded-full shrink-0 font-sans font-bold text-white text-[13px] whitespace-nowrap'
                : 'bg-white border border-latte border-solid flex items-start px-5 py-2.5 rounded-full shrink-0 font-sans font-medium text-mocha text-[13px] whitespace-nowrap hover:border-rust transition-colors'
            }
          >
            All Items
          </button>
          {categories.map((cat) => (
            <button
              key={cat.id}
              type="button"
              onClick={() => setCategoryId(cat.id)}
              className={
                String(cat.id) === String(categoryId)
                  ? 'bg-espresso flex items-start px-5 py-2.5 rounded-full shrink-0 font-sans font-bold text-white text-[13px] whitespace-nowrap'
                  : 'bg-white border border-latte border-solid flex items-start px-5 py-2.5 rounded-full shrink-0 font-sans font-medium text-mocha text-[13px] whitespace-nowrap hover:border-rust transition-colors'
              }
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-8 items-start px-6 lg:px-16 py-12 w-full" data-name="menu-grid-section">
        <h1 className="font-display font-extrabold text-espresso text-[28px]">Our Full Artisanal Menu</h1>
        {productsLoading ? (
          <p className="font-sans text-mocha text-sm">Loading the menu…</p>
        ) : productsError ? (
          <p className="font-sans text-sm text-[#b3261e]">{productsError}</p>
        ) : filtered.length === 0 ? (
          <p className="font-sans text-mocha text-sm">No items match your search.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 w-full">
            {filtered.map((item) => {
              const soldOut = item.status === 'SOLD_OUT'
              return (
                <div
                  key={item.id}
                  className="bg-white border border-latte border-solid flex flex-col justify-between overflow-hidden rounded-2xl"
                >
                  <div className="h-[220px] w-full relative">
                    <img alt={item.name} className="size-full object-cover" src={item.imageUrl} />
                    {soldOut && (
                      <span className="absolute top-3 right-3 bg-espresso/80 text-white text-[11px] font-sans font-bold px-2 py-1 rounded">
                        Sold Out
                      </span>
                    )}
                  </div>
                  <div className="flex flex-col gap-3 items-start p-5 w-full">
                    <div className="flex font-display font-bold items-start justify-between text-lg w-full">
                      <p className="flex-1 min-w-0 truncate text-espresso">{item.name}</p>
                      <p className="shrink-0 text-rust">${item.price.toFixed(2)}</p>
                    </div>
                    <p className="font-sans text-mocha text-[13px] leading-snug h-[54px] overflow-hidden">{item.description}</p>
                    <div className="bg-latte h-px w-full" />
                    <div className="flex items-center justify-between w-full">
                      <span className="font-sans text-mocha text-[11px]">{item.categoryName}</span>
                      <button
                        type="button"
                        disabled={soldOut}
                        onClick={() => handleAdd(item)}
                        className={
                          soldOut
                            ? 'bg-latte flex gap-2 items-center px-4 py-2 rounded-lg shrink-0 font-sans font-bold text-mocha text-[13px] cursor-not-allowed'
                            : 'bg-rust flex gap-2 items-center px-4 py-2 rounded-lg shrink-0 font-sans font-bold text-white text-[13px] hover:opacity-90 transition-opacity'
                        }
                      >
                        <img alt="" className="size-3" src={menuIcons.shoppingBag} />
                        {addedId === item.id ? 'Added!' : soldOut ? 'Sold Out' : 'Add to Cart'}
                      </button>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      <Footer />
    </div>
  )
}
