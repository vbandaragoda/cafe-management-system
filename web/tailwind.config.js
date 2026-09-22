/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Design tokens pulled from the Figma file (raw hex, no published variables)
        rust: '#c85c40', // primary brand / CTA color
        espresso: '#2e1e12', // near-black ink / footer bg
        cream: '#faf6f0', // page background
        latte: '#eae3d9', // borders / dividers
        mocha: '#8c7a6b', // muted / secondary text
        blush: '#f5dfd9', // tag background
        walnut: '#5c4636', // status pill bg
      },
      fontFamily: {
        display: ['Outfit', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        sans: ['Figtree', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
