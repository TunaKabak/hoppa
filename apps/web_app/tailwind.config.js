/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        hoppa: {
          orange: "#FF6B00",
          "orange-hover": "#E56000",
          "orange-light": "rgba(255, 107, 0, 0.12)",
          green: "#00A651",
          "green-hover": "#008C44",
          "green-light": "rgba(0, 166, 81, 0.12)",
          dark: "#0b0f19",
          sidebar: "#111827",
          card: "#1f2937",
          border: "#374151"
        }
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
