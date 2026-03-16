FROM node:20-alpine

WORKDIR /app

# Required for manual product seeding from inside the container.
RUN apk add --no-cache curl bash

# Install production dependencies only
COPY package.json ./
RUN npm install --omit=dev

# Copy application source
COPY src ./src

EXPOSE 3000

CMD ["node", "src/app.js"]