import { useState } from 'react'
import { Link } from 'react-router-dom'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { home, icons } from '../assets/images'
import { useApp } from '../context/AppContext'

const steps = [
  {
    num: 1,
    title: 'Choose Your Cafe',
    body: 'Select your local Caffora-enabled coffee shop and browse live menus.',
  },
  {
    num: 2,
    title: 'Customize & Pay',
    body: 'Tailor your espresso milk preference, sweetness level, and pay in one tap.',
  },
  {
    num: 3,
    title: 'Grab & Enjoy',
    body: 'Receive real-time notifications on preparation states and collect at bar.',
  },
]

export default function HomePage() {
  const { products, productsLoading, productsError, addToCart } = useApp()
  const [addedId, setAddedId] = useState(null)

  const featured = products.filter((item) => item.status !== 'SOLD_OUT').slice(0, 4)

  const handleAdd = (item) => {
    addToCart(item)
    setAddedId(item.id)
    setTimeout(() => setAddedId((id) => (id === item.id ? null : id)), 1200)
  }

  return (
    <div className="bg-cream flex flex-col items-start w-full min-h-screen">
      <Header />

      {/* Hero */}
      <div className="flex flex-col lg:flex-row gap-16 items-center px-6 lg:px-16 py-20 w-full" data-name="hero">
        <div className="flex flex-1 flex-col gap-8 items-start min-w-0">
          <span className="bg-blush flex items-start px-4 py-1.5 rounded-full shrink-0">
            <span className="font-sans font-bold text-rust text-[13px] uppercase whitespace-nowrap">
              Freshly Brewed Innovation
            </span>
          </span>
          <h1 className="font-display font-extrabold text-espresso text-4xl lg:text-[56px] leading-[1.1]">
            Skip the queue. <span className="text-rust">Savor every drop.</span>
          </h1>
          <p className="font-sans text-mocha text-lg leading-relaxed max-w-xl">
            Experience ordering reimagined. Caffora connects you to your favorite neighborhood brews and warm
            treats with lightning-fast register pick-up, transparent ingredient logs, and friendly rewards.
          </p>
          <div className="flex gap-4 items-start flex-wrap">
            <Link
              to="/menu"
              className="bg-rust flex items-start px-8 py-4 rounded-xl shrink-0 font-sans font-bold text-white text-base whitespace-nowrap hover:opacity-90 transition-opacity"
            >
              Order Now & Skip Line
            </Link>
            <Link
              to="/menu"
              className="border-espresso border-[1.5px] border-solid flex items-start px-8 py-4 rounded-xl shrink-0 font-sans font-bold text-espresso text-base whitespace-nowrap hover:bg-white transition-colors"
            >
              View Local Menu
            </Link>
          </div>
        </div>
        <div className="flex h-[460px] w-full lg:w-[560px] overflow-hidden rounded-3xl shrink-0" data-name="hero-right">
          <img alt="Barista pouring coffee" className="size-full object-cover" src={home.hero} />
        </div>
      </div>

      {/* Benefits */}
      <div
        className="bg-white border-latte border-y border-solid flex flex-col gap-12 items-start p-6 lg:p-16 w-full"
        data-name="benefits-strip"
      >
        <div className="flex flex-col gap-2 items-center text-center w-full">
          <h2 className="font-display font-extrabold text-espresso text-[32px]">Crafted for your busy mornings</h2>
          <p className="font-sans text-mocha text-base max-w-[600px]">
            Three simple steps to the perfect cup without the wait.
          </p>
        </div>
        <div className="flex flex-col md:flex-row gap-8 items-start w-full">
          {steps.map((step) => (
            <div key={step.num} className="bg-cream flex flex-1 flex-col gap-4 items-start p-6 rounded-2xl w-full">
              <span className="bg-rust flex items-center justify-center rounded-[20px] shrink-0 size-10">
                <span className="font-display font-bold text-white text-lg">{step.num}</span>
              </span>
              <p className="font-display font-bold text-espresso text-xl">{step.title}</p>
              <p className="font-sans text-mocha text-sm leading-relaxed">{step.body}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Featured */}
      <div className="flex flex-col gap-10 items-start px-6 lg:px-16 py-20 w-full" data-name="featured-preview">
        <div className="flex items-end justify-between w-full flex-wrap gap-4">
          <div className="flex flex-col gap-2 items-start">
            <h2 className="font-display font-extrabold text-espresso text-[32px]">Today's favorites</h2>
            <p className="font-sans text-mocha text-base">Warmly prepared, local ingredients, outstanding flavor profiles.</p>
          </div>
          <Link
            to="/menu"
            className="border border-rust border-solid flex items-start px-5 py-2.5 rounded-xl shrink-0 font-sans font-semibold text-rust text-sm whitespace-nowrap hover:bg-blush transition-colors"
          >
            Browse Full Menu
          </Link>
        </div>
        {productsLoading ? (
          <p className="font-sans text-mocha text-sm">Loading today's favorites…</p>
        ) : productsError ? (
          <p className="font-sans text-sm text-[#b3261e]">{productsError}</p>
        ) : featured.length === 0 ? (
          <p className="font-sans text-mocha text-sm">No items are available right now — check back soon.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 w-full">
            {featured.map((item) => (
              <div
                key={item.id}
                className="bg-white border border-latte border-solid flex flex-col justify-between overflow-hidden rounded-2xl"
              >
                <div className="h-[200px] w-full">
                  <img alt={item.name} className="size-full object-cover" src={item.imageUrl} />
                </div>
                <div className="flex flex-col gap-4 items-start p-5 w-full">
                  <div className="flex font-display font-bold items-start justify-between text-lg w-full">
                    <p className="flex-1 min-w-0 truncate text-espresso">{item.name}</p>
                    <p className="shrink-0 text-rust">${item.price.toFixed(2)}</p>
                  </div>
                  <p className="font-sans text-mocha text-[13px] leading-snug">{item.description}</p>
                  <div className="flex items-center justify-between w-full">
                    <span className="bg-cream flex items-start px-2.5 py-1 rounded shrink-0">
                      <span className="font-sans font-semibold text-mocha text-[11px]">{item.categoryName}</span>
                    </span>
                    <button
                      type="button"
                      onClick={() => handleAdd(item)}
                      aria-label={addedId === item.id ? `${item.name} added to cart` : `Add ${item.name} to cart`}
                      className="bg-espresso flex items-center justify-center rounded-[14px] shrink-0 size-7 hover:opacity-90 transition-opacity"
                    >
                      <img alt="" className="size-3" src={icons.cart} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <Footer />
    </div>
  )
}
