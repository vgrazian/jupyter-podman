#!/bin/bash

# Configuration
CONTAINER_NAME="jupyter-podman"
IMAGE_NAME="jupyter-lab"
PORT="8890"
NOTEBOOKS_DIR="${HOME}/jupyter-notebooks"
WORKSPACE_DIR="/workspace"
TOKEN_FILE="token.ini"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Jupyter Podman Manager for macOS${NC}"
echo "======================================"

# Load token from token.ini
load_token() {
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(grep '^token=' "$TOKEN_FILE" | cut -d= -f2)
        if [ -n "$TOKEN" ]; then
            echo -e "${GREEN}✓ Token loaded from $TOKEN_FILE${NC}"
            return 0
        else
            echo -e "${RED}✗ No token found in $TOKEN_FILE${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ $TOKEN_FILE not found${NC}"
        echo -e "${YELLOW}Creating default $TOKEN_FILE...${NC}"
        generate_token
        return $?
    fi
}

# Generate a new token
generate_token() {
    echo -e "${YELLOW}Generating new token...${NC}"
    NEW_TOKEN=$(openssl rand -hex 32 2>/dev/null || python3 -c "import secrets; print(secrets.token_hex(32))")
    echo "token=$NEW_TOKEN" > "$TOKEN_FILE"
    echo -e "${GREEN}✓ New token generated and saved to $TOKEN_FILE${NC}"
    TOKEN=$NEW_TOKEN
}

# Create local notebooks directory if it doesn't exist
mkdir -p "${NOTEBOOKS_DIR}"

# Load token at script start
if ! load_token; then
    echo -e "${RED}Failed to load token. Exiting.${NC}"
    exit 1
fi

# Function to build the image
build_image() {
    echo -e "${YELLOW}Building Jupyter image...${NC}"
    # Copy token.ini to container context
    cp "$TOKEN_FILE" .container_token.ini 2>/dev/null || echo "token=$TOKEN" > .container_token.ini
    podman build -t ${IMAGE_NAME} -f Containerfile .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image built successfully${NC}"
        rm -f .container_token.ini
    else
        echo -e "${RED}✗ Failed to build image${NC}"
        rm -f .container_token.ini
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
        
        # Wait a moment for Jupyter to start
        echo -e "${YELLOW}Waiting for Jupyter to initialize...${NC}"
        sleep 3
        
        # Show connection details
        show_connection_details
        
        # Ask if user wants to open Chrome
        read -p "Open in Chrome? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open_chrome
        fi
    else
        echo -e "${RED}✗ Failed to start container${NC}"
        exit 1
    fi
}

# Function to show connection details
show_connection_details() {
    echo -e "\n${YELLOW}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 Jupyter Lab is running!${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
    echo -e "\n${BLUE}Connection Details:${NC}"
    echo -e "  URL: ${GREEN}http://localhost:${PORT}/lab${NC}"
    echo -e "  Token: ${GREEN}${TOKEN}${NC}"
    echo -e "\n${BLUE}Quick Links:${NC}"
    echo -e "  ${YELLOW}With auto-login:${NC}"
    echo -e "  http://localhost:${PORT}/lab?token=${TOKEN}"
    echo -e "\n  ${YELLOW}For VS Code:${NC}"
    echo -e "  http://localhost:${PORT}/?token=${TOKEN}"
    echo -e "\n${YELLOW}══════════════════════════════════════════════════${NC}"
}

# Function to open Chrome with Jupyter
open_chrome() {
    echo -e "${YELLOW}Opening Chrome with Jupyter...${NC}"
    if [ -d "/Applications/Google Chrome.app" ]; then
        open -a "Google Chrome" "http://localhost:${PORT}/lab?token=${TOKEN}"
        echo -e "${GREEN}✓ Chrome opened with Jupyter Lab${NC}"
    elif [ -d "/Applications/Chrome.app" ]; then
        open -a "Chrome" "http://localhost:${PORT}/lab?token=${TOKEN}"
        echo -e "${GREEN}✓ Chrome opened with Jupyter Lab${NC}"
    else
        echo -e "${RED}✗ Google Chrome not found in Applications${NC}"
        echo -e "${YELLOW}Opening in default browser instead...${NC}"
        open "http://localhost:${PORT}/lab?token=${TOKEN}"
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
        show_connection_details
    else
        echo -e "\n${YELLOW}Container is not running${NC}"
    fi
}

