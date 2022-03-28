const typography = require("@tailwindcss/typography");
const forms = require("@tailwindcss/forms");
const aspectRatio = require("@tailwindcss/aspect-ratio");

module.exports = {
  darkMode: false, // or 'media' or 'class'
  // using elm-tailwind-modules for purging unused styles
  purge: false,
  plugins: [typography, forms, aspectRatio],
  // this needs to be empty for elm-tailwind-modules
  variants: [],
  theme: {
    extend: {},
  },
};
