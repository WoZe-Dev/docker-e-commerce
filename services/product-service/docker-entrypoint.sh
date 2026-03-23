#!/bin/sh
set -e

# Docker secrets support: read files and strip trailing whitespace/newlines

if [ -n "$JWT_SECRET_FILE" ] && [ -f "$JWT_SECRET_FILE" ]; then
  export JWT_SECRET=$(cat "$JWT_SECRET_FILE" | tr -d '\n\r')
fi

if [ -n "$MONGODB_URI_FILE" ] && [ -f "$MONGODB_URI_FILE" ]; then
  export MONGODB_URI=$(cat "$MONGODB_URI_FILE" | tr -d '\n\r')
fi

# Construct authenticated MongoDB URI from individual secrets
if [ -f "/run/secrets/mongo_user" ] && [ -f "/run/secrets/mongo_password" ]; then
  MONGO_USER=$(cat /run/secrets/mongo_user | tr -d '\n\r')
  MONGO_PASS=$(cat /run/secrets/mongo_password | tr -d '\n\r')
  MONGO_DB=${MONGO_DB:-ecommerce}
  export MONGODB_URI="mongodb://${MONGO_USER}:${MONGO_PASS}@mongodb:27017/${MONGO_DB}?authSource=admin"
fi

exec "$@"
