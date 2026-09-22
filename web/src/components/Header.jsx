import { Link, useLocation } from 'react-router-dom'
import { icons, cartAvatar, cartIcons } from '../assets/images'
import { useApp } from '../context/AppContext'

export default function Header() {
  const { pathname, search } = useLocation()
  const { user, isAdmin, logout, totals } = useApp()
  const currentTab = new URLSearchParams(search).get('tab')

  const navItems = [
    { label: 'Home', to: '/', match: () => pathname === '/' },
    { label: 'Menu', to: '/menu', match: () => pathname === '/menu' },
    {
      label: `Cart${totals.count ? ` (${totals.count})` : ''}`,
      to: '/cart',
      match: () => pathname === '/cart' && currentTab !== 'orders',
    },
    {
      label: 'My Orders',
      to: '/cart?tab=orders',
      match: () => pathname === '/cart' && currentTab === 'orders',
    },
    ...(isAdmin ? [{ label: 'Admin', to: '/admin', match: () => pathname === '/admin' }] : []),
  ]

  return (
    <header
      className="bg-white border-latte border-b border-solid flex items-center justify-between px-6 lg:px-16 py-5 w-full flex-wrap gap-4"
      data-name="header"
    >
      <Link to="/" className="flex gap-2 items-center shrink-0" data-name="logo">
        <div className="bg-rust flex items-center justify-center rounded-xl shrink-0 size-8">
          <img alt="" className="size-[18px]" src={icons.coffee} />
        </div>
        <p className="font-display font-bold text-espresso text-[22px] whitespace-nowrap">Caffora</p>
      </Link>

      <nav className="flex gap-8 items-center shrink-0 flex-wrap" data-name="nav-links">
        {navItems.map((item) => {
          const active = item.match()
          return (
            <Link key={item.label} to={item.to} className="flex flex-col gap-1 items-center shrink-0">
              <span
                className={
                  active
                    ? 'font-sans font-bold text-rust text-[15px] whitespace-nowrap'
                    : 'font-sans font-medium text-mocha text-[15px] whitespace-nowrap'
                }
              >
                {item.label}
              </span>
              {active && <span className="bg-rust h-0.5 w-4" />}
            </Link>
          )
        })}
      </nav>

      {user ? (
        <div className="flex gap-3 items-center shrink-0" data-name="user-profile-summary">
          <img alt="" className="rounded-full size-9 object-cover" src={cartAvatar} />
          <div className="flex flex-col items-start whitespace-nowrap">
            <p className="font-sans font-semibold text-[#3d2b1f] text-sm">{user.name}</p>
            <p className="font-sans text-mocha text-[11px]">{isAdmin ? 'Admin account' : user.email}</p>
          </div>
          <button type="button" onClick={logout} aria-label="Log out" className="flex items-center justify-center size-6">
            <img alt="" className="size-4" src={cartIcons.logOut} />
          </button>
        </div>
      ) : (
        <div className="flex gap-4 items-center shrink-0" data-name="user-actions">
          <Link
            to="/auth"
            className="flex items-start px-5 py-2.5 rounded-xl shrink-0 font-sans font-semibold text-espresso text-[15px] whitespace-nowrap hover:bg-cream transition-colors"
          >
            Sign In
          </Link>
          <Link
            to="/auth"
            className="bg-espresso flex items-start px-5 py-2.5 rounded-xl shrink-0 font-sans font-semibold text-white text-[15px] whitespace-nowrap hover:opacity-90 transition-opacity"
          >
            Register
          </Link>
        </div>
      )}
    </header>
  )
}
