/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#0f172a",
        mist: "#e2e8f0",
        sand: "#f8f5ef",
        coral: "#ef7d57",
        teal: "#0f766e",
      },
      fontFamily: {
        display: ["Georgia", "serif"],
        body: ["Helvetica Neue", "Arial", "sans-serif"],
      },
      boxShadow: {
        card: "0 20px 45px rgba(15, 23, 42, 0.12)",
      },
    },
  },
  plugins: [],
};
