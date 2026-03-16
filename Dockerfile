# ==============================================================================
# Merchant Core API - Multi-Stage Dockerfile
# ==============================================================================
# Inherits from the DevOps-managed base image for security, observability,
# and runtime defaults. Only adds application-specific build and configuration.
#
# Build: docker build -t merchant-core-api:latest -f Dockerfile .
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Install dependencies
# ------------------------------------------------------------------------------
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package manifests first for better Docker layer caching
COPY package.json package-lock.json* ./

# Install production dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

# ------------------------------------------------------------------------------
# Stage 2: Build (if you have a build step — TypeScript, bundling, etc.)
# ------------------------------------------------------------------------------
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build --if-present

# ------------------------------------------------------------------------------
# Stage 3: Production runtime — inherits from DevOps base image
# ------------------------------------------------------------------------------
FROM merchant-base:latest AS production

# Copy only production node_modules from deps stage
COPY --chown=appuser:appgroup --from=deps /app/node_modules ./node_modules

# Copy only built application artifacts from build stage
COPY --chown=appuser:appgroup --from=build /app/dist ./dist
COPY --chown=appuser:appgroup --from=build /app/package.json ./package.json

# Service-specific configuration
ENV SERVICE_NAME=merchant-core-api

# Start the application
CMD ["node", "dist/index.js"]
