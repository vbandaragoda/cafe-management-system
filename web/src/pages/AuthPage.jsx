import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { auth, icons } from '../assets/images'
import { useApp } from '../context/AppContext'

export default function AuthPage() {
  const [tab, setTab] = useState('signin') // 'signin' | 'register'
  const [showPassword, setShowPassword] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [formError, setFormError] = useState(null)
  const { login, register, authLoading, authError, setAuthError } = useApp()
  const navigate = useNavigate()
  const location = useLocation()
  const from = location.state?.from?.pathname || '/cart'

  const switchTab = (next) => {
    setTab(next)
    setFormError(null)
    setAuthError(null)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setFormError(null)
    setAuthError(null)

    if (tab === 'register' && !name.trim()) {
      setFormError('Please enter your full name.')
      return
    }
    if (!email.trim() || !password) {
      setFormError('Please enter your email and password.')
      return
    }

    try {
      if (tab === 'register') {
        await register(name.trim(), email.trim(), password)
      } else {
        await login(email.trim(), password)
      }
      navigate(from, { replace: true })
    } catch {
      // authError from context already carries the backend's message
    }
  }

  return (
    <div className="bg-cream flex flex-col items-start w-full min-h-screen">
      <Header />

      <div className="flex flex-col lg:flex-row gap-16 items-center justify-center px-6 lg:px-16 py-20 w-full" data-name="auth-container">
        {/* Visual card */}
        <div
          className="bg-espresso relative flex flex-col h-[560px] items-start justify-between overflow-hidden p-10 rounded-3xl shrink-0 w-full lg:w-[480px]"
          data-name="auth-visual-card"
        >
          <img
            alt=""
            className="absolute inset-0 size-full object-cover opacity-30 pointer-events-none"
            src={auth.bgPhoto}
          />
          <div className="relative flex gap-2 items-center">
            <span className="bg-rust flex items-center justify-center rounded-lg shrink-0 size-7">
              <img alt="" className="size-3.5" src={icons.coffee} />
            </span>
            <p className="font-display font-bold text-lg text-white whitespace-nowrap">Caffora</p>
          </div>

          <div className="relative flex flex-col gap-4 items-start w-full">
            <h1 className="font-display font-extrabold leading-[1.2] text-white text-[32px]">
              Every order earns you local points.
            </h1>
            <p className="font-sans text-latte text-[15px] leading-relaxed">
              Create a free account to automatically save your customized coffee preferences, save payment
              options, and track active deliveries.
            </p>
          </div>

          <div className="relative flex gap-3 items-center w-full">
            <img alt="Marcus, Caffora partner barista" className="rounded-full shrink-0 size-10 object-cover" src={auth.avatar} />
            <div className="flex flex-col items-start">
              <p className="font-sans font-semibold text-[13px] text-white">
                "Pickups are 3x faster with our portal"
              </p>
              <p className="font-sans text-mocha text-[11px]">Marcus, Caffora Partner Barista</p>
            </div>
          </div>
        </div>

        {/* Form card */}
        <div
          className="bg-white border border-latte border-solid flex flex-col gap-8 items-start p-10 rounded-3xl shrink-0 w-full lg:w-[480px] shadow-[0px_8px_12px_rgba(46,30,18,0.04)]"
          data-name="auth-form-card"
        >
          <div className="bg-cream flex items-start p-1 rounded-xl shrink-0 w-full" data-name="tabs">
            <button
              type="button"
              onClick={() => switchTab('signin')}
              className={
                tab === 'signin'
                  ? 'bg-white flex flex-1 items-center justify-center min-w-0 py-2.5 rounded-xl font-sans font-bold text-espresso text-sm shadow-[0px_2px_2px_rgba(0,0,0,0.03)]'
                  : 'flex flex-1 items-center justify-center min-w-0 py-2.5 rounded-xl font-sans font-medium text-mocha text-sm'
              }
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={() => switchTab('register')}
              className={
                tab === 'register'
                  ? 'bg-white flex flex-1 items-center justify-center min-w-0 py-2.5 rounded-xl font-sans font-bold text-espresso text-sm shadow-[0px_2px_2px_rgba(0,0,0,0.03)]'
                  : 'flex flex-1 items-center justify-center min-w-0 py-2.5 rounded-xl font-sans font-medium text-mocha text-sm'
              }
            >
              Create Account
            </button>
          </div>

          <form className="flex flex-col gap-5 items-start w-full" onSubmit={handleSubmit}>
            {tab === 'register' && (
              <div className="flex flex-col gap-2 items-start w-full">
                <label className="font-sans font-semibold text-[#3d2b1f] text-[13px]" htmlFor="name">
                  Full Name
                </label>
                <input
                  id="name"
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Elena Woods"
                  className="border border-latte border-solid p-3.5 rounded-lg w-full font-sans text-sm text-espresso placeholder:text-mocha focus:outline-none focus:border-rust"
                />
              </div>
            )}

            <div className="flex flex-col gap-2 items-start w-full">
              <label className="font-sans font-semibold text-[#3d2b1f] text-[13px]" htmlFor="email">
                Email Address
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="e.g. elena.woods@gmail.com"
                autoComplete="email"
                className="border border-latte border-solid p-3.5 rounded-lg w-full font-sans text-sm text-espresso placeholder:text-mocha focus:outline-none focus:border-rust"
              />
            </div>

            <div className="flex flex-col gap-2 items-start w-full">
              <div className="flex items-start justify-between text-[13px] w-full">
                <label className="font-sans font-semibold text-[#3d2b1f]" htmlFor="password">
                  Password
                </label>
                {tab === 'signin' && (
                  <button type="button" className="font-sans text-rust">
                    Forgot?
                  </button>
                )}
              </div>
              <div className="border border-latte border-solid flex items-center justify-between p-3.5 rounded-lg w-full">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  autoComplete={tab === 'signin' ? 'current-password' : 'new-password'}
                  className="flex-1 min-w-0 font-sans text-sm text-espresso placeholder:text-mocha focus:outline-none"
                />
                <button type="button" onClick={() => setShowPassword((v) => !v)} aria-label="Toggle password visibility">
                  <img alt="" className="size-4" src={icons.eye} />
                </button>
              </div>
            </div>

            {(formError || authError) && (
              <p className="font-sans text-sm text-[#b3261e] whitespace-pre-line" role="alert">
                {formError || authError}
              </p>
            )}

            <div className="flex flex-col gap-4 items-start w-full">
              <button
                type="submit"
                disabled={authLoading}
                className="bg-espresso flex items-center justify-center py-3.5 rounded-xl shrink-0 w-full font-sans font-bold text-[15px] text-white hover:opacity-90 transition-opacity disabled:opacity-60"
              >
                {authLoading
                  ? 'Please wait…'
                  : tab === 'signin'
                    ? 'Sign In to Caffora'
                    : 'Create My Account'}
              </button>
              <button
                type="button"
                onClick={() => switchTab(tab === 'signin' ? 'register' : 'signin')}
                className="flex gap-1 items-center justify-center text-[13px] w-full"
              >
                <span className="font-sans text-mocha">
                  {tab === 'signin' ? 'New to our portal?' : 'Already have an account?'}
                </span>
                <span className="font-sans font-semibold text-rust">
                  {tab === 'signin' ? 'Create account instead' : 'Sign in instead'}
                </span>
              </button>
            </div>

            <div className="bg-latte h-px w-full" />

            <div className="flex flex-col gap-3 items-center w-full">
              <p className="font-sans text-mocha text-[13px]">No account needed to order</p>
              <Link
                to="/menu"
                className="border-rust border-[1.5px] border-solid flex items-center justify-center px-6 py-3 rounded-xl w-full font-sans font-bold text-rust text-sm hover:bg-blush transition-colors"
              >
                Continue Browsing as Guest
              </Link>
            </div>
          </form>
        </div>
      </div>

      <Footer />
    </div>
  )
}
