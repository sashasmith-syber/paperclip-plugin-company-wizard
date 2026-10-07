# Security Guidelines for Local Deployment

This document outlines security best practices for local development and deployment of the Company Wizard plugin.

## Core Security Principles

1. **Never commit secrets** - Use environment variables and secret stores
2. **Principle of least privilege** - Run services with minimal required permissions
3. **Local-first security** - Secure local development before considering cloud extensions
4. **Defense in depth** - Multiple security layers, not single points of failure

## Environment Variables and Secrets

### Required Environment Variables

Create a `.env.local` file (never commit this):

```bash
# Paperclip Configuration
PAPERCLIP_PUBLIC_URL=http://localhost:3100
PAPERCLIP_EMAIL=your-email@example.com
PAPERCLIP_PASSWORD=your-secure-password

# AI Wizard Mode (Optional)
ANTHROPIC_API_KEY=sk-ant-api03-...

# Development
NODE_ENV=development
```

### Secret Management

```bash
# Use .env.example as a template
cp .env.example .env.local

# Never commit .env.local
echo ".env.local" >> .gitignore  # Already in .gitignore

# For production, use proper secret management:
# - Docker secrets
# - Kubernetes secrets
# - AWS Secrets Manager / Azure Key Vault
# - Environment-specific .env files
```

## Docker Security

### Container Security

Our Docker configuration follows these security practices:

```dockerfile
# Use official, minimal base images
FROM node:20-alpine  # Alpine Linux reduces attack surface

# Non-root user (if needed for production)
# RUN addgroup -g 1001 -S nodejs
# RUN adduser -S nextjs -u 1001
# USER nextjs
```

### Docker Compose Security

```yaml
services:
  app:
    # Bind to localhost only
    ports:
      - "127.0.0.1:4177:4177"  # More secure than "4177:4177"
    
    # Read-only filesystem (when possible)
    # read_only: true
    
    # Drop capabilities
    # cap_drop:
    #   - ALL
    # cap_add:
    #   - NET_BIND_SERVICE
    
    # No privileged access
    # privileged: false
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### Docker Security Commands

```bash
# Scan Docker image for vulnerabilities
docker scan company-wizard:latest

# Check for exposed ports
docker port $(docker ps -q)

# Inspect container security
docker inspect $(docker ps -q) | grep -A 10 "SecurityOpt"

# Run with security options
docker run --security-opt=no-new-privileges company-wizard:latest
```

## Network Security

### Local Development

```bash
# Bind to localhost only
pnpm dev:ui  # Already configured for localhost

# Use firewall rules if needed
# Windows: New-NetFirewallRule -DisplayName "Block App" -Direction Outbound -LocalPort 4177 -Protocol TCP -Action Block
# macOS: sudo pfctl -f /etc/pf.conf
# Linux: sudo ufw deny 4177
```

### Docker Networking

```bash
# Use custom networks
docker network create company-wizard-net

# Run with custom network
docker run --network company-wizard-net company-wizard:latest

# Isolate from host network
docker run --network none company-wizard:latest  # No network access
```

## Code Security

### Dependency Security

```bash
# Audit dependencies
pnpm audit

# Fix vulnerabilities
pnpm audit --fix

# Check for outdated packages
pnpm outdated

# Use npm-check-updates for bulk updates
npx npm-check-updates -u
pnpm install
```

### Secret Scanning

```bash
# Install gitleaks locally
brew install gitleaks  # macOS
# Or download from GitHub releases

# Scan repository
gitleaks detect --source . --verbose

# Scan specific directory
gitleaks detect --source ./src --verbose

# Create gitleaks config if needed
gitleaks init
```

### Code Quality

```bash
# Type checking (prevents runtime errors)
pnpm typecheck

# Linting (prevents security anti-patterns)
pnpm prettier --check .

# Security-focused ESLint rules (if added)
# npx eslint . --ext .ts,.tsx --config .eslintrc.security.js
```

## File System Security

### Permissions

```bash
# Check file permissions
ls -la

# Fix permissions (Linux/macOS)
chmod 755 scripts/
chmod 644 *.json
chmod 600 .env.local

# Docker volume permissions
docker run -v $(pwd):/app:ro company-wizard:latest  # Read-only mount
```

### Sensitive Files

Ensure these files are in `.gitignore`:

```gitignore
# Environment files
.env.local
.env.*.local

# Secret files
*.key
*.pem
*.p12
secrets/

# IDE files
.vscode/settings.json  # May contain API keys
.idea/

# OS files
.DS_Store
Thumbs.db
```

## Monitoring and Logging

### Security Monitoring

```bash
# Monitor Docker containers
docker logs -f company-wizard-app

# Monitor system resources
docker stats

# Check for suspicious activity
docker exec company-wizard-app ps aux
```

### Log Security

```javascript
// Avoid logging sensitive data
console.log('User login:', { email, password }); // BAD
console.log('User login:', { email }); // GOOD
console.log('API call:', { endpoint, method }); // GOOD

// Use structured logging
console.log(JSON.stringify({
  event: 'user_login',
  email: user.email,
  timestamp: new Date().toISOString(),
  ip: req.ip
}));
```

## CI/CD Security

### GitHub Actions Security

Our CI/CD pipeline includes:

- **Secret scanning** with Gitleaks
- **Dependency auditing** with `pnpm audit`
- **Read-only permissions** by default
- **No production deployments** (local-first)

### Local CI Security

Run the local CI pipeline securely:

```bash
# Install act for local GitHub Actions
brew install act  # macOS
# Or download from GitHub releases

# Run security checks locally
act -j security-scan
act -j dependency-audit
act -j lint
```

## Security Checklist

### Before Development

- [ ] `.env.local` created from `.env.example`
- [ ] No secrets in tracked files
- [ ] Docker image scanned for vulnerabilities
- [ ] Dependencies audited
- [ ] File permissions set correctly

### During Development

- [ ] No hardcoded secrets in code
- [ ] Environment variables used for configuration
- [ ] Sensitive data not logged
- [ ] Changes reviewed for security implications

### Before Deployment

- [ ] Full security scan passed
- [ ] Dependencies updated and audited
- [ ] Docker security options configured
- [ ] Network access restricted
- [ ] Monitoring and logging configured

## Incident Response

### If Secrets Are Committed

```bash
# 1. Immediately remove from current branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env.local' \
  --prune-empty --tag-name-filter cat -- --all

# 2. Rotate all exposed secrets
# 3. Push force with caution
git push origin --force --all

# 4. Review GitHub/GitLab for exposed tokens
# 5. Monitor for suspicious activity
```

### If Vulnerabilities Found

```bash
# 1. Update vulnerable packages
pnpm update package-name

# 2. Test thoroughly
pnpm test

# 3. Document the fix
git commit -m "fix: update package-name to fix CVE-XXXX-XXXX"

# 4. Monitor for related issues
```

## Extending to Cloud

When extending local setup to cloud environments:

1. **Use proper secret management** (AWS Secrets Manager, etc.)
2. **Enable VPC/network isolation**
3. **Use managed security services** (AWS GuardDuty, etc.)
4. **Implement proper IAM roles**
5. **Enable audit logging**
6. **Use container security scanning** (AWS ECR scanning, etc.)

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Node.js Security Checklist](https://github.com/goldbergyoni/nodebestpractices#-security-best-practices)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
