import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import EnvironmentPlugin from 'vite-plugin-environment'

export default defineConfig({
  plugins: [
    react(),
    EnvironmentPlugin('all', { prefix: 'REACT_APP_' }),
  ],
  build: {
    outDir: "build"
  },
  esbuild: {
    loader: "tsx",
    include: [
      "src/**/*.js",
    ],
    exclude: [],
  }
})
