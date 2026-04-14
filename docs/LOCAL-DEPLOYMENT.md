# Local Deployment Guide

This guide covers setting up a secure, reproducible local development environment for the Company Wizard Paperclip plugin.

## Prerequisites

- **Docker Desktop** (or Docker Engine + Docker Compose)
- **Node.js 20+** (for local development without Docker)
- **pnpm** (package manager)
- **Git**

## Quick Start

### Option 1: Docker (Recommended)

```bash
# Clone and navigate to the project
git clone https://github.com/Yesterday-AI/paperclip-plugin-company-wizard.git
cd paperclip-plugin-company-wizard

# Start the development environment
docker compose up

# The plugin UI will be available at http://localhost:4177
```

### Option 2: Local Development

```bash
# Clone and navigate to the project
git clone https://github.com/Yesterday-AI/paperclip-plugin-company-wizard.git
cd paperclip-plugin-company-wizard

# Install dependencies
pnpm install

# Start development server
pnpm dev:ui

# The plugin UI will be available at http://localhost:4177
```

## Commands

### Docker Commands

```bash
# Start the development environment
docker compose up

# Start in detached mode
docker compose up -d

# Stop the environment
docker compose down

# Stop and remove volumes (clean start)
docker compose down -v

# View logs
docker compose logs -f app

# Execute commands in the container
docker compose exec app pnpm test
docker compose exec app pnpm build
```

### Local Development Commands

```bash
# Install dependencies
pnpm install

# Development with hot reload
pnpm dev

# Development with UI server only
pnpm dev:ui

# Build the plugin
pnpm build

# Run tests
pnpm test

# Run logic tests
pnpm test:logic

# Type checking
pnpm typecheck

# Linting (via prettier)
pnpm lint  # Alias for prettier check
```

## Development Workflow

### Making Changes

1. **For plugin code changes:**
   ```bash
   # Make your changes
   # The build will auto-reload in dev mode
   pnpm dev
   ```

2. **For Docker changes:**
   ```bash
   # Rebuild the Docker image
   docker compose build
   
   # Restart with new image
   docker compose up
   ```

### Testing Before Commit

```bash
# Run the full test suite
pnpm test

# Type checking
pnpm typecheck

# Build verification
pnpm build

# Security scan (if gitleaks is installed locally)
gitleaks detect --source . --verbose
```

## Environment Variables

Create a `.env.local` file for local development:

```bash
# Copy the example
cp .env.example .env.local

# Edit with your values
# See .env.example for available variables
```

## Troubleshooting

### Common Issues

**Port 4177 already in use:**
```bash
# Check what's using the port
lsof -i :4177  # macOS/Linux
netstat -ano | findstr :4177  # Windows

# Or change the port in docker-compose.yml
ports:
  - "4178:4177"  # Use 4178 instead
```

**Docker build fails:**
```bash
# Clean rebuild
docker compose down -v
docker system prune -f
docker compose build --no-cache
```

**Node modules issues:**
```bash
# Clean install
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

**Permission issues (Linux/macOS):**
```bash
# Fix Docker permissions
sudo chown -R $USER:$USER .dockerignore
```

### Performance Tips

1. **Use Docker volumes** for faster file syncing (already configured)
2. **Exclude node_modules** from Docker context (configured in .dockerignore)
3. **Use local pnpm** for faster initial setup vs Docker
4. **Enable Docker Desktop's** file sharing optimization

## Security Considerations

- Never commit `.env.local` or any secrets
- Use `.env.example` as a template for required variables
- The Docker container runs as non-root user
- All ports are bound to localhost by default
- Security scanning is included in CI/CD pipeline

## Next Steps

- Read [SECURITY-LOCAL-DEPLOYMENT.md](SECURITY-LOCAL-DEPLOYMENT.md) for security guidelines
- Check [PERFORMANCE-NOTES.md](PERFORMANCE-NOTES.md) for optimization tips
- Review the [CI/CD pipeline](../.github/workflows/ci.yml) for automated checks
