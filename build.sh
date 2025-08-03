#!/bin/bash

# Atalanta Docker Build Script
# This script helps build and manage the Atalanta Docker container

set -e

# Configuration
IMAGE_NAME="atalanta"
VERSION="2.0"
DOCKERFILE="Dockerfile"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Atalanta Docker Build Script  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker found"
}

# Build the Docker image
build_image() {
    print_info "Building Atalanta Docker image..."
    
    if [ ! -f "$DOCKERFILE" ]; then
        print_error "Dockerfile not found in current directory"
        exit 1
    fi
    
    # Build the image
    docker build -t "${IMAGE_NAME}:${VERSION}" -t "${IMAGE_NAME}:latest" .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
        print_info "Image tags: ${IMAGE_NAME}:${VERSION}, ${IMAGE_NAME}:latest"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Test the built image
test_image() {
    print_info "Testing the built image..."
    
    # Test basic functionality
    docker run --rm "${IMAGE_NAME}:latest" atalanta -h g > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Image test passed"
    else
        print_warning "Image test failed - but image might still be functional"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -b, --build    Build the Docker image (default)"
    echo "  -t, --test     Test the built image"
    echo "  -a, --all      Build and test the image"
    echo "  -p, --push     Push image to Docker Hub (requires login)"
    echo "  -c, --clean    Remove built images"
    echo "  --tag TAG      Specify custom tag (default: $VERSION)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build the image"
    echo "  $0 --all             # Build and test"
    echo "  $0 --push           # Push to Docker Hub"
    echo "  $0 --tag 2.1        # Build with custom tag"
}

# Push to Docker Hub
push_image() {
    print_info "Pushing image to Docker Hub..."
    
    if [ -z "$DOCKER_USERNAME" ]; then
        read -p "Enter your Docker Hub username: " DOCKER_USERNAME
    fi
    
    # Tag for Docker Hub
    docker tag "${IMAGE_NAME}:${VERSION}" "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}"
    docker tag "${IMAGE_NAME}:latest" "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    
    # Push to Docker Hub
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}"
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    
    if [ $? -eq 0 ]; then
        print_success "Images pushed to Docker Hub successfully"
        print_info "Users can now run: docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
    else
        print_error "Failed to push images to Docker Hub"
        print_info "Make sure you're logged in: docker login"
        exit 1
    fi
}

# Clean up images
clean_images() {
    print_info "Removing built images..."
    
    docker rmi "${IMAGE_NAME}:${VERSION}" "${IMAGE_NAME}:latest" 2>/dev/null || true
    
    if [ ! -z "$DOCKER_USERNAME" ]; then
        docker rmi "${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}" "${DOCKER_USERNAME}/${IMAGE_NAME}:latest" 2>/dev/null || true
    fi
    
    print_success "Images cleaned up"
}

# Show image information
show_info() {
    print_info "Docker images:"
    docker images | grep "$IMAGE_NAME" || print_warning "No $IMAGE_NAME images found"
    
    echo
    print_info "To run the container:"
    echo "  docker run --rm -v \$(pwd):/data ${IMAGE_NAME}:latest atalanta your_circuit.bench"
    
    echo
    print_info "For interactive mode:"
    echo "  docker run --rm -it -v \$(pwd):/data ${IMAGE_NAME}:latest /bin/bash"
}

# Main execution
main() {
    print_header
    
    # Parse command line arguments
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -t|--test)
            check_docker
            test_image
            ;;
        -a|--all)
            check_docker
            build_image
            test_image
            show_info
            ;;
        -p|--push)
            check_docker
            push_image
            ;;
        -c|--clean)
            clean_images
            ;;
        --tag)
            VERSION="$2"
            check_docker
            build_image
            test_image
            ;;
        -b|--build|"")
            check_docker
            build_image
            show_info
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
