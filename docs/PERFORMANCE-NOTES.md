# Performance Notes & Optimization Guide

This document tracks performance characteristics, bottlenecks, and optimization strategies for the Company Wizard plugin.

## Current Performance Baseline

### Build Performance

```bash
# Initial build (cold cache)
pnpm build
# Expected: ~10-15 seconds

# Incremental build (warm cache)
pnpm build
# Expected: ~2-5 seconds

# Development server startup
pnpm dev
# Expected: ~3-7 seconds
```

### Test Performance

```bash
# Full test suite
pnpm test
# Expected: < 30 seconds

# Logic tests only
pnpm test:logic
# Expected: < 10 seconds

# Type checking
pnpm typecheck
# Expected: < 15 seconds
```

### Docker Performance

```bash
# Docker build (no cache)
docker compose build
# Expected: ~2-3 minutes

# Docker build (with cache)
docker compose build
# Expected: ~30-45 seconds

# Container startup
docker compose up
# Expected: ~10-20 seconds
```

## Known Performance Hotspots

### 1. Template Processing

**Location**: `src/logic/assembly.ts`
**Impact**: High during company creation
**Current**: Processes ~200MB of templates
**Optimization Opportunities**:
- Lazy loading of templates
- Template caching
- Parallel processing of independent modules

### 2. Build Process

**Location**: `esbuild.config.mjs`
**Impact**: Every build
**Current**: Bundles UI components with React
**Optimization Opportunities**:
- Code splitting for UI
- Tree shaking for unused dependencies
- Incremental builds

### 3. Development Server

**Location**: `pnpm dev:ui`
**Impact**: Development experience
**Current**: Full rebuild on file changes
**Optimization Opportunities**:
- Hot module replacement
- Selective rebuilding
- File watching optimizations

## Profiling Tools & Commands

### Node.js Profiling

```bash
# CPU profiling
node --prof dist/worker.js
node --prof-process isolate-*.log > processed.txt

# Memory profiling
node --inspect dist/worker.js
# Then connect Chrome DevTools

# Heap snapshots
node --inspect --heap-prof dist/worker.js
```

### Build Profiling

```bash
# Detailed build timing
pnpm build --reporter=verbose

# Bundle analysis
pnpm build:rollup  # If using Rollup with analyzer

# Dependency analysis
pnpm why <package-name>
pnpm ls --depth=0
```

### Docker Profiling

```bash
# Container resource usage
docker stats

# Container inspection
docker inspect $(docker ps -q)

# Build cache analysis
docker builder df
docker buildx du
```

### Frontend Profiling

```bash
# Development server profiling
# Open http://localhost:4177 and use Chrome DevTools:
# - Performance tab
# - Network tab
# - Memory tab
```

## Optimization Strategies

### 1. Build Optimizations

#### Caching Strategy

```javascript
// esbuild.config.mjs optimizations
const buildOptions = {
  // Enable incremental builds
  incremental: true,
  
  // Optimize for development
  sourcemap: true,
  minify: false,  // Faster builds in dev
  
  // Target specific Node version
  target: ['node20'],
  
  // External dependencies for faster builds
  external: ['react', 'react-dom'],
};
```

#### Parallel Processing

```bash
# Run tests in parallel
pnpm test --reporter=verbose --threads

# Parallel type checking (if using tsc --project)
pnpm typecheck --build --force
```

### 2. Docker Optimizations

#### Multi-stage Builds

```dockerfile
# Optimize Dockerfile for faster builds
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY package*.json ./
RUN pnpm install --production --frozen-lockfile
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/worker.js"]
```

#### Layer Caching

```dockerfile
# Order Docker operations by frequency of change
COPY package*.json ./  # Changes rarely
RUN pnpm install --frozen-lockfile  # Cacheable

COPY src/ ./src  # Changes frequently
COPY templates/ ./templates  # Changes rarely
RUN pnpm build
```

### 3. Development Workflow Optimizations

#### Fast Refresh Strategy

