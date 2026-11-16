/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        hoppa: {
          orange: "#FF6B00",
          "orange-hover": "#E55A00",
          "orange-tint": "#FFF4EC",
          "orange-light": "rgba(255, 107, 0, 0.14)",
          green: "#00A651",
          "green-hover": "#008C44",
          "green-tint": "#ECFDF5",
          "green-light": "rgba(0, 166, 81, 0.12)",
          canvas: "#F8FAFC",
          "canvas-dark": "#0B0F17",
          surface: "#FFFFFF",
          "surface-dark": "#111827",
          "surface-subtle": "#F1F5F9",
          "surface-subtle-dark": "#1E293B",
          dark: "#0B0F17",
          sidebar: "#111827",
          card: "#1E293B",
          border: "#E2E8F0",
          "border-dark": "#1E293B"
        }
      },
      borderWidth: {
        3: "3px",
      },
      boxShadow: {
        xs: "0 1px 2px 0 rgb(0 0 0 / 0.05)",
        "2xs": "0 1px 1px 0 rgb(0 0 0 / 0.04)",
      },
      backdropBlur: {
        xs: "2px",
      },
      transitionDuration: {
        250: "250ms",
        350: "350ms",
      },
      scale: {
        102: "1.02",
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
