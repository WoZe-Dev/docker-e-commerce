# stage 1
FROM node:20-alpine AS builder

WORKDIR /app


COPY package.json .npmrc* ./


RUN npm install


COPY . .
RUN npm run build

# stage2  

FROM node:20-alpine AS production

WORKDIR /app

COPY package.json  .npmrc* ./
RUN npm install


COPY --from=builder /app/dist ./dist
COPY server.cjs ./

EXPOSE 8080


CMD ["node", "server.cjs"]