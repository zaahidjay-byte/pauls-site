/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        'pauls-blue': '#1D44C2',
        'pauls-pink': '#E85CAA',
        'pauls-light-pink': '#FFE8F4',
        'pauls-light-blue': '#BEE8F6',
        'pauls-dark-blue': '#11266A',
        'pauls-offwhite': '#F4FDFF',
      },
      fontFamily: {
        sans: ['DM Sans', 'Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
