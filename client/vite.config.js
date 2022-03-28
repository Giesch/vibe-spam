import * as vite from "vite";
import elmPlugin from "vite-plugin-elm";

export default vite.defineConfig(({ mode }) => {
  const dev = mode === "development";

  const env = vite.loadEnv(mode, process.cwd());
  const apiTarget = env.VITE_API_TARGET;
  if (!apiTarget && dev) {
    throw new Error(
      "no VITE_API_TARGET set; run 'npm run config:local or npm 'run config:local:prod'"
    );
  }

  const plugins = [elmPlugin({ debug: dev })];
  const server = dev ? devServerOptions(apiTarget) : {};

  return { root: "public", plugins, server };
});

/**
 * @param {string} apiTarget - the url to use for json api requests
 * @return {vite.ServerOptions}
 */
function devServerOptions(apiTarget) {
  return {
    proxy: {
      "/api": {
        target: apiTarget,
        changeOrigin: true,
      },
    },
  };
}
