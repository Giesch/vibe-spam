# rogue-wizard client

## first-time setup

0. [install nvm](https://github.com/nvm-sh/nvm)
1. `nvm install`
2. `npm start`

## scripts

```bash
npm start       # initial developer setup; runs setup and dev
npm run setup   # installs dependencies and generates code
npm run dev     # dev server; runs elm-spa and Vite
npm run api     # generate graphql api modules
npm run tw      # generate tailwind css modules
npm run docker  # used in the Dockerfile; runs setup and build
npm run build   # production codegen and vite build
npm run config:local  # use local api server
npm run config:prod   # use prod api server
```

## dependencies

- [elm](https://elm-lang.org)
- [elm-spa](https://elm-spa.dev)
- [elm-graphql](https://github.com/dillonkearns/elm-graphql)
- [elm-tailwind-modules](https://matheus23.github.io/elm-tailwind-modules)
- [tailwindcss (v2)](https://v2.tailwindcss.com)
- [tailwindui](https://tailwindui.com)
