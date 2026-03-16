FROM node:20-alpine

WORKDIR /app

# Required for manual product seeding from inside the container.
RUN apk add --no-cache curl bash

# Copy and clean init script (remove Windows CRLF line endings)
COPY scripts/init-products.sh /tmp/init-products.sh
RUN tr -d '\r' < /tmp/init-products.sh > /init-products.sh && chmod +x /init-products.sh

# Install production dependencies only
COPY services/product-service/package.json ./
RUN npm install --omit=dev

# Copy application source
COPY services/product-service/src ./src

EXPOSE 3000

CMD ["node", "src/app.js"]