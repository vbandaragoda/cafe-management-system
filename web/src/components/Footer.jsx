import { Link } from 'react-router-dom'
import { icons } from '../assets/images'
import { useApp } from '../context/AppContext'

const linkColumns = [
  {
    title: 'Explore',
    links: ['Menu Catalog', 'Daily Specials', 'Catering Packages'],
  },
  {
    title: 'For Owners',
    links: ['Register Cafe', 'System Features', 'Hardware Integrations'],
  },
  {
    title: 'Help',
    links: ['Support Center', 'Privacy Terms', 'Accessibility'],
  },
]

export default function Footer({ statusOverride }) {
  const { user } = useApp()
  const statusLabel = statusOverride || (user ? `Logged in as ${user.name}` : 'Browsing as Guest')

  return (
    <footer className="bg-espresso flex flex-col gap-10 items-start pb-10 pt-16 px-16 w-full" data-name="footer">
      <div className="flex items-start justify-between w-full flex-wrap gap-10" data-name="footer-top">
        <div className="flex flex-col gap-4 items-start w-[340px] max-w-full" data-name="footer-brand">
          <div className="flex gap-2 items-center">
            <div className="bg-rust flex items-center justify-center rounded-xl shrink-0 size-8">
              <img alt="" className="size-[18px]" src={icons.coffee} />
            </div>
            <p className="font-display font-bold text-[22px] text-white whitespace-nowrap">Caffora</p>
          </div>
          <p className="font-sans text-latte text-sm leading-relaxed">
            Smart digital catalog, seamless orders, and streamlined management for modern independent cafes.
            Built for coffee lovers, managed with absolute clarity.
          </p>
        </div>

        <div className="flex gap-16 items-start text-sm flex-wrap" data-name="footer-links-grid">
          {linkColumns.map((col) => (
            <div key={col.title} className="flex flex-col gap-3 items-start">
              <p className="font-display font-bold text-rust uppercase">{col.title}</p>
              {col.links.map((link) => (
                <p key={link} className="font-sans text-white whitespace-nowrap">
                  {link}
                </p>
              ))}
            </div>
          ))}
        </div>
      </div>

      <div className="bg-[#4a382c] h-px w-full" data-name="Line" />

      <div className="flex items-center justify-between w-full flex-wrap gap-4" data-name="footer-bottom">
        <div className="flex gap-4 items-center flex-wrap">
          <p className="font-sans text-latte text-sm whitespace-nowrap">© 2026 Caffora Inc. All rights reserved.</p>
          <Link to="/admin" className="font-sans text-mocha text-xs underline whitespace-nowrap">
            Cafe Admin Portal
          </Link>
        </div>
        <div className="bg-walnut flex gap-2 items-center px-3 py-1.5 rounded-xl shrink-0" data-name="auth-status-indicator">
          <span className="bg-[#5fd07a] rounded-full size-2" />
          <p className="font-sans text-xs text-white whitespace-nowrap">{statusLabel}</p>
        </div>
      </div>
    </footer>
  )
}