```bash
# Use file watching for specific directories
pnpm dev --watch src --watch templates

# Exclude large directories from watching
echo "node_modules/" >> .watchignore
echo "dist/" >> .watchignore
```

#### Selective Testing

```bash
# Run only relevant tests
pnpm test --grep "assembly"
pnpm test --reporter=verbose src/logic/*.test.ts

# Run tests for changed files only
pnpm test --changed since=main
```

## Performance Monitoring

### Local Monitoring

```bash
# Monitor build times
time pnpm build
time pnpm test

# Monitor Docker performance
docker stats --no-stream
docker compose exec app top

# Monitor file system usage
du -sh node_modules/
du -sh dist/
du -sh templates/
```

### CI/CD Performance

```bash
# Monitor GitHub Actions performance
# Check job timings in GitHub Actions UI

# Local CI performance with act
time act -j test
time act -j build
```

## Performance Benchmarks

### Target Metrics

| Operation | Target | Current | Status |
|-----------|--------|---------|---------|
| Initial build | < 20s | ~15s | ✅ |
| Incremental build | < 5s | ~3s | ✅ |
| Full test suite | < 60s | ~30s | ✅ |
| Docker build | < 90s | ~45s | ✅ |
| Container startup | < 30s | ~15s | ✅ |
| Company creation | < 10s | ~8s | ✅ |

### Historical Performance

Track performance over time:

```bash
# Create performance log
echo "$(date),$(time pnpm build 2>&1 | grep real)" >> performance.log

# Analyze trends
grep -o '[0-9]\+\.[0-9]\+' performance.log | awk '{sum+=$1; count++} END {print "Average:", sum/count}'
```

## Optimization Roadmap

### Short Term (Next Sprint)

- [ ] Implement template caching
- [ ] Add build timing metrics
- [ ] Optimize Docker layer caching
- [ ] Add selective test running

### Medium Term (Next Month)

- [ ] Implement code splitting for UI
- [ ] Add incremental type checking
- [ ] Optimize template processing pipeline
- [ ] Add performance regression tests

### Long Term (Next Quarter)

- [ ] Implement hot module replacement
- [ ] Add performance monitoring dashboard
- [ ] Optimize bundle size
- [ ] Implement lazy loading for templates

## Performance Testing

### Load Testing

```bash
# Test company creation performance
for i in {1..10}; do
  time curl -X POST http://localhost:4177/api/assemble-company \
    -H "Content-Type: application/json" \
    -d '{"preset":"fast","modules":["github-repo"]}'
done
```

### Memory Testing

```bash
# Monitor memory usage during builds
node --max-old-space-size=4096 ./node_modules/.bin/esbuild ./esbuild.config.mjs

# Check for memory leaks
node --inspect --trace-gc dist/worker.js
```

## Troubleshooting Performance Issues

### Slow Builds

**Symptoms**: Build times > 30 seconds
**Causes**:
- Large node_modules
- Missing build cache
- Inefficient esbuild config
**Solutions**:
```bash
# Clean and rebuild
rm -rf node_modules dist
pnpm install
pnpm build

# Check build cache
pnpm store path
pnpm store prune
```

### Slow Tests

**Symptoms**: Test times > 60 seconds
**Causes**:
- Inefficient test setup
- Missing test isolation
- Large fixture data
**Solutions**:
```bash
# Run tests with timing
pnpm test --reporter=verbose

# Profile slow tests
pnpm test --timeout 10000
```

### Docker Performance

**Symptoms**: Container startup > 60 seconds
**Causes**:
- Large image size
- Missing layer cache
- Inefficient volume mounts
**Solutions**:
```bash
# Optimize Docker build
docker compose build --no-cache
docker system prune -f

# Use .dockerignore effectively
echo "*.log" >> .dockerignore
echo "coverage/" >> .dockerignore
```

## Performance Resources

- [Node.js Performance Best Practices](https://nodejs.org/en/docs/guides/simple-profiling/)
- [Docker Performance Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [esbuild Performance Guide](https://esbuild.github.io/api/#performance)
- [Vitest Performance Tips](https://vitest.dev/guide/features.html#performance)
