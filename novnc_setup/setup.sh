#!/bin/bash

rm -rf .devcontainer/novnc
npx create-next-app .devcontainer/novnc --yes --typescript --tailwind --eslint --app --api --src-dir --turbopack --import-alias "@/*" --empty
rm .devcontainer/novnc/src/app/route.ts
curl -o .devcontainer/novnc/Dockerfile https://raw.githubusercontent.com/vercel/next.js/refs/heads/canary/examples/with-docker/Dockerfile
sed -i '41i\LABEL org.opencontainers.image.source="https://github.com/peakys-org/blender-devcontainer/"' .devcontainer/novnc/Dockerfile
mkdir .devcontainer/novnc/public
git clone https://github.com/novnc/noVNC.git .devcontainer/novnc/public/noVNC/
# rm -rf .devcontainer/novnc/public/noVNC/.git
cp novnc_setup/mandatory.json .devcontainer/novnc/public/noVNC/mandatory.json
cp novnc_setup/clipboard.mjs .devcontainer/novnc/public/noVNC/clipboard.mjs
cp novnc_setup/route.ts .devcontainer/novnc/src/app/[slug]/route.ts
cp novnc_setup/layout.tsx .devcontainer/novnc/src/app/layout.tsx
cp novnc_setup/page.tsx .devcontainer/novnc/src/app/page.tsx
mkdir -p .devcontainer/novnc/src/lib/server
cp novnc_setup/services.ts .devcontainer/novnc/src/lib/server/services.ts
cp novnc_setup/next.config.ts .devcontainer/novnc/next.config.ts
sed -i '/<\/head>/i <script type="module">import "./clipboard.mjs";</script>' .devcontainer/novnc/public/noVNC/vnc.html
