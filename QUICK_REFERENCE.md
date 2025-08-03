# Atalanta Docker Quick Reference

## Essential Commands

### From Docker Hub (End Users)

```bash
# Pull image
docker pull yourusername/atalanta:latest

# Basic usage (one-shot) - with named volume
docker run --rm -v atalanta_data:/data yourusername/atalanta:latest atalanta circuit.bench

# Interactive mode (multiple commands) - with named volume
docker run --rm -it -v atalanta_data:/data yourusername/atalanta:latest /bin/bash
```

### Local Build

```bash
# Build image
docker build -t atalanta:2.0 .

# Use locally built image
docker run --rm -v $(pwd):/data atalanta:2.0 atalanta circuit.bench
```

## Volume & Persistence

| Scenario | Command | Result |
|----------|---------|---------|
| **Named volume (Recommended)** | `-v atalanta_data:/data` | Cross-platform persistence, Docker managed |
| **Current directory** | `-v $(pwd):/data` | Files persist in current directory |
| **Specific directory** | `-v ~/projects:/data` | Files persist in ~/projects |
| **Windows path** | `-v C:/Users/YourName/atalanta:/data` | Windows-specific bind mount |
| **No volume** | ❌ No `-v` flag | Files lost when container stops |

### ✅ Best Practice: Named Volumes
```bash
# Create and use named volume (cross-platform)
docker run --rm -v atalanta_data:/data yourusername/atalanta:latest atalanta circuit.bench

# Access files in the volume
docker run --rm -it -v atalanta_data:/data yourusername/atalanta:latest /bin/bash
```

### Managing Named Volumes
```bash
# List all volumes
docker volume ls

# Inspect volume location
docker volume inspect atalanta_data

# Remove volume (deletes all data!)
docker volume rm atalanta_data

# Copy files to/from volume
docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine cp /host/circuit.bench /data/
```

## Interactive vs Non-Interactive

| Mode | Command | Use Case |
|------|---------|----------|
| **One-shot (Named Volume)** | `docker run --rm -v atalanta_data:/data yourusername/atalanta:latest atalanta circuit.bench` | Single analysis |
| **Interactive (Named Volume)** | `docker run --rm -it -v atalanta_data:/data yourusername/atalanta:latest /bin/bash` | Multiple commands |
| One-shot (Local) | `docker run --rm -v $(pwd):/data atalanta:2.0 atalanta circuit.bench` | Single analysis (local build) |
| Background | `docker run -d -v atalanta_data:/data yourusername/atalanta:latest atalanta circuit.bench` | Long-running analysis |

## Common Atalanta Options

| Option | Purpose | Example |
|--------|---------|---------|
| `-A` | All test patterns per fault | `atalanta -A circuit.bench` |
| `-l file.log` | Create log file | `atalanta -l analysis.log circuit.bench` |
| `-t output.test` | Custom output file | `atalanta -t custom.test circuit.bench` |
| `-r 32` | 32 random pattern sessions | `atalanta -r 32 circuit.bench` |
| `-L` | Enable learning | `atalanta -L circuit.bench` |

## File Types

| Extension | Description | Example |
|-----------|-------------|---------|
| `.bench` | Input circuit (ISCAS89) | `c432.bench` |
| `.test` | Output test patterns | `c432.test` |
| `.log` | Analysis log (optional) | `analysis.log` |
| `.ufaults` | Aborted faults (optional) | `c432.ufaults` |

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "Permission denied" | `chmod -R 755 ~/data_directory` |
| "File not found" | Ensure files are in mounted volume |
| "Interactive mode not working" | Add `-it` flags |
| "Files disappear" | Always use volume mounting `-v` |
| "Out of memory" | Add `-m 4g` for 4GB memory limit |

## Example Workflows

### Quick Test (After Docker Pull)
```bash
# 1. Pull the image
docker pull yourusername/atalanta:latest

# 2. Copy your circuit files to the Docker volume
docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine cp /host/your_circuit.bench /data/

# 3. Run analysis
docker run --rm -v atalanta_data:/data yourusername/atalanta:latest atalanta your_circuit.bench

# 4. View results
docker run --rm -v atalanta_data:/data alpine cat /data/your_circuit.test
```

### Interactive Session (After Docker Pull)
```bash
# 1. Pull the image
docker pull yourusername/atalanta:latest

# 2. Start interactive session with named volume
docker run --rm -it -v atalanta_data:/data yourusername/atalanta:latest /bin/bash

# 3. Inside container - copy your files first:
# (You can copy files from outside using the copy method above)

# 4. Run analysis:
atalanta circuit1.bench
atalanta -A circuit2.bench
ls -la  # See all generated files
exit
```

### Cross-Platform File Management
```bash
# Copy files TO the Docker volume (Windows/Mac/Linux)
docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine cp /host/circuit.bench /data/

# Copy files FROM the Docker volume
docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine cp /data/circuit.test /host/

# List files in volume
docker run --rm -v atalanta_data:/data alpine ls -la /data

# View file content from volume
docker run --rm -v atalanta_data:/data alpine cat /data/circuit.test
```

### Batch Processing
```bash
# Copy all .bench files to Docker volume first
for circuit in *.bench; do
    docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine cp "/host/$circuit" /data/
done

# Process all circuits using named volume
docker run --rm -it -v atalanta_data:/data yourusername/atalanta:latest /bin/bash -c "
cd /data
for circuit in *.bench; do
    echo 'Processing \$circuit...'
    atalanta \"\$circuit\"
done
"

# Copy results back to host
docker run --rm -v atalanta_data:/data -v $(pwd):/host alpine sh -c "cp /data/*.test /host/"
```

## Remember: Named Volumes are Best Practice!
- ✅ Use `-v atalanta_data:/data` for cross-platform compatibility
- ✅ Works on Windows, Mac, Linux without path issues
- ✅ Docker manages the volume location automatically
- ✅ Persistent across container restarts and system reboots
- ⚠️ Use file copy commands to transfer files to/from volume
