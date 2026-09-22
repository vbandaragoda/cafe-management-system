import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { cartIcons } from '../assets/images'
import { useApp } from '../context/AppContext'

const STEPS = [
  { key: 'PENDING', title: 'Pending Approval', body: 'Cafe receipt generated and awaiting kitchen queue.' },
  { key: 'PREPARING', title: 'Preparing', body: 'Espresso is pulling and pastries are warming in the oven.' },
  { key: 'READY', title: 'Ready for Pickup', body: 'Collect at the Caffora priority bar.' },
  { key: 'COMPLETED', title: 'Completed', body: 'Successfully collected by you.' },
]

const STEP_ORDER = STEPS.map((s) => s.key)

const PAYMENT_METHODS = [
  { value: 'CASH', label: 'Cash at counter' },
  { value: 'CARD', label: 'Card' },
  { value: 'MOBILE_WALLET', label: 'Mobile wallet' },
]

function formatPlacedAt(value) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return `Placed ${date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })} at ${date.toLocaleTimeString(
    undefined,
    { hour: 'numeric', minute: '2-digit' },
  )}`
}

export default function CartOrdersPage() {
  const {
    cart,
    updateQty,
    removeFromCart,
    totals,
    myOrders,
    lastOrder,
    ordersLoading,
    ordersError,
    placeOrder,
    placingOrder,
    placeOrderError,
  } = useApp()
  const [searchParams, setSearchParams] = useSearchParams()
  const tab = searchParams.get('tab') === 'orders' ? 'orders' : 'cart'
  const setTab = (next) => setSearchParams(next === 'orders' ? { tab: 'orders' } : {})
  const [paymentMethod, setPaymentMethod] = useState('CASH')
  const [checkoutMessage, setCheckoutMessage] = useState(null)

  const currentStepIndex = lastOrder ? STEP_ORDER.indexOf(lastOrder.status) : -1
  const cancelled = lastOrder?.status === 'CANCELLED'

  const handleCheckout = async () => {
    setCheckoutMessage(null)
    try {
      const order = await placeOrder({ paymentMethod, pickupType: 'COUNTER' })
      if (order) {
        setCheckoutMessage(`Order #${order.orderNumber ?? order.id} placed! Track it under "My Orders".`)
        setTab('orders')
      }
    } catch {
      // placeOrderError from context already carries the backend's message
    }
  }

  return (
    <div className="bg-cream flex flex-col items-start w-full min-h-screen">
      <Header />

      <div className="flex flex-col lg:flex-row gap-8 items-start px-6 lg:px-16 py-12 w-full" data-name="cart-page-body">
        <div className="flex flex-1 flex-col gap-6 items-start min-w-0 w-full" data-name="cart-main-col">
          <h1 className="sr-only">Your cart and orders</h1>
          <div className="bg-white border border-latte border-solid flex items-start p-1 rounded-xl shrink-0 w-full" data-name="cart-toggle-bar">
            <button
              type="button"
              onClick={() => setTab('cart')}
              className={
                tab === 'cart'
                  ? 'bg-[#f4ede4] flex flex-1 items-center justify-center min-w-0 py-3 rounded-lg font-sans font-bold text-espresso text-sm'
                  : 'flex flex-1 items-center justify-center min-w-0 py-3 font-sans font-medium text-mocha text-sm'
              }
            >
              Active Cart ({totals.count} items)
            </button>
            <button
              type="button"
              onClick={() => setTab('orders')}
              className={
                tab === 'orders'
                  ? 'bg-[#f4ede4] flex flex-1 items-center justify-center min-w-0 py-3 rounded-lg font-sans font-bold text-espresso text-sm'
                  : 'flex flex-1 items-center justify-center min-w-0 py-3 font-sans font-medium text-mocha text-sm'
              }
            >
              My Orders & Live Tracking
            </button>
          </div>

          {tab === 'cart' ? (
            <>
              <div className="bg-white border border-latte border-solid flex flex-col gap-5 items-start p-6 rounded-2xl shrink-0 w-full" data-name="items-list-card">
                <p className="font-display font-bold text-espresso text-xl">Items in your bag</p>
                {cart.length === 0 && (
                  <p className="font-sans text-mocha text-sm">Your bag is empty — add something delicious from the menu.</p>
                )}
                {cart.map((line, idx) => (
                  <div key={`${line.id}-${line.note}`} className="flex flex-col gap-5 items-start w-full">
                    <div className="flex items-center justify-between w-full flex-wrap gap-3" data-name="cart-item">
                      <div className="flex gap-4 items-center shrink-0">
                        <img alt="" className="rounded-lg shrink-0 size-16 object-cover" src={line.img} />
                        <div className="flex flex-col gap-1 items-start whitespace-nowrap">
                          <p className="font-display font-bold text-espresso text-base">{line.name}</p>
                          <p className="font-sans text-mocha text-[13px]">{line.note || 'No modifications'}</p>
                        </div>
                      </div>
                      <div className="flex gap-8 items-center shrink-0">
                        <div className="bg-cream flex gap-3 items-center px-3 py-1.5 rounded-lg shrink-0 font-sans font-bold text-espresso text-sm">
                          <button type="button" onClick={() => updateQty(line.id, line.note, -1)} aria-label={`Decrease quantity of ${line.name}`}>
                            −
                          </button>
                          <span>{line.qty}</span>
                          <button type="button" onClick={() => updateQty(line.id, line.note, 1)} aria-label={`Increase quantity of ${line.name}`}>
                            +
                          </button>
                        </div>
                        <p className="font-display font-bold text-espresso text-base whitespace-nowrap">
                          ${(line.price * line.qty).toFixed(2)}
                        </p>
                        <button type="button" onClick={() => removeFromCart(line.id, line.note)} aria-label={`Remove ${line.name}`}>
                          <img alt="" className="size-4" src={cartIcons.trash} />
                        </button>
                      </div>
                    </div>
                    {idx < cart.length - 1 && <div className="bg-latte h-px w-full" />}
                  </div>
                ))}
              </div>

              <div className="bg-white border border-latte border-solid flex items-center justify-between p-5 rounded-2xl shrink-0 w-full flex-wrap gap-3" data-name="empty-state-preview">
                <div className="flex gap-3 items-center">
                  <img alt="" className="size-5" src={cartIcons.shoppingBag} />
                  <p className="font-sans font-semibold text-[#3d2b1f] text-sm whitespace-nowrap">Looking for more?</p>
                  <p className="font-sans text-mocha text-sm">Browse the full artisanal menu for today's specials.</p>
                </div>
                <Link to="/menu" className="font-sans font-bold text-rust text-[13px] whitespace-nowrap">
                  Start Ordering →
                </Link>
              </div>
            </>
          ) : (
            <div className="bg-white border border-latte border-solid flex flex-col gap-5 items-start p-6 rounded-2xl shrink-0 w-full">
              <p className="font-display font-bold text-espresso text-xl">Order History</p>
              {ordersLoading ? (
                <p className="font-sans text-mocha text-sm">Loading your orders…</p>
              ) : ordersError ? (
                <p className="font-sans text-sm text-[#b3261e]">{ordersError}</p>
              ) : myOrders.length === 0 ? (
                <p className="font-sans text-mocha text-sm">You haven't placed any orders yet.</p>
              ) : (
                myOrders.map((order) => (
                  <div
                    key={order.id}
                    className="bg-cream border border-latte border-solid flex items-center justify-between p-4 rounded-xl w-full flex-wrap gap-3"
                  >
                    <div className="flex flex-col gap-1 items-start">
                      <p className="font-display font-extrabold text-espresso text-base">#{order.orderNumber ?? order.id}</p>
                      <p className="font-sans text-mocha text-[13px]">{formatPlacedAt(order.placedAt)}</p>
                    </div>
                    <p className="font-display font-extrabold text-espresso text-base">${Number(order.total ?? 0).toFixed(2)}</p>
                    <span className="bg-blush text-rust font-sans font-bold text-xs px-3 py-1 rounded-full capitalize">
                      {(order.status || '').toLowerCase()}
                    </span>
                  </div>
                ))
              )}
            </div>
          )}
        </div>

        <div className="flex flex-col gap-6 items-start shrink-0 w-full lg:w-[440px]" data-name="cart-right-col">
          <div className="bg-white border border-latte border-solid flex flex-col gap-5 items-start p-6 rounded-2xl shrink-0 w-full" data-name="billing-card">
            <p className="font-display font-bold text-espresso text-xl">Order Summary</p>
            <div className="flex flex-col gap-3 items-start w-full">
              <div className="flex font-sans items-start justify-between text-sm w-full">
                <p className="text-mocha">Subtotal</p>
                <p className="text-[#3d2b1f]">${totals.subtotal.toFixed(2)}</p>
              </div>
              <div className="flex font-sans items-start justify-between text-sm w-full">
                <p className="text-mocha">Register Pickup Fee</p>
                <p className="text-[#3d2b1f]">${totals.fee.toFixed(2)}</p>
              </div>
              <div className="flex font-sans items-start justify-between text-sm w-full">
                <p className="text-mocha">Sales Tax (8%)</p>
                <p className="text-[#3d2b1f]">${totals.tax.toFixed(2)}</p>
              </div>
              <div className="bg-latte h-px w-full" />
              <div className="flex font-display font-bold items-start justify-between text-lg w-full">
                <p className="text-espresso">Total Payment (estimate)</p>
                <p className="text-rust">${totals.total.toFixed(2)}</p>
              </div>
              <p className="font-sans text-mocha text-[11px] leading-snug">
                Final totals are computed by the server when your order is placed.
              </p>
            </div>

            <div className="flex flex-col gap-2 items-start w-full">
              <label className="font-sans font-semibold text-[#3d2b1f] text-[13px]" htmlFor="payment-method">
                Payment method
              </label>
              <select
                id="payment-method"
                value={paymentMethod}
                onChange={(e) => setPaymentMethod(e.target.value)}
                className="border border-latte border-solid p-3 rounded-lg w-full font-sans text-sm text-espresso focus:outline-none focus:border-rust"
              >
                {PAYMENT_METHODS.map((m) => (
                  <option key={m.value} value={m.value}>
                    {m.label}
                  </option>
                ))}
              </select>
              <p className="font-sans text-mocha text-[11px]">Simulated payment — no real charge.</p>
            </div>

            {placeOrderError && (
              <p className="font-sans text-sm text-[#b3261e] whitespace-pre-line w-full" role="alert">
                {placeOrderError}
              </p>
            )}
            {checkoutMessage && (
              <p className="font-sans text-sm text-[#498500] w-full" role="status">
                {checkoutMessage}
              </p>
            )}

            <button
              type="button"
              disabled={cart.length === 0 || placingOrder}
              onClick={handleCheckout}
              className={
                cart.length === 0 || placingOrder
                  ? 'bg-latte flex items-center justify-center py-3.5 rounded-xl shrink-0 w-full font-sans font-bold text-mocha text-[15px] cursor-not-allowed'
                  : 'bg-rust flex items-center justify-center py-3.5 rounded-xl shrink-0 w-full font-sans font-bold text-white text-[15px] hover:opacity-90 transition-opacity'
              }
            >
              {placingOrder ? 'Placing order…' : `Place Order ($${totals.total.toFixed(2)})`}
            </button>
          </div>

          <div className="bg-white border border-latte border-solid flex flex-col gap-5 items-start p-6 rounded-2xl shrink-0 w-full" data-name="live-tracker-panel">
            {!lastOrder ? (
              <p className="font-sans text-mocha text-sm">Place an order to see live tracking here.</p>
            ) : (
              <>
                <div className="flex flex-col gap-1 items-start w-full">
                  <p className="font-display font-bold text-espresso text-lg">Last Order: #{lastOrder.orderNumber ?? lastOrder.id}</p>
                  <p className="font-sans text-mocha text-xs">{formatPlacedAt(lastOrder.placedAt)}</p>
                </div>
                {cancelled ? (
                  <p className="font-sans font-semibold text-[#b3261e] text-sm">This order was cancelled.</p>
                ) : (
                  <div className="flex flex-col gap-4 items-start w-full">
                    {STEPS.map((step, idx) => {
                      const done = idx < currentStepIndex
                      const active = idx === currentStepIndex
                      const dotColor = done ? 'bg-[#498500]' : active ? 'bg-rust' : 'bg-latte'
                      const lineColor = idx < currentStepIndex ? 'bg-[#498500]' : 'bg-latte'
                      return (
                        <div key={step.key} className="flex gap-3 items-start w-full">
                          <div className="flex flex-col gap-1 items-center shrink-0">
                            <span className={`${dotColor} flex items-center justify-center rounded-full shrink-0 size-5 text-white text-[10px]`}>
                              {done ? '✓' : ''}
                            </span>
                            {idx < STEPS.length - 1 && <span className={`${lineColor} h-6 w-0.5`} />}
                          </div>
                          <div className="flex flex-1 flex-col gap-0.5 items-start min-w-0">
                            <p className={`font-display font-bold text-sm ${active ? 'text-rust' : done ? 'text-espresso' : 'text-mocha'}`}>
                              {step.title}
                            </p>
                            <p className="font-sans text-mocha text-xs leading-snug">{step.body}</p>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>

      <Footer />
    </div>
  )
}
