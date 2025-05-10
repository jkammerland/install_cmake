# CMake Installation Script

A simple bash script to install a specific version of CMake from source.

## Usage

```bash 
./install_cmake.sh -h # Show help message
# Downloads version and installs at ./cmake-3.31.6
./install_cmake.sh -v 3.31.6 -d ./cmake-3.31.6
# or
./install_cmake.sh -v 4.0.2 -d ./cmake-4.0.2
```

Without cloning the repository, you can also download download and pipe it with arguments directly:
```bash
curl -fsSL https://raw.githubusercontent.com/jkammerland/install_cmake/master/install_cmake.sh | bash -s -- -v 4.0.2 -d ./cmake-4.0.2
```

## Requirements
- `curl`
- `tar`
- `make`
- `nproc`

## Notes
- Uses a temporary directory for extraction
- Installs to specified directory (creates if missing at ./cmake)
- Verifies SHA-256 checksum before extraction
- Requires version in X.Y.Z format (e.g., 3.27.4)