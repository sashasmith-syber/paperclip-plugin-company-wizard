# Use Node.js 20 as base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the plugin
RUN pnpm build

# Expose development server port
EXPOSE 4177

# Default command for development
CMD ["pnpm", "dev:ui"]
