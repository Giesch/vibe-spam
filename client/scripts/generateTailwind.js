const elmTailwindModules = require("elm-tailwind-modules");
const autoprefixer = require("autoprefixer");
const tailwindConfig = require("../tailwind.config.js");

elmTailwindModules.run({
  directory: ".elm-tailwind-modules",
  generateDocumentation: true,
  moduleName: "Tailwind",
  postcssPlugins: [autoprefixer],
  tailwindConfig,
});
