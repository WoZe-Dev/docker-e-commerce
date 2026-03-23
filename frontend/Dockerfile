# Stage 1: Build Vue.js application
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json .npmrc* ./
RUN npm install && npm cache clean --force
COPY . .
RUN npm run build

# Stage 2: Development (Express + proxy for hot-reload)
FROM node:20-alpine AS development
WORKDIR /app
COPY package.json .npmrc* ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "server.cjs"]

# Stage 3: Production (Nginx - lightweight static server + reverse proxy)
FROM nginx:stable-alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
