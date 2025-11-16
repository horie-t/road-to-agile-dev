# Multi-stage Dockerfile for Vite + React frontend

# 1) Builder: install deps and build static assets
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN set -eux \
    && if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy the rest of the source and build
COPY . .
RUN npm run build


# 2) Runtime: serve static files with nginx
FROM nginx:1.27-alpine AS runtime

# Copy custom nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifact
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

# Healthcheck (optional but useful)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://localhost/ || exit 1

# Use the default nginx entrypoint/cmd
