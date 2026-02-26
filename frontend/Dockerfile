# stage 1
FROM node:20-alpine AS builder

WORKDIR /app


COPY package.json package-lock.json .npmrc* ./


RUN npm ci


COPY . .
RUN npm run build

# stage2  

FROM node:20-alpine AS production

WORKDIR /app

COPY package.json package-lock.json .npmrc* ./
RUN npm ci --omit=dev


COPY --from=builder /app/dist ./dist
COPY server.cjs ./

EXPOSE 8080


CMD ["node", "server.cjs"]