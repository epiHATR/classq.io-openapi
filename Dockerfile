# ClassQ OpenAPI docs. Build from the repo root:
#   docker build -t classq-io-openapi .
FROM node:22-alpine AS build

WORKDIR /src

COPY package.json package-lock.json ./
RUN npm ci

COPY openapi.yaml ./
COPY scripts/build-docs.mjs scripts/build-docs.mjs
RUN node scripts/build-docs.mjs

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/dist/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=10s \
  CMD wget -q --spider "http://127.0.0.1:80/" || exit 1

CMD ["nginx", "-g", "daemon off;"]
