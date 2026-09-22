import { menuItemImages } from '../assets/images'

export const categories = ['All Items', 'Beverages', 'Snacks', 'Meals', 'Desserts']

export const menuItems = [
  {
    id: 'flat-white',
    name: 'Craft Flat White',
    price: 4.5,
    desc: 'Double shot of single-origin espresso with silky textured milk.',
    category: 'Beverages',
    calories: 280,
    img: menuItemImages.flatWhite,
    status: 'Available',
  },
  {
    id: 'cinnamon-bun',
    name: 'Cinnamon Swirl Bun',
    price: 3.75,
    desc: 'Freshly baked sourdough bun with Ceylon cinnamon and brown sugar glaze.',
    category: 'Snacks',
    calories: 280,
    img: menuItemImages.cinnamonBun,
    status: 'Available',
  },
  {
    id: 'avocado-toast',
    name: 'Avocado Sourdough Toast',
    price: 11.5,
    desc: 'Crushed Hass avocado, cherry tomatoes, and feta on organic levain.',
    category: 'Meals',
    calories: 280,
    img: menuItemImages.avocadoToast,
    status: 'Available',
  },
  {
    id: 'pistachio-tart',
    name: 'Pistachio Raspberry Tart',
    price: 6.5,
    desc: 'Sweet pastry shell filled with rich pistachio cream and fresh raspberries.',
    category: 'Desserts',
    calories: 280,
    img: menuItemImages.pistachioTart,
    status: 'Sold Out',
  },
  {
    id: 'chocolate-cookie',
    name: 'Sourdough Chocolate Cookie',
    price: 3.25,
    desc: 'Crispy edges with gooey, rich dark chocolate pools and flaked sea salt.',
    category: 'Desserts',
    calories: 340,
    img: menuItemImages.chocolateCookie,
    status: 'Available',
  },
  {
    id: 'honey-oat-latte',
    name: 'Iced Honey Oat Latte',
    price: 5.25,
    desc: 'Organic oat milk combined with raw local honey and blonde roast cold brew.',
    category: 'Beverages',
    calories: 340,
    img: menuItemImages.honeyOatLatte,
    status: 'Available',
  },
  {
    id: 'turkey-ciabatta',
    name: 'Smoked Turkey Ciabatta',
    price: 12.0,
    desc: 'Hand-carved turkey breast, heirloom tomatoes, pesto, and melted provolone.',
    category: 'Meals',
    calories: 340,
    img: menuItemImages.turkeyCiabatta,
    status: 'Available',
  },
  {
    id: 'matcha-crepe',
    name: 'Matcha Jasmine Crepe',
    price: 7.5,
    desc: 'Delicate matcha crepe layers with airy jasmine-infused pastry cream.',
    category: 'Snacks',
    calories: 340,
    img: menuItemImages.matchaCrepe,
    status: 'Available',
  },
]

export function findMenuItem(id) {
  return menuItems.find((item) => item.id === id)
}
