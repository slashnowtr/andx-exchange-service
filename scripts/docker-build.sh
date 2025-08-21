#!/bin/bash

# AndX Exchange Service Docker Build Script
# This script handles building Docker images for different environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="andx-exchange-service"
DOCKER_REGISTRY=""  # Set this if you want to push to a registry
DEFAULT_TAG="latest"

# Default values
ENVIRONMENT="production"
PUSH_TO_REGISTRY=false
NO_CACHE=false
TAG="$DEFAULT_TAG"

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
    echo "  -t, --tag TAG           Set Docker image tag [default: latest]"
    echo "  -p, --push              Push image to registry after building"
    echo "  -n, --no-cache          Build without using cache"
    echo "  -r, --registry URL      Set Docker registry URL"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      Build production image with latest tag"
    echo "  $0 -e development       Build development image"
    echo "  $0 -t v1.0.0 -p         Build and push with tag v1.0.0"
    echo "  $0 -n                   Build without cache"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_TO_REGISTRY=true
            shift
            ;;
        -n|--no-cache)
            NO_CACHE=true
            shift
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
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

# Set image name based on registry
if [[ -n "$DOCKER_REGISTRY" ]]; then
    IMAGE_NAME="$DOCKER_REGISTRY/$APP_NAME"
else
    IMAGE_NAME="$APP_NAME"
fi

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
    
    print_success "Prerequisites check passed"
}

# Function to build Docker image
build_image() {
    print_status "Building Docker image for $ENVIRONMENT environment..."
    
    local dockerfile="Dockerfile"
    if [[ "$ENVIRONMENT" == "development" ]]; then
        dockerfile="Dockerfile.dev"
    fi
    
    # Check if Dockerfile exists
    if [[ ! -f "$dockerfile" ]]; then
        print_error "Dockerfile not found: $dockerfile"
        exit 1
    fi
    
    # Build arguments
    local build_args=""
    if [[ "$NO_CACHE" == true ]]; then
        build_args="--no-cache"
    fi
    
    # Generate timestamp tag
    local timestamp_tag="$(date +%Y%m%d-%H%M%S)"
    
    print_status "Building image: $IMAGE_NAME:$TAG"
    print_status "Using Dockerfile: $dockerfile"
    
    # Build the image with multiple tags
    if docker build $build_args \
        -f "$dockerfile" \
        -t "$IMAGE_NAME:$TAG" \
        -t "$IMAGE_NAME:$timestamp_tag" \
        -t "$IMAGE_NAME:latest" \
        .; then
        print_success "Docker image built successfully"
        print_success "Tags created:"
        echo "  - $IMAGE_NAME:$TAG"
        echo "  - $IMAGE_NAME:$timestamp_tag"
        echo "  - $IMAGE_NAME:latest"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to push image to registry
push_image() {
    if [[ "$PUSH_TO_REGISTRY" != true ]]; then
        return 0
    fi
    
    if [[ -z "$DOCKER_REGISTRY" ]]; then
        print_error "Cannot push to registry: no registry URL specified"
        exit 1
    fi
    
    print_status "Pushing image to registry..."
    
    # Push all tags
    local tags=("$TAG" "latest" "$(date +%Y%m%d-%H%M%S)")
    
    for tag in "${tags[@]}"; do
        print_status "Pushing $IMAGE_NAME:$tag"
        if docker push "$IMAGE_NAME:$tag"; then
            print_success "Successfully pushed $IMAGE_NAME:$tag"
        else
            print_error "Failed to push $IMAGE_NAME:$tag"
            exit 1
        fi
    done
}

# Function to show image information
show_image_info() {
    print_status "Image Information:"
    echo ""
    
    # Show image details
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"
    
    echo ""
    print_status "Image layers:"
    docker history "$IMAGE_NAME:$TAG" --format "table {{.CreatedBy}}\t{{.Size}}" | head -10
}

# Function to run security scan (if available)
security_scan() {
    print_status "Running security scan..."
    
    # Check if docker scan is available
    if docker scan --help &> /dev/null; then
        print_status "Running Docker scan..."
        docker scan "$IMAGE_NAME:$TAG" || print_warning "Security scan completed with warnings"
    elif command -v trivy &> /dev/null; then
        print_status "Running Trivy scan..."
        trivy image "$IMAGE_NAME:$TAG" || print_warning "Security scan completed with warnings"
    else
        print_warning "No security scanning tool available (docker scan or trivy)"
    fi
}

# Function to test the built image
test_image() {
    print_status "Testing the built image..."
    
    local test_container="$APP_NAME-test"
    
    # Remove existing test container if it exists
    docker rm -f "$test_container" 2>/dev/null || true
    
    # Run the container in test mode
    print_status "Starting test container..."
    if docker run -d --name "$test_container" -p 3003:3000 "$IMAGE_NAME:$TAG"; then
        print_success "Test container started"
        
        # Wait a bit for the application to start
        sleep 10
        
        # Test if the application is responding
        if curl -f http://localhost:3003/health &> /dev/null; then
            print_success "Application is responding to health checks"
        else
            print_warning "Application health check failed"
        fi
        
        # Clean up test container
        docker rm -f "$test_container"
        print_status "Test container cleaned up"
    else
        print_error "Failed to start test container"
        exit 1
    fi
}

# Main build process
main() {
    print_status "Starting Docker build process for $APP_NAME"
    print_status "Environment: $ENVIRONMENT"
    print_status "Tag: $TAG"
    print_status "Push to registry: $PUSH_TO_REGISTRY"
    print_status "No cache: $NO_CACHE"
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        print_status "Registry: $DOCKER_REGISTRY"
    fi
    echo ""
    
    check_prerequisites
    build_image
    show_image_info
    security_scan
    test_image
    push_image
    
    print_success "Docker build process completed successfully!"
    
    echo ""
    print_status "Next steps:"
    echo "  - Run the image: docker run -p 80:3000 $IMAGE_NAME:$TAG"
    echo "  - Use with docker-compose: docker-compose up"
    if [[ "$PUSH_TO_REGISTRY" == true ]]; then
        echo "  - Image is available in registry: $IMAGE_NAME:$TAG"
    fi
}

# Run main function
main "$@"
