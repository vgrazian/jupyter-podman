# Jupyter with Podman on macOS + VS Code Integration

## Quick Start

1. **Install Podman:**

```bash
brew install podman
podman machine init
podman machine start
```

2. **Build and start:**

```bash
chmod +x start-jupyter.sh
./start-jupyter.sh build
./start-jupyter.sh start
./start-jupyter.sh copy
```

3. **In VS Code:**

- Open Command Palette
- Type: `Jupyter: Select Notebook Kernel`
- Choose: `Existing Jupyter Server`
- Paste the URL from clipboard

## Your Configuration

- **URL:** `http://localhost:8890`
- **Token:** `a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d`
- **Complete URL:** `http://localhost:8890/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d`
- **Notebooks Directory:** `~/jupyter-notebooks`
- **Python Interpreter:** `/opt/anaconda3/bin/python`

configuredinVSCodesettings

## Available Commands

```bash
./start-jupyter.sh build # Build container
./start-jupyter.sh start # Start container
./start-jupyter.sh stop # Stop container
./start-jupyter.sh status # Check status
./start-jupyter.sh copy # Copy URL to clipboard
./start-jupyter.sh open # Open in browser
./start-jupyter.sh shell # Open container shell
./start-jupyter.sh restart # Restart container
./start-jupyter.sh logs # View container logs
./start-jupyter.sh vscode # Show VS Code connection details
```

## File Structure

```
jupyter-podman/
├── Containerfile # Container definition
├── start-jupyter.sh # Management script
├── requirements.txt # Python packages
├── setup.sh # Setup helper 

optional
├── .vscode/
│ └── settings.json # VS Code configuration
└── notebooks/ # Example notebooks
```

## Python Interpreter Configuration

The VS Code settings are configured to use `/opt/anaconda3/bin/python` as the default Python interpreter. This ensures compatibility with your existing Anaconda installation on macOS.

If you need to change the Python interpreter in the container, update the `Containerfile` base image:

```dockerfile
# Change this line to use a different Python base
FROM python:3.11-slim
```

## Connecting from VS Code

Method 1: Using the complete URL

recommended

1. Run `./start-jupyter.sh copy`
2. In VS Code, open Command Palette
3. Select `Jupyter: Select Notebook Kernel`
4. Choose `Existing Jupyter Server`
5. Paste the complete URL: `http://localhost:8890/?token=a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d`

Method 2: Separate URL and token

1. URL: `http://localhost:8890`
2. Token: `a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d`

## Persistence

Your notebooks are automatically saved to `~/jupyter-notebooks` on your macOS host. This directory is mounted into the container, so:

✅ Your work persists between container restarts
✅ You can access notebooks directly from Finder
✅ VS Code can open notebooks from this directory

## Customization

Changing the port
Edit `start-jupyter.sh` and modify:

```bash
PORT="8890" # Change to your preferred port
```

Changing Python packages
Edit `requirements.txt`, then rebuild:

```bash
./start-jupyter.sh stop
./start-jupyter.sh build
./start-jupyter.sh start
```

Changing the token

optional
Generate a new token:

```bash
openssl rand -hex 32
```

Update both `Containerfile` and `start-jupyter.sh` with the new token.

## Troubleshooting

VS Code cannot connect

1. **Check container status:** `./start-jupyter.sh status`
2. **Verify port is free:** `lsof -i :8890`
3. **Check container logs:** `./start-jupyter.sh logs`
4. **Restart VS Code:** Close and reopen VS Code after starting container
5. **Test in browser:** `./start-jupyter.sh open`

Port already in use
If port 8890 is occupied:

```bash
# Find what's using the port
lsof -i :8890

# Kill the process or change port in start-jupyter.sh
```

Podman machine not running

```bash
# Check podman machine status
podman machine list

# Start podman machine if stopped
podman machine start
```

Permission errors on mounted volumes

```bash
# Ensure proper permissions on macOS
chmod 755 ~/jupyter-notebooks
```

## Security Notes

- The token `a12c30b161be74d88eadea4ebe25f275ef72d5ab59b7568d` is hard-coded for convenience
- For production use, consider using a more secure token or enabling password authentication
- The container only exposes port 8890 to your local machine
- Jupyter runs as a non-root user inside the container

## Cleaning Up

To completely remove everything:

```bash
# Stop and remove container
./start-jupyter.sh stop

# Remove image
podman rmi jupyter-lab

# Remove local notebooks 

optional
rm -rf ~/jupyter-notebooks

# Remove podman machine 

optional
podman machine stop
podman machine rm
```

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Verify Podman machine is running: `podman machine list`
3. Check container logs: `./start-jupyter.sh logs`
4. Ensure port 8890 is not blocked by firewall

## References

- **Podman Documentation:** <https://podman.io/docs>
- **Jupyter Documentation:** <https://jupyter.org/documentation>
- **VS Code Jupyter Extension:** <https://code.visualstudio.com/docs/datascience/jupyter-notebooks>
- **Anaconda Python:** <https://docs.anaconda.com/>

## License

This setup is provided as-is for educational and development purposes. Modify as needed for your specific requirements.

**Happy coding with Jupyter and VS Code!**
