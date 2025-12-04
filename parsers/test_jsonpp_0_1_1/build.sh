#!/bin/bash
set -e

# get the absolute path of the script
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_URL="https://github.com/mikami-w/jsonpp/archive/refs/tags/v0.1.1.tar.gz"

echo "[JSONpp] Preparing directories..."
# for storing source code
mkdir -p "$BASE_DIR/jsonpp"
# for storing binaries
mkdir -p "$BASE_DIR/bin"

echo "[JSONpp] Downloading source code..."
if command -v curl >/dev/null 2>&1; then
    curl -L "$SRC_URL" -o "$BASE_DIR/jsonpp.tar.gz"
elif command -v wget >/dev/null 2>&1; then
    wget "$SRC_URL" -O "$BASE_DIR/jsonpp.tar.gz"
else
    echo "Error: Neither curl nor wget found."
    exit 1
fi

echo "[JSONpp] Extracting..."
tar -xzf "$BASE_DIR/jsonpp.tar.gz" --strip-components=1 -C "$BASE_DIR/jsonpp"

echo "[JSONpp] Compiling..."

# input: $BASE_DIR/test_jsonpp/main.cpp
# output: $BASE_DIR/bin/test_jsonpp
# headers: $BASE_DIR/jsonpp/src
g++ "$BASE_DIR/test_jsonpp/main.cpp" \
    -o "$BASE_DIR/bin/test_jsonpp" \
    -std=c++17 \
    -I"$BASE_DIR/jsonpp/src"

rm "$BASE_DIR/jsonpp.tar.gz"

echo "[JSONpp] Build success!"
echo "Binary location: $BASE_DIR/bin/test_jsonpp"