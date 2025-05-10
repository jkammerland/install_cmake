#!/bin/bash
# CMake Installation Script
# Usage: ./install_cmake.sh -v <cmake_version> -d <install_prefix>

# Exit on any error
set -e

# Default values
CMAKE_VERSION=""
INSTALL_PREFIX="./cmake"

# Display help function
show_help() {
  echo "Usage: $0 -v <cmake_version> -d <install_prefix>"
  echo ""
  echo "Options:"
  echo "  -v VERSION    CMake version to install (required, format: X.Y.Z)"
  echo "  -d DIRECTORY  Installation directory (default: ./cmake)"
  echo "  -h            Display this help message"
}

# Parse command line options
while getopts "v:d:h" opt; do
  case "$opt" in
    v) CMAKE_VERSION="$OPTARG";;
    d) INSTALL_PREFIX="$OPTARG";;
    h) show_help; exit 0;;
    \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1;;
  esac
done

# Check if version is provided
if [ -z "$CMAKE_VERSION" ]; then
  echo "Error: -v option is required."
  show_help
  exit 1
fi

# Validate version format
if [[ ! "$CMAKE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format. Use X.Y.Z (e.g., 3.27.4)"
  exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"
cd "$TEMP_DIR" || { echo "Failed to change to temporary directory"; exit 1; }

# Download checksum file
echo "Downloading checksum for CMake $CMAKE_VERSION..."
CHECKSUM_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt"
if ! curl -sSL "$CHECKSUM_URL" -o "cmake-${CMAKE_VERSION}-SHA-256.txt"; then
  echo "Error: Failed to download checksum file. Verify that version ${CMAKE_VERSION} exists."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Download CMake
echo "Downloading CMake $CMAKE_VERSION..."
CMAKE_FILE="cmake-${CMAKE_VERSION}.tar.gz"
if ! curl -sSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_FILE}" -o "${CMAKE_FILE}"; then
  echo "Error: Failed to download CMake ${CMAKE_VERSION}."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Verify checksum
echo "Verifying checksum..."
EXPECTED_CHECKSUM=$(grep "${CMAKE_FILE}" "cmake-${CMAKE_VERSION}-SHA-256.txt" | awk '{print $1}')
if [ -z "$EXPECTED_CHECKSUM" ]; then
  echo "Error: Could not find checksum for ${CMAKE_FILE} in the checksum file."
  rm -rf "$TEMP_DIR"
  exit 1
fi

COMPUTED_CHECKSUM=$(sha256sum "${CMAKE_FILE}" | awk '{print $1}')
if [ "$COMPUTED_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
  echo "Error: Checksum verification failed."
  echo "Expected: $EXPECTED_CHECKSUM"
  echo "Got: $COMPUTED_CHECKSUM"
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "Checksum verification successful."

# Extract
echo "Extracting CMake..."
if ! tar -xzf "${CMAKE_FILE}"; then
  echo "Error: Failed to extract CMake archive."
  rm -rf "$TEMP_DIR"
  exit 1
fi

cd "cmake-${CMAKE_VERSION}" || { echo "Failed to change to extracted directory"; rm -rf "$TEMP_DIR"; exit 1; }

# Prepare installation directory
mkdir -p "$INSTALL_PREFIX" || { echo "Failed to create installation directory"; rm -rf "$TEMP_DIR"; exit 1; }

# Store the original installation path as provided by the user
ORIGINAL_INSTALL_PREFIX="$INSTALL_PREFIX"

# Convert to absolute path only if it's needed for the build process
if [[ "$INSTALL_PREFIX" != /* ]]; then
  # For relative paths, construct the absolute path from the current working directory
  INSTALL_PREFIX="$(pwd)/$INSTALL_PREFIX"
fi

echo "Will install to: $ORIGINAL_INSTALL_PREFIX (absolute path: $INSTALL_PREFIX)"

# Bootstrap and build
echo "Configuring CMake..."
if ! ./bootstrap \
  -- \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_PREFIX"; then
  echo "Error: Failed to configure CMake build."
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "Building CMake..."
if ! make -j$(nproc); then
  echo "Error: Failed to build CMake."
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "Installing CMake..."
if ! make install; then
  echo "Error: Failed to install CMake."
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Cleanup
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

# Verify installation
echo "Verifying installation..."
if ! "$INSTALL_PREFIX/bin/cmake" --version; then
  echo "Error: Failed to verify CMake installation."
  exit 1
fi

echo "CMake $CMAKE_VERSION has been successfully installed to $ORIGINAL_INSTALL_PREFIX"