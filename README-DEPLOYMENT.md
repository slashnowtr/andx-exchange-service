# AndX Exchange Service - Deployment Guide

This guide covers deployment options for the AndX Exchange Service using Docker and the provided deployment scripts.

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Node.js 18+ (for local development)
- Git

### Environment Setup

1. Copy the environment template:

```bash
cp .env.example .env
```

2. Edit `.env` file with your configuration:

```bash
# Required: Set your CoinGecko API key
COINGECKO_API_KEY=your_api_key_here

# Optional: Adjust other settings as needed
PORT=3000
RATE_LIMIT_TTL=60
RATE_LIMIT_LIMIT=60
```

## Deployment Options

### Option 1: Quick Deployment (Recommended)

Use the automated deployment script:

```bash
# Deploy to production
./scripts/deploy.sh

# Deploy to development
./scripts/deploy.sh -e development

# Build only (no deployment)
./scripts/deploy.sh -b

# Skip tests and force rebuild
./scripts/deploy.sh -s -f
```

### Option 2: Manual Docker Deployment

#### Production Deployment

```bash
# Build the production image
docker build -t andx-exchange-service .

# Run with docker-compose
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

#### Development Deployment

```bash
# Build development image
docker build -f Dockerfile.dev -t andx-exchange-service:dev .

# Run development environment
docker-compose -f docker-compose.dev.yml up -d
```

### Option 3: Docker Build Script

Use the specialized build script for more control:

```bash
# Build production image
./scripts/docker-build.sh

# Build development image
./scripts/docker-build.sh -e development

# Build with custom tag
./scripts/docker-build.sh -t v1.0.0

# Build and push to registry
./scripts/docker-build.sh -t v1.0.0 -p -r your-registry.com
```

## Script Reference

### Deploy Script (`scripts/deploy.sh`)

Main deployment script with comprehensive features:

**Options:**

- `-e, --environment ENV`: Set environment (development|production)
- `-b, --build-only`: Only build, don't deploy
- `-s, --skip-tests`: Skip running tests
- `-f, --force-rebuild`: Force rebuild of Docker image
- `-h, --help`: Show help

**Features:**

- Automated testing before deployment
- Health checks after deployment
- Backup of current deployment
- Comprehensive logging
- Environment validation

### Build Script (`scripts/docker-build.sh`)

Specialized Docker image building:

**Options:**

- `-e, --environment ENV`: Set environment
- `-t, --tag TAG`: Set Docker image tag
- `-p, --push`: Push to registry
- `-n, --no-cache`: Build without cache
- `-r, --registry URL`: Set registry URL

**Features:**

- Multi-tag support
- Security scanning (if tools available)
- Image testing
- Registry push support

### Cleanup Script (`scripts/docker-cleanup.sh`)

Clean up Docker resources:

**Options:**

- `-a, --all`: Clean all resources
- `-i, --images`: Clean only images
- `-c, --containers`: Clean only containers
- `-v, --volumes`: Clean only volumes
- `-n, --networks`: Clean only networks
- `-f, --force`: Force without confirmation

## Production Deployment

### With Nginx Reverse Proxy

The included `nginx.conf` provides:

- Load balancing
- Rate limiting
- SSL termination (when configured)
- Security headers
- Gzip compression

To use with nginx:

```bash
# Start with nginx
docker-compose --profile production up -d
```

### Environment Variables

Key environment variables for production:

```bash
NODE_ENV=production
PORT=3000
COINGECKO_API_KEY=your_api_key
RATE_LIMIT_TTL=60
RATE_LIMIT_LIMIT=60
DEFAULT_CACHE_TTL_MS=60000
ALLOW_ORIGINS=https://yourdomain.com
```

### Health Checks

The application includes health checks at `/health` endpoint. Docker containers are configured with health checks that:

- Check every 30 seconds
- Timeout after 10 seconds
- Retry 3 times
- Wait 40 seconds before starting

### Monitoring

Check application status:

```bash
# View logs
docker-compose logs -f andx-exchange-service

# Check health
curl http://localhost/health

# View container status
docker-compose ps
```

## Development Deployment

For development with hot reload:

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f
```

The development setup includes:

- Volume mounting for hot reload
- Development-specific environment
- Exposed debugging ports

## Troubleshooting

### Common Issues

1. **Port already in use:**

   ```bash
   # Change port in .env file or stop conflicting service
   sudo lsof -i :80
   ```

2. **Permission denied on scripts:**

   ```bash
   chmod +x scripts/*.sh
   ```

3. **Docker daemon not running:**

   ```bash
   # Start Docker service
   sudo systemctl start docker  # Linux
   # or start Docker Desktop on macOS/Windows
   ```

4. **Build failures:**
   ```bash
   # Clean Docker cache and rebuild
   ./scripts/docker-cleanup.sh -f
   ./scripts/deploy.sh -f
   ```

### Logs and Debugging

```bash
# Application logs
docker-compose logs andx-exchange-service

# All services logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# Container shell access
docker-compose exec andx-exchange-service sh
```

### Performance Tuning

For production environments:

1. **Adjust rate limiting:**

   ```bash
   RATE_LIMIT_TTL=60
   RATE_LIMIT_LIMIT=100
   ```

2. **Cache configuration:**

   ```bash
   DEFAULT_CACHE_TTL_MS=300000  # 5 minutes
   ```

3. **Resource limits in docker-compose.yml:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M
         cpus: '0.5'
   ```

## Security Considerations

1. **Environment Variables:** Never commit `.env` files with sensitive data
2. **API Keys:** Use secure key management in production
3. **CORS:** Configure specific origins instead of `*`
4. **Rate Limiting:** Adjust based on expected traffic
5. **SSL/TLS:** Configure HTTPS in production (uncomment nginx SSL config)

## Backup and Recovery

The deployment script automatically creates backups before deployment. Manual backup:

```bash
# Export current container
docker export andx-exchange-service > backup-$(date +%Y%m%d).tar

# Backup volumes
docker run --rm -v andx-data:/data -v $(pwd):/backup alpine tar czf /backup/volumes-backup.tar.gz /data
```

## Scaling

For horizontal scaling:

```yaml
# In docker-compose.yml
services:
  andx-exchange-service:
    deploy:
      replicas: 3
```

Or use Docker Swarm / Kubernetes for advanced orchestration.