# Function to open Jupyter in browser
open_browser() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:${PORT}/lab?token=${TOKEN}"
        echo -e "${GREEN}✓ Opening browser with auto-login link${NC}"
    else
        echo -e "${YELLOW}Please open:${NC}"
        echo "http://localhost:${PORT}/lab?token=${TOKEN}"
    fi
}

# Function to get the VS Code connection string
get_vscode_connection() {
    echo -e "${GREEN}VS Code Connection String:${NC}"
    echo "URL: http://localhost:${PORT}"
    echo "Token: ${TOKEN}"
    echo -e "\n${YELLOW}Or use this complete URL:${NC}"
    echo "http://localhost:${PORT}/?token=${TOKEN}"
}

# Function to copy connection string to clipboard (macOS only)
copy_connection() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "http://localhost:${PORT}/?token=${TOKEN}" | pbcopy
        echo -e "${GREEN}✓ Connection URL copied to clipboard${NC}"
        echo "Paste into VS Code when prompted for Jupyter server URL"
    else
        echo -e "${YELLOW}Copy this URL for VS Code:${NC}"
        echo "http://localhost:${PORT}/?token=${TOKEN}"
    fi
}

# Function to regenerate token
regenerate_token() {
    echo -e "${YELLOW}Regenerating token...${NC}"
    generate_token
    echo -e "\n${GREEN}New token generated!${NC}"
    echo -e "You need to rebuild the container for the new token to take effect:"
    echo -e "  ./start-jupyter.sh stop"
    echo -e "  ./start-jupyter.sh build"
    echo -e "  ./start-jupyter.sh start"
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

# Function to open Chrome specifically
open_chrome_cmd() {
    open_chrome
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
    "open"|"browser")
        open_browser
        ;;
    "chrome")
        open_chrome_cmd
        ;;
    "vscode")
        get_vscode_connection
        ;;
    "copy")
        copy_connection
        ;;
    "token"|"newtoken")
        regenerate_token
        ;;
    "shell")
        open_shell
        ;;
    *)
        echo "Usage: $0 {build|start|stop|restart|logs|status|open|chrome|vscode|copy|token|shell}"
        echo ""
        echo "Commands:"
        echo "  build    - Build the container image"
        echo "  start    - Start the Jupyter container (asks to open Chrome)"
        echo "  stop     - Stop and remove the container"
        echo "  restart  - Restart the container"
        echo "  logs     - Show container logs"
        echo "  status   - Show container status"
        echo "  open     - Open Jupyter in default browser"
        echo "  chrome   - Open Jupyter in Google Chrome"
        echo "  vscode   - Show VS Code connection details"
        echo "  copy     - Copy connection URL to clipboard (macOS)"
        echo "  token    - Generate a new token (requires rebuild)"
        echo "  shell    - Open shell in running container"
        echo ""
        echo "Current Configuration:"
        echo "  Port: ${PORT}"
        echo "  Token file: ${TOKEN_FILE}"
        echo "  Notebooks: ${NOTEBOOKS_DIR}"
        echo ""
        echo "Token: ${TOKEN:0:20}..."
        echo ""
        echo "Example workflow:"
        echo "  $0 build    # Build the image"
        echo "  $0 start    # Start the container (will ask to open Chrome)"
        echo "  $0 chrome   # Open Chrome if not opened initially"
        echo "  # Or use: $0 start then press 'y' when asked"
        exit 1
        ;;
esac