#!/bin/bash

# AndX Exchange Service Deployment Script
# This script handles the deployment of the AndX Exchange Service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="andx-exchange-service"
DOCKER_IMAGE="$APP_NAME"
CONTAINER_NAME="$APP_NAME"
BACKUP_DIR="./backups"
LOG_FILE="./deploy.log"

# Default values
ENVIRONMENT="production"
BUILD_ONLY=false
SKIP_TESTS=false
FORCE_REBUILD=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Set environment (development|production) [default: production]"
    echo "  -b, --build-only         Only build the Docker image, don't deploy"
    echo "  -s, --skip-tests         Skip running tests before deployment"
    echo "  -f, --force-rebuild      Force rebuild of Docker image"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                       Deploy to production"
    echo "  $0 -e development        Deploy to development"
    echo "  $0 -b                    Build only"
    echo "  $0 -s -f                 Skip tests and force rebuild"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -f|--force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'development' or 'production'"
    exit 1
fi

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if .env file exists
    if [[ ! -f .env ]]; then
        print_warning ".env file not found. Creating from template..."
        cp .env.example .env 2>/dev/null || {
            print_error "No .env.example file found. Please create .env file manually"
            exit 1
        }
    fi
    
    print_success "Prerequisites check passed"
}

# Function to run tests
run_tests() {
    if [[ "$SKIP_TESTS" == true ]]; then
        print_warning "Skipping tests as requested"
        return 0
    fi
    
    print_status "Running tests..."
    
    if npm test; then
        print_success "All tests passed"
    else
        print_error "Tests failed. Deployment aborted."
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image..."
    
    local dockerfile="Dockerfile"
    local compose_file="docker-compose.yml"
    
    if [[ "$ENVIRONMENT" == "development" ]]; then
        dockerfile="Dockerfile.dev"
        compose_file="docker-compose.dev.yml"
    fi
    
    local build_args=""
    if [[ "$FORCE_REBUILD" == true ]]; then
        build_args="--no-cache"
    fi
    
    if docker build $build_args -f "$dockerfile" -t "$DOCKER_IMAGE:latest" -t "$DOCKER_IMAGE:$(date +%Y%m%d-%H%M%S)" .; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to backup current deployment
backup_current() {
    print_status "Creating backup of current deployment..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Export current container if it exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        local backup_name="$BACKUP_DIR/${CONTAINER_NAME}_$(date +%Y%m%d_%H%M%S).tar"
        if docker export "$CONTAINER_NAME" > "$backup_name"; then
            print_success "Backup created: $backup_name"
        else
            print_warning "Failed to create backup, continuing anyway..."
        fi
    fi
}

# Function to deploy the application
deploy() {
    print_status "Deploying $APP_NAME to $ENVIRONMENT environment..."
    
    local compose_file="docker-compose.yml"
    if [[ "$ENVIRONMENT" == "development" ]]; then
        compose_file="docker-compose.dev.yml"
    fi
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose -f "$compose_file" down || true
    
    # Start new containers
    print_status "Starting new containers..."
    if docker-compose -f "$compose_file" up -d; then
        print_success "Deployment completed successfully"
    else
        print_error "Deployment failed"
        exit 1
    fi
    
    # Wait for health check
    print_status "Waiting for application to be healthy..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker-compose -f "$compose_file" ps | grep -q "healthy"; then
            print_success "Application is healthy and ready"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            print_error "Application failed to become healthy within timeout"
            exit 1
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for health check..."
        sleep 10
        ((attempt++))
    done
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo ""
    
    local compose_file="docker-compose.yml"
    if [[ "$ENVIRONMENT" == "development" ]]; then
        compose_file="docker-compose.dev.yml"
    fi
    
    docker-compose -f "$compose_file" ps
    echo ""
    
    print_status "Application logs (last 20 lines):"
    docker-compose -f "$compose_file" logs --tail=20 "$APP_NAME" || docker-compose -f "$compose_file" logs --tail=20
}

# Main deployment process
main() {
    print_status "Starting deployment process for $APP_NAME"
    print_status "Environment: $ENVIRONMENT"
    print_status "Build only: $BUILD_ONLY"
    print_status "Skip tests: $SKIP_TESTS"
    print_status "Force rebuild: $FORCE_REBUILD"
    echo ""
    
    log "Deployment started - Environment: $ENVIRONMENT"
    
    check_prerequisites
    run_tests
    build_image
    
    if [[ "$BUILD_ONLY" == true ]]; then
        print_success "Build completed successfully. Skipping deployment as requested."
        log "Build completed (build-only mode)"
        exit 0
    fi
    
    backup_current
    deploy
    show_status
    
    print_success "Deployment process completed successfully!"
    log "Deployment completed successfully"
    
    echo ""
    print_status "Application is now running at:"
    if [[ "$ENVIRONMENT" == "development" ]]; then
        echo "  - API: http://localhost"
        echo "  - Swagger: http://localhost/api"
    else
        echo "  - API: http://localhost"
        echo "  - Swagger: http://localhost/api"
    fi
}

# Run main function
main "$@"
