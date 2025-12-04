#!/bin/bash

# Configuration
CONTAINER_NAME="jupyter-podman"
IMAGE_NAME="jupyter-lab"
PORT="8890"  # Your working port
NOTEBOOKS_DIR="${HOME}/jupyter-notebooks"
WORKSPACE_DIR="/workspace"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Jupyter Podman Manager for macOS${NC}"
echo "======================================"

# Create local notebooks directory if it doesn't exist
mkdir -p "${NOTEBOOKS_DIR}"

# Function to build the image
build_image() {
    echo -e "${YELLOW}Building Jupyter image...${NC}"
    podman build -t ${IMAGE_NAME} -f Containerfile .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build image${NC}"
        exit 1
    fi
}

# Function to start the container
start_container() {
    echo -e "${YELLOW}Starting Jupyter container...${NC}"
    
    # Check if container already exists and remove it
    if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "Removing existing container..."
        podman rm -f ${CONTAINER_NAME}
    fi
    
    # Run the container with proper volume mounts
    podman run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:8888 \
        -v "${NOTEBOOKS_DIR}:${WORKSPACE_DIR}/notebooks:Z" \
        -v "$(pwd):${WORKSPACE_DIR}/src:Z" \
        --security-opt label=disable \
        ${IMAGE_NAME}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container started successfully${NC}"
        echo -e "\n${YELLOW}Jupyter Lab is running at:${NC}"
        echo -e "  ${GREEN}http://localhost:${PORT}/lab${NC}"
        echo -e "\n${YELLOW}Your connection details:${NC}"
        echo "  URL: http://localhost:${PORT}"
        echo "  Token: a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
        echo -e "\n${YELLOW}To connect from VS Code:${NC}"
        echo "  1. Install 'Jupyter' extension in VS Code"
        echo "  2. Open command palette (Cmd+Shift+P)"
        echo "  3. Type 'Jupyter: Select Notebook Kernel'"
        echo "  4. Choose 'Existing Jupyter Server'"
        echo "  5. Enter: http://localhost:${PORT}"
        echo "  6. Token: a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
        echo -e "\n${YELLOW}Quick connection URL for VS Code:${NC}"
        echo -e "  ${BLUE}http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d${NC}"
        echo -e "\n${YELLOW}Local notebooks directory:${NC} ${NOTEBOOKS_DIR}"
        echo -e "${YELLOW}Notebooks will persist in this directory.${NC}"
    else
        echo -e "${RED}✗ Failed to start container${NC}"
        exit 1
    fi
}

# Function to stop the container
stop_container() {
    echo -e "${YELLOW}Stopping Jupyter container...${NC}"
    podman stop ${CONTAINER_NAME} 2>/dev/null
    podman rm ${CONTAINER_NAME} 2>/dev/null
    echo -e "${GREEN}✓ Container stopped and removed${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${YELLOW}Container logs:${NC}"
    podman logs ${CONTAINER_NAME}
}

# Function to show container status
show_status() {
    echo -e "${YELLOW}Container status:${NC}"
    podman ps -a --filter "name=${CONTAINER_NAME}"
    
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "\n${GREEN}✓ Jupyter is running${NC}"
        echo -e "URL: ${BLUE}http://localhost:${PORT}${NC}"
        echo "Token: a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
        echo -e "\n${YELLOW}Connect in VS Code with:${NC}"
        echo "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
    else
        echo -e "\n${YELLOW}Container is not running${NC}"
    fi
}

# Function to open Jupyter in browser
open_browser() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
        echo -e "${GREEN}✓ Opening browser with auto-login link${NC}"
    else
        echo -e "${YELLOW}Please open:${NC}"
        echo "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
    fi
}

# Function to get the VS Code connection string
get_vscode_connection() {
    echo -e "${GREEN}VS Code Connection String:${NC}"
    echo "URL: http://localhost:${PORT}"
    echo "Token: a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
    echo -e "\n${YELLOW}Or use this complete URL:${NC}"
    echo "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
}

# Function to copy connection string to clipboard (macOS only)
copy_connection() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d" | pbcopy
        echo -e "${GREEN}✓ Connection URL copied to clipboard${NC}"
        echo "Paste into VS Code when prompted for Jupyter server URL"
    else
        echo -e "${YELLOW}Copy this URL for VS Code:${NC}"
        echo "http://localhost:${PORT}/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
    fi
}

# Function to open shell in container
open_shell() {
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Opening shell in container...${NC}"
        podman exec -it ${CONTAINER_NAME} /bin/bash
    else
        echo -e "${RED}Container is not running. Start it first with: $0 start${NC}"
    fi
}

# Main menu
case "$1" in
    "build")
        build_image
        ;;
    "start")
        start_container
        ;;
    "stop")
        stop_container
        ;;
    "restart")
        stop_container
        sleep 2
        start_container
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "open")
        open_browser
        ;;
    "vscode")
        get_vscode_connection
        ;;
    "copy")
        copy_connection
        ;;
    "shell")
        open_shell
        ;;
    *)
        echo "Usage: $0 {build|start|stop|restart|logs|status|open|vscode|copy|shell}"
        echo ""
        echo "Commands:"
        echo "  build    - Build the container image"
        echo "  start    - Start the Jupyter container"
        echo "  stop     - Stop and remove the container"
        echo "  restart  - Restart the container"
        echo "  logs     - Show container logs"
        echo "  status   - Show container status"
        echo "  open     - Open Jupyter in browser (with auto-login)"
        echo "  vscode   - Show VS Code connection details"
        echo "  copy     - Copy connection URL to clipboard (macOS)"
        echo "  shell    - Open shell in running container"
        echo ""
        echo "Your Configuration:"
        echo "  Port: ${PORT}"
        echo "  Token: a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d"
        echo "  Notebooks: ${NOTEBOOKS_DIR}"
        echo ""
        echo "Example workflow:"
        echo "  $0 build    # Build the image"
        echo "  $0 start    # Start the container"
        echo "  $0 copy     # Copy connection URL"
        echo "  # Then in VS Code, paste the URL when prompted"
        exit 1
        ;;
esac