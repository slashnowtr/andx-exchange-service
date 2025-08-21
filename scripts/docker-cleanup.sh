#!/bin/bash

# AndX Exchange Service Docker Cleanup Script
# This script helps clean up Docker resources

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="andx-exchange-service"

# Default values
FORCE=false
CLEAN_ALL=false
CLEAN_IMAGES=false
CLEAN_CONTAINERS=false
CLEAN_VOLUMES=false
CLEAN_NETWORKS=false

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
    echo "  -a, --all               Clean all Docker resources (images, containers, volumes, networks)"
    echo "  -i, --images            Clean only images"
    echo "  -c, --containers        Clean only containers"
    echo "  -v, --volumes           Clean only volumes"
    echo "  -n, --networks          Clean only networks"
    echo "  -f, --force             Force cleanup without confirmation"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -a                   Clean all resources (with confirmation)"
    echo "  $0 -i -f                Force clean only images"
    echo "  $0 -c -v                Clean containers and volumes"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -i|--images)
            CLEAN_IMAGES=true
            shift
            ;;
        -c|--containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        -v|--volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        -n|--networks)
            CLEAN_NETWORKS=true
            shift
            ;;
        -f|--force)
            FORCE=true
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

# If no specific options are set, default to cleaning all
if [[ "$CLEAN_ALL" == false && "$CLEAN_IMAGES" == false && "$CLEAN_CONTAINERS" == false && "$CLEAN_VOLUMES" == false && "$CLEAN_NETWORKS" == false ]]; then
    CLEAN_ALL=true
fi

# Set individual flags if cleaning all
if [[ "$CLEAN_ALL" == true ]]; then
    CLEAN_IMAGES=true
    CLEAN_CONTAINERS=true
    CLEAN_VOLUMES=true
    CLEAN_NETWORKS=true
fi

# Function to confirm action
confirm_action() {
    if [[ "$FORCE" == true ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}WARNING: This will remove Docker resources related to $APP_NAME${NC}"
    echo "The following will be cleaned:"
    
    if [[ "$CLEAN_CONTAINERS" == true ]]; then
        echo "  - Containers"
    fi
    if [[ "$CLEAN_IMAGES" == true ]]; then
        echo "  - Images"
    fi
    if [[ "$CLEAN_VOLUMES" == true ]]; then
        echo "  - Volumes"
    fi
    if [[ "$CLEAN_NETWORKS" == true ]]; then
        echo "  - Networks"
    fi
    
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Function to show current Docker resources
show_current_resources() {
    print_status "Current Docker resources for $APP_NAME:"
    echo ""
    
    echo "Containers:"
    docker ps -a --filter "name=$APP_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "No containers found"
    echo ""
    
    echo "Images:"
    docker images --filter "reference=$APP_NAME*" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" || echo "No images found"
    echo ""
    
    echo "Volumes:"
    docker volume ls --filter "name=$APP_NAME" --format "table {{.Name}}\t{{.Driver}}" || echo "No volumes found"
    echo ""
    
    echo "Networks:"
    docker network ls --filter "name=$APP_NAME" --format "table {{.Name}}\t{{.Driver}}" || echo "No networks found"
    echo ""
}

# Function to clean containers
clean_containers() {
    if [[ "$CLEAN_CONTAINERS" != true ]]; then
        return 0
    fi
    
    print_status "Cleaning containers..."
    
    # Stop and remove containers
    local containers=$(docker ps -aq --filter "name=$APP_NAME")
    if [[ -n "$containers" ]]; then
        print_status "Stopping containers..."
        docker stop $containers || true
        
        print_status "Removing containers..."
        docker rm $containers || true
        
        print_success "Containers cleaned"
    else
        print_status "No containers to clean"
    fi
}

# Function to clean images
clean_images() {
    if [[ "$CLEAN_IMAGES" != true ]]; then
        return 0
    fi
    
    print_status "Cleaning images..."
    
    # Remove images
    local images=$(docker images -q --filter "reference=$APP_NAME*")
    if [[ -n "$images" ]]; then
        print_status "Removing images..."
        docker rmi $images || true
        
        print_success "Images cleaned"
    else
        print_status "No images to clean"
    fi
    
    # Clean dangling images
    local dangling=$(docker images -q --filter "dangling=true")
    if [[ -n "$dangling" ]]; then
        print_status "Removing dangling images..."
        docker rmi $dangling || true
    fi
}

# Function to clean volumes
clean_volumes() {
    if [[ "$CLEAN_VOLUMES" != true ]]; then
        return 0
    fi
    
    print_status "Cleaning volumes..."
    
    # Remove named volumes
    local volumes=$(docker volume ls -q --filter "name=$APP_NAME")
    if [[ -n "$volumes" ]]; then
        print_status "Removing volumes..."
        docker volume rm $volumes || true
        
        print_success "Volumes cleaned"
    else
        print_status "No volumes to clean"
    fi
    
    # Clean dangling volumes
    local dangling_volumes=$(docker volume ls -q --filter "dangling=true")
    if [[ -n "$dangling_volumes" ]]; then
        print_status "Removing dangling volumes..."
        docker volume rm $dangling_volumes || true
    fi
}

# Function to clean networks
clean_networks() {
    if [[ "$CLEAN_NETWORKS" != true ]]; then
        return 0
    fi
    
    print_status "Cleaning networks..."
    
    # Remove custom networks
    local networks=$(docker network ls -q --filter "name=$APP_NAME")
    if [[ -n "$networks" ]]; then
        print_status "Removing networks..."
        docker network rm $networks || true
        
        print_success "Networks cleaned"
    else
        print_status "No networks to clean"
    fi
}

# Function to run system prune
system_prune() {
    print_status "Running system prune..."
    
    if [[ "$FORCE" == true ]]; then
        docker system prune -f
    else
        docker system prune
    fi
    
    print_success "System prune completed"
}

# Function to show disk usage
show_disk_usage() {
    print_status "Docker disk usage:"
    docker system df
}

# Main cleanup process
main() {
    print_status "Starting Docker cleanup for $APP_NAME"
    echo ""
    
    show_current_resources
    confirm_action
    
    print_status "Starting cleanup process..."
    
    clean_containers
    clean_images
    clean_volumes
    clean_networks
    
    if [[ "$CLEAN_ALL" == true ]]; then
        system_prune
    fi
    
    print_success "Cleanup process completed!"
    echo ""
    
    show_disk_usage
    
    echo ""
    print_status "Cleanup summary:"
    if [[ "$CLEAN_CONTAINERS" == true ]]; then
        echo "  ✓ Containers cleaned"
    fi
    if [[ "$CLEAN_IMAGES" == true ]]; then
        echo "  ✓ Images cleaned"
    fi
    if [[ "$CLEAN_VOLUMES" == true ]]; then
        echo "  ✓ Volumes cleaned"
    fi
    if [[ "$CLEAN_NETWORKS" == true ]]; then
        echo "  ✓ Networks cleaned"
    fi
}

# Run main function
main "$@"
