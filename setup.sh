#!/bin/bash

# setup.sh - Initial setup script

echo "Setting up Jupyter with Podman on macOS..."

# Make main script executable
chmod +x start-jupyter.sh

# Create necessary directories
mkdir -p notebooks .vscode

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "Podman not found. Installing via Homebrew..."
    brew install podman
    
    echo "Initializing Podman machine..."
    podman machine init
    podman machine start
fi

# Check if VS Code Jupyter extension is installed
echo "Make sure you have these VS Code extensions installed:"
echo "1. Jupyter (by Microsoft)"
echo "2. Python (by Microsoft) - Optional but recommended"
echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Build the image: ./start-jupyter.sh build"
echo "2. Start the container: ./start-jupyter.sh start"
echo "3. Copy connection: ./start-jupyter.sh copy"
echo "4. In VS Code, paste the URL when prompted for Jupyter server"